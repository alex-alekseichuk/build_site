package BSA::Controller::Admin::Payments;

use strict;
use warnings;
use base 'BSA::Controller';
use Data::Dumper;
use BST qw(error);
use BST::CustomerOrder;
use BST::CreditCard;
use BST::GatewayPayment;

use GUPE::OnlinePayment;
use GUPE::Crypt::Asym;

our $TEST_PASSPHRASE = 'TEST';
our $ASYM_LIVE = undef;
our $ASYM_TEST = undef;

=head1 NAME

BSA::Controller::Admin::Payments - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index : Path('/admin/payments/') {
    my ( $self, $c ) = @_;
    return $c->deny() unless $c->user->is_bs_admin();
    return $c->response->redirect('/admin/payments/recurring');
}


sub recurring : Path('/admin/payments/recurring') {
    my ( $self, $c ) = @_;
    return $c->deny() unless $c->user->is_bs_admin();
    $c->stash->{orders} = $self->find_recurring($c->request->param('testaccounts') ? 0 : 1, ($c->request->param('all') eq "0") ? 0 : 1);
    $c->stash->{template} = 'payments/recurring.tt';
}


sub sweep : Path('/admin/payments/sweep') Form {
    my ( $self, $c ) = @_;
    return $c->deny() unless $c->user->is_bs_admin();
    return $c->response->redirect('/admin/payments/recurring') if $c->request->{method} ne "POST";

    $c->stash->{debug} = [];
    local( *debug ) = sub { shift; push @{ $c->stash->{debug} },  join( '', @_ ); };

    my $results = $self->sweep_recurring($c->request->param('passphrase'), $c->request->param('testaccounts') ? 0 : 1, $c->request->param('pretend') ? 1 : 0, $c->request->param('stoponerror') ? 1 : 0);
    $c->stash->{orders} = $results;
    $c->stash->{template} = 'payments/sweep.tt';
}


sub find_recurring {
    my $self = shift;
    my $islive = shift;
    my $all = shift;

    my ($query, $columns, @orders);

    $columns = [map { "me.$_" } BST::CustomerOrder->columns ];
    push @$columns, "gw_testmode";
    #push @$columns, "IF(me.order_expires < NOW() or me.order_expires IS NULL, '0', '1') as expired";

    $query->{'me.order_expires'} = { 'or' => [{'is' => undef}, {'>' => 'NOW()'}] } unless $all;
    $query->{'me.order_status'} = {'in' => ['valid', 'expired']};
    $query->{gw_testmode} = $islive ? 'false' : 'true';

    @orders = BST::CustomerOrder->search($query, {
        alias       => 'me',
        select      => $columns,
        group_by    => $columns,
        from        => [
            { me => 'customer_order' },
            [
                { gp => 'gateway_payment' },
                { 'me.customer_order_id' => 'gp.customer_order_id' }
            ],
        ],
	order_by => 'me.customer_order_id'
	});

    return \@orders;
}


sub sweep_recurring () {
    my ($self, $passphrase, $islive, $pretend, $stoponerror) = @_;

    my $customer_orders = $self->find_recurring($islive, 1);

    my $asym = $self->get_asym($passphrase, $islive);
    my $results = [];

    for my $co (@$customer_orders) {
        my $r = $self->charge_recurring($co, $asym, $pretend, $islive);
        push @$results, $r;

        my $err = $r->{err};
        if ( $err and scalar @$err and $stoponerror ) {
            $self->debug("stopping because of errors");
            last;
        }
    }
    return $results;
}


# password is required if going to decrypt or generate
sub get_asym () {
    my ($self, $passphrase, $islive) = @_;
    if ($islive     and $ASYM_LIVE) { return $ASYM_LIVE; }
    if (not $islive and $ASYM_TEST) { return $ASYM_TEST; }

    my $crypter = new GUPE::Crypt::Asym(
        private_file => BST::config('payments')->{keyfileprivate}->{$islive ? "live" : "test"},
        public_file  => BST::config('payments')->{keyfilepublic}->{$islive ? "live" : "test"},
        password => $passphrase,
        armour => 1
    );

    return ($ASYM_LIVE = $crypter) if $islive;
    return ($ASYM_TEST = $crypter);
}


sub charge_recurring {
    my ($self, $co, $asym, $pretend, $islive) = @_;

    # load the card's details
    my $cc = BST::CreditCard->load($co->credit_card_id) || die "can't find the credit card record ($co->credit_card_id)\n";

    my @err = ();
    my $h;
    my $result = { order => $co, err => \@err, success => undef, charge => $h };

    # decrypt card number
    my $cc_number;
    eval { $cc_number = $asym->decrypt($cc->cc_number_encrypted) };

    if ($@) {
        push @err, "decrypt failed";
	$self->debug($@);
        # $cc_number = "4111111111111111";
	return $result;
    }

    # load customer info
    my $cu = BST::CustomerUser->load($co->customer_user_id) || die "can't find the customer_user record ($co->customer_user_id)\n";

    # load account info
    my $ca = BST::Account->load({ customer_order_id => $co->customer_order_id }) || die "can't find the customer_account record ($cu->customer_account_id)\n";

    my $tracking = {
        description    => 'BuildSite Individual',
        invoice_number => $co->customer_order_id,
        customer_id    => $co->get_column('customer_user_id'),
    };

    my $is_success;

    my $gp = BST::GatewayPayment->search({customer_order_id => $co->customer_order_id, txn_status_flag => 'Y'}, {select => "recur_index", order_by => "recur_index DESC"});
    my $recur_index = $gp->first->recur_index || 0;
    $recur_index++;

    my $request = {
            customer_order_id => $co->customer_order_id,
            credit_card_id    => $co->get_column('credit_card_id'),
            recur_index       => $recur_index,
            txn_amount        => $co->amount,
            txn_status_flag   => 'I', # incomplete
            txn_start_epoch   => time,
            txn_type          => 'auth_capture',
            gw_system         => BST::config('payments')->{gateway}->{class},
            gw_account        => BST::config('payments')->{gateway}->{account},
            gw_testmode       => ($islive ? 'false' : 'true'),
    };

    my $obj = BST::GatewayPayment->create($request);

    eval { $obj->save() };
    if ($@) {
        push(@err, "pre_insert_gateway_payment: $@");
    }

    eval {
      $h = $self->attempt_charge($cc, $cu->fullname, $ca, $cc_number, $co->amount, $tracking, $islive);
    };


    push(@err, "attempt_charge: $@") if $@;

    $request = {
            txn_status_flag  => $h->{status_flag},
            txn_id           => $h->{txn_id},
            txn_finish_epoch => time,
            txn_refnum       => $h->{refnum},
            txn_result_code  => $h->{result_code},
            txn_avs_flags    => $h->{avs_flags},
            txn_verif_flags  => $h->{verif_flags},
            txn_message      => $h->{message},
    };

    eval {$obj->update($request)};
    if ($@) {
        push(@err, "post_update_gateway_payment: $@");
    }

    $result->{success} = $is_success = $h->{status_flag} ? 1 : 0;

    my ($d, $m, $y) = (localtime)[3..5];
    $y += 1900; $m++;

    my $today = sprintf "%d-%02d-%02d", $y, $m, $d;
    my $email_template;


    # act, based on result
    if ($is_success) {
        # find new order_expires

        $gp = BST::GatewayPayment->search({customer_order_id => $co->customer_order_id, txn_status_flag => 'Y'}, {select => "recur_index", order_by => "recur_index DESC"});
        $recur_index = $gp->first->recur_index || 0;

        if ($co->recur_interval =~ /^(1M|1 month)$/) {
            $request = {order_expires => \ "order_start + INTERVAL '$recur_index month'"};
            $co->update($request);
            $co = BST::CustomerOrder->load($co->customer_order_id);

            if ($today lt $co->order_expires) {
                if ( $co->order_status ne 'valid' ) {
                    $request = { order_status => 'valid' };
                    $result->{new_status}   = 'valid';
                    $co->update($request);
                }
            } else {
                $result->{repeat} = 1;
            }

            # find if the previous attempt was a failure
            my $lastattempt = BST::GatewayPayment->search({customer_order_id => $co->customer_order_id, recur_index => $recur_index - 1 }, {select => "txn_status_flag"})->first;
            if ($lastattempt and $lastattempt->txn_status_flag ne 'Y') {
                # previous payment attempt was a failure
                $email_template = 'recurring_success';
            }
        } else {
            die "unknown recur_interval";
        }
    } else {
        # if order_expires is in the past (generally so), set order_status = 'expired'
        my $order_expires = $co->order_expires;
        my $new_status;

        if ($today gt $order_expires ) {
            if ( $co->order_status eq 'valid' ) {
                $new_status = 'expired';
                $email_template = 'recurring_failure';
            }

=pod
            # if have made at least X attempts in past Y days, all failed, set order_status = 'cancelled'
            if ( too_many_failed_attempts( $dbh, $co ) ) {
                $new_status = 'cancelled';
                $email_template = 'cancellation';
                # XXX set customer_account.block_reason to 'expired'?
            }
=cut

            if ( $new_status ) {
                $co->update({order_status => $new_status});
                $result->{new_status} = $new_status;
            }
        }

    }

    if ( $email_template ) {
        if ( not $pretend ) {
            # "sending notification email to the user: $email_template";
            my $email_params = { user => $cu, customer_order => $co };
            $self->send_user_message( $email_template, $email_params ) or push @err, "send_user_message: " . BST::Email->error();
        } else {
            if ($email_template) {
                push @err, "should be sending email notification ($email_template) to the user, but we are in pretend mode";
            }
        }
    }

=pod
    # log it, and send email.
    if (@err) {
      my $err = join("\n", @err);
      warning("got errors after the card charge: $err");
      debug "Errors: $err";
      eval {
        send_sysadmin($err);
        if (open(EF, ">>" . $context->{post_error_log_file})) {
          print EF "#### " . localtime() . "####\n" . $err, "\n";
          close EF;
        }
      };
    }

    $dbh->commit() if not $pretend;
    $dbh->rollback()   if $pretend;
=cut

    # Replace order data (it might be updated)
    $result->{order} = $co;
    return $result;
}


sub attempt_charge {
    my ($self, $cc, $user_fullname, $account, $cc_number, $amount, $tracking, $islive) = @_;

    my $billing = $cc->billing_from_account ?
    {
        fullname    => $user_fullname,
        street      => $account->company_id->addr_street,
        city        => $account->company_id->addr_city,
        region      => $account->company_id->addr_region,
        postal_code => $account->company_id->addr_postal_code,
        country     => ($account->company_id->addr_country || 'US'),
    } :
    {
        fullname    => $cc->billing_name,
        street      => $cc->billing_street,
        city        => $cc->billing_city,
        region      => $cc->billing_region,
        postal_code => $cc->billing_postal_code,
        country     => ($cc->billing_country || 'US'),
    };
    $cc_number =~ s/[^\d]//g;
    my $object_hash = {
            transaction => {
                txn_type => 'auth_capture',
                amount   => $amount,
                ipaddr   => $ENV{REMOTE_ADDR},
            },
            creditcard => {
                card_type    => $cc->cc_type,
                # $cc_number has non-digits removed
                card_number  => $cc_number,
                expire_month => $cc->cc_expire_month,
                expire_year  => $cc->cc_expire_year,
                verif_number => $cc->cc_verif_number,
            },
            billing    => $billing,
            tracking   => $tracking,
        };

    return $self->gw_txn($object_hash, $islive);
}


sub gw_txn {
    my ($self, $object_hash, $islive) = @_;
    my $gw = {
        %{BST::config('payments')->{gateway}},
        testmode => !$islive,
        log_file => BST::config('payments')->{payment_log_file},
    };

    my $response = GUPE::OnlinePayment::pay($gw, $object_hash);
    return $response;
}

sub debug {
}

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
