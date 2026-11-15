package BSA::Controller::Admin;

use strict;
use warnings;
use base 'BSA::Controller';
use Data::Dumper;
use BST::User;
use BST::Location;
use BST::Company;
use BST qw(error);
use POSIX qw(ceil);

=head1 NAME

BSA::Controller::Admin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut


sub _fill_crumbs { 
    my $c = shift; 
    my %params = @_; 
     
    my $path = {}; 
    $path->{account_id} = $params{account}; 
     
    if ($params{user}) { 
        my $oUser = BST::User->load( { user_id => $params{user} } );
        if ($oUser) {
            $path->{user_id} = $params{user}->user_id; 
            $path->{user_name} = $oUser->given_name . ' ' . $oUser->family_name;
            $path->{account_id} = $params{user}->primary_location->account->account_id unless $path->{account_id};
        }
    } 
 
    if ($params{location}) { 
        my $oLocation = BST::Location->load( { account_location_id => $params{location} } ); 
        $path->{location_id} = $params{location}->account_location_id; 
        $path->{location_name} = $oLocation->location_fullname || $oLocation->location_nickname; 
        $path->{account_id} = $params{location}->account->account_id unless $path->{account_id}; 
    }
    
    if ($path->{account_id}) {
        my $oAcc = BST::Account->load( { account_id => $path->{account_id} } );
        $path->{account_name} = $oAcc->company_id ? $oAcc->company->legal_name : "";
    }

    $c->stash->{path} = $path; 
} 

sub auto : Private {
    my ($self, $c) = @_;
    $c->stash->{user} = $c->user;
}


sub index :Path Args(0) {
    my ( $self, $c ) = @_;

    return $c->response->redirect( '/admin/edit/user' ) if ($c->user->is_single_user());
    return $c->response->redirect('/admin/account') if ($c->user->is_account_admin());
    $c->stash->{user} = $c->user;
}


sub account : Path('/admin/account') Form {
    my ($self, $c) = @_;
    my $account;

    if ($c->req->param('account_id')) {
        $account = BST::Account->load({ account_id => $c->req->param("account_id") });
        return $c->deny() unless ($c->user->is_bs_admin || ($account->account_id eq $c->user->primary_location->account->account_id && $c->user->is_account_admin()));
    } elsif ($c->user->is_account_admin()) {
        $account = BST::Account->load({ account_id => $c->user->primary_location->account->account_id });
    } else {
        $c->deny() unless $c->user->is_bs_admin();
    } 

    if ($c->req->param('new') && $c->req->param('account_id') && BST::Account->load({account_id => $c->req->param('account_id')})) {
        &error->account_exists;
        $c->stash->{account_id} = $c->req->param('account_id');
        $account = undef;
    }

    my $form = $self->formbuilder;
    my @fields = qw[account_id account_type allow_self_registration access_constraints signed_final_date signed_trial_date expiration_date mail_opt_out email_opt_out email_opt_out_date mail_opt_out_date sponsor_id];
    unless ($account && $account->get_column('company_id')) {
        #--- New Company ----
        $form->field( name => 'company_id', type => 'select', label => 'Existing Company', required => 0);
        $form->field( name => 'new_customer_id', type => 'text', label => 'New Company', style => 'display:none');
    } else {
        $form->field( name => 'company_id', type => 'hidden', required => 1, value => $account->get_column('company_id'));
        $form->field( name => 'new_customer_id', type => 'text', label => 'Company', style => 'display:none');
    }

    $form->field(
               name => 'legal_name',
               label => '<span style="margin-left:20px;">Name</span>',
               value => $account && $account->company ? $account->company->legal_name : '',
               required => 0,
        );
    $form->field(
               name => 'company_type',
               label => '<span style="margin-left:20px;">Type</span>',
               options => ['library_publisher', 'contractor', 'manufacturer', 'dealer', 'other_company', 'other_type'],
               value => $account && $account->company ? $account->company->company_type : '',
               required => 0,
        );
    $form->field(
               name => 'public_visible',
               label => '<span style="margin-left:20px;">Public Visible</span>',
               options => [['0' => 'false'], ['1' => 'true']],
               type => 'select',
               selectname => 0,
               value => $account && $account->company ? $account->company->public_visible : '',
               required => 0,
        );
    $form->field(
               name => 'company_nickname',
               label => '<span style="margin-left:20px;">Nickname</span>',
               value => $account && $account->company ? $account->company->company_nickname : '',
               required => 0,
        );
    $form->field(
               name => 'company_url',
               label => '<span style="margin-left:20px;">Company URL</span>',
               value => $account && $account->company ? $account->company->company_url : '',
        );

    if ($account && $account->company) {
        $form->field( name => 'link', type => 'text', label => '', style => 'display:none', comment => '<a href="/dbedit/company/' . $account->get_column('company_id') .'">full company details</a>');
    }

    $form->field( name => 'account_type', label => 'Account Type', type => 'select', required => 1);
    $form->field( name => $_, label => $_, type => 'text', required => 0 ) for qw (allow_self_registration access_constraints signed_final_date signed_trial_date expiration_date mail_opt_out email_opt_out email_opt_out_date mail_opt_out_date);
    $form->field( name => 'sponsor_id', label => 'Sponsor', type => 'select', required => 0);
    $form->field( name => 'block_access', label => 'Account Status', type => 'select', options => ['Active', 'Blocked'], required => 1);
    $form->field( name => 'new', type => 'hidden', required => 0);

    &error->bad_account_id if ($form->submitted && $form->validate && $form->field("account_id") !~ /^[a-z0-9_]+$/);
    my $valid = ($form->field("company_id") || ($form->field("company_nickname") && $form->field("company_type") && $form->field("legal_name")));
    &error->customer_id_is_required if ($form->submitted && $form->validate && !$valid );

    my $company_id;
    if (!&error->status && $form->submitted && $form->validate) {
        if ($form->field("account_id") =~ /^[a-z0-9_]+$/ && $valid) {
            # create company if not exists
            $company_id = $form->field("account_id");

            my $request = {
                            company_nickname => $form->field('company_nickname'),
                            legal_name => $form->field('legal_name'),
                            company_type => $form->field('company_type'),
                            public_visible => $form->field("public_visible"),
                            company_url => $form->field("company_url")
                        };

            unless ($form->field("company_id")) {

                my $company = BST::Company->load({company_id => $company_id});
                unless ($company) {
                    $request->{company_id} = $company_id;
                    $request->{suppress_reason_code} = '';
                    $request->{permission_granted} = 'false';
                    $company = BST::Company->create($request);
                    eval {$company->save()};
                    &error->save_failed if $@;
                } else {
                    &error->company_exists;
                }
            } else {
                if ($form->field("company_nickname")) {
                    # update Company
                    my $company = BST::Company->load({company_id => $form->field("company_id")});
                    if ($company) {
                        eval {$company->update($request)};
                        &error->save_failed if $@;
                    } else {
                        &error->save_failed;
                    }
                }
                $company_id = $form->field("company_id");
            }

            $request = {
                block_access => $form->field("block_access") eq 'true' ? 1 : 0,
                company_id => $company_id,
                map {;
                    $_ => $form->field($_)
                } @fields
            };

            if ($account) {
                eval {$account->update($request);};
                &error->save_failed if $@;
            }
            else {
                if (BST::Account->load({ account_id => $form->field("account_id") })) {
                    &error->account_exists;
                    $c->stash->{account_id} = $form->field("account_id");
                    $account = undef;
                } else {
                    $account = BST::Account->create($request);
                    eval {$account->save();};
                    if ($@) {
                        $account = undef;
                        &error->save_failed;
                    } else {
                        return $c->response->redirect( $c->uri_for('/admin/account/', {account_id => $account->account_id }) );
                    }
                }
            }
            #$c->response->redirect('/admin/list/accounts');
        }
    }

    $form->field(name => 'account_id', value => $account ? $account->account_id : "");
    my (@company_list, @sponsors_list);
    push @company_list, [ $_->get_column('company_id') => $_->legal_name . " (". $_->get_column('company_id') . ")" ] for BST::Company->search({'account_id' => undef, branch_of_id => undef, 'me.company_id' => {'not like' => 'individual_%'}}, { from => [ {me => 'company'}, [{acc => 'account', -join_type => 'LEFT'}, {'me.company_id' => 'acc.account_id'}] ], order_by => 'me.legal_name'})->all;
    push @sponsors_list, [ $_->get_column('company_id') => $_->legal_name . " (". $_->get_column('company_id') . ")" ] for BST::Company->search({branch_of_id => undef, 'me.company_id' => {'not like' => 'individual_%'}}, {order_by => 'me.legal_name'})->all;
    $form->field(
               name => 'company_id',
               value => $account ? $account->get_column('company_id') : "",
               options => \@company_list,
        );

    $form->field(
               name => 'sponsor_id',
               value => $account ? $account->get_column('sponsor_id') : "",
               options => \@sponsors_list
        );
    $form->field(
               name => 'account_type',
               options => [ ['normal' => 'Normal'], ['guest' => 'Guest'], ['dealer' => 'Dealer'], ['admin' => 'Admin'], ['individual' => 'Individual'] ],
               value => $account ? $account->account_type : "normal",
        );
    $form->field(
               name => 'block_access',
               options => [ ['true' => 'Blocked'], ['false' => 'Active'] ],
               value => $account && $account->block_access ? 'true' : 'false',
        );
    $form->field(name => 'allow_self_registration', value => $account ? $account->allow_self_registration : "");
    $form->field(name => 'access_constraints', value => $account ? $account->access_constraints : "");
    $form->field(name => 'signed_final_date', value => $account ? $account->signed_final_date : "");
    $form->field(name => 'signed_trial_date', value => $account ? $account->signed_trial_date : "");
    $form->field(name => 'expiration_date', value => $account ? $account->expiration_date : "");
    $form->field(name => 'mail_opt_out', value => $account ? $account->mail_opt_out : "");
    $form->field(name => 'email_opt_out', value => $account ? $account->email_opt_out : "");
    $form->field(name => 'email_opt_out_date', value => $account ? $account->email_opt_out_date : "");
    $form->field(name => 'mail_opt_out_date', value => $account ? $account->mail_opt_out_date : "");
    $form->field(name => 'new', value => $account ? "" : "1");
    $c->stash->{obj} = $account;

    _fill_crumbs($c, account => $account ? $account->account_id : undef);
}


sub users : Path('/admin/list/users') Args {
    my ($self, $c) = @_;

    return $c->deny() unless $c->user->is_bs_admin() || $c->user->is_account_admin();
    my $order_by = $c->req->param('order') || 'login_id asc';

    my $account_id = $c->user->is_bs_admin() ?
        $c->req->param('account_id') : 
        $c->user->primary_location->account->account_id;

    my @locations = BST::Location->search({ account_id => $account_id });

    $c->stash->{items} = @locations ? BST::User->search( { primary_location => [ map { $_->account_location_id } @locations ] }, {order_by => $order_by}) : undef;
    _fill_crumbs($c, account => $account_id);
    $c->stash->{order}  = $order_by;
}


sub accounts : Path('/admin/list/accounts') Args {
    my ($self, $c) = @_;

    return $c->deny() unless $c->user->is_bs_admin();
    my $order_by = $c->req->param('order') || 'account asc';

    my @items = BST::Account->search({});
    BST::Account->get_companies_for_items(\@items);

    @items = sort {
        return 1 unless $a->get_column('company_id');
        return -1 unless $b->get_column('company_id');
        return uc $a->company->name cmp uc $b->company->name
    } @items;
    @items = reverse @items if $order_by eq 'account desc';

    $c->stash->{items} = \@items;
    $c->stash->{order} = $order_by;
}


sub locations : Path('/admin/list/locations') Args {
    my ($self, $c) = @_;

    return $c->deny() unless $c->user->is_bs_admin() || $c->user->is_account_admin();

    my $account_id = $c->user->is_bs_admin() ?
        $c->req->param('account_id') :
        $c->user->primary_location->account->account_id;

    $c->stash->{items} = BST::Location->search({ account_id => $account_id });
    $c->stash->{obj} = {account_id => $account_id};
    _fill_crumbs($c, account => $account_id);
}


sub edit_location : Path('/admin/edit/location') Form {
    my ($self, $c) = @_;

    my $location;
    if ($c->req->param("location_id")) {
        $location = BST::Location->load({ account_location_id => $c->req->param("location_id") });
        return unless $c->must_write($location);
    } else {
        $c->deny() unless $c->user->is_bs_admin() || $c->user->is_account_admin();
    }

    my @fields = qw[location_nickname location_fullname location_url location_phone location_fax addr_street addr_city addr_region addr_postal_code];
    my $account_id = $c->user->is_bs_admin() ?
        ( $location ? $location->account->account_id : $c->req->param('account_id') ):
        $c->user->primary_location->account->account_id;

    my $form = $self->formbuilder;
    &error->bad_location_nickname if ($form->submitted && $form->validate && $form->field("location_nickname") !~ /^[a-z0-9_]+$/);
    if ($form->submitted && $form->validate && $form->field("location_nickname") =~ /^[a-z0-9_]+$/) {
        my $request = {
            block_access => $form->field("block_access") eq 'true' ? 1 : 0,
            map {;
                $_ => $form->field($_)
            } @fields
        };

        if ($location) {
            $location->update($request);
        }
        else {
            $request->{account_id} = $account_id;
            $request->{account_location_id} = $request->{account_id} . "_" . $request->{location_nickname};
            if (BST::Location->load({account_location_id => $request->{account_location_id}})) {
                &error->location_exists;
                $c->stash->{location_id} = $request->{account_location_id};
            } else {
                $location = BST::Location->create($request);
                eval {$location->save();};
                if ($@) {
                    &error->save_failed;
                } else {
                    my $dir = BST::config("account_locations_path") . "/" . $request->{account_location_id};
                    mkdir $dir unless -e $dir;
                    $dir .= "/account_private_files";
                    mkdir $dir unless -e $dir;
                }
            }
        }
    }


    $form->field(name => 'account_id', value => $account_id);
    $form->field(name => 'location_id', value => $location ? $location->account_location_id : '');
    $form->field(
        name => $_,
        value => $location ? $location->$_ : ''
    ) foreach (@fields);

    $form->field(
        name => 'block_access',
        options => [ 
            ['true' => 'Blocked'], ['false' => 'Active'] 
        ],
        value => $location && $location->block_access ? 'true': 'false',
    );

    $c->stash->{obj} = $location;
    _fill_crumbs($c, account => $account_id, location => $location);
}


sub edit_user : Path('edit/user') Form {
    my ($self, $c) = @_;
    my $user;


    if ($c->user->is_single_user) {
        $user = BST::User->load({ user_id => $c->session->{user_id} });
    }
    elsif ($c->req->param("user_id")) {
        $user = BST::User->load({ user_id => $c->req->param("user_id") });
        return unless $c->must_write($user);
    }
    else {
        return $c->deny() unless ($c->user->is_bs_admin() || $c->user->is_account_admin());
    }


    my $form = $self->formbuilder;
    &error->bad_login_id if ($form->submitted && $form->validate && $form->field("login_id") !~ /^[a-z0-9_]+$/);
    my @fields = qw[given_name family_name email_address];
    if ($form->submitted && $form->validate && $form->field("login_id") =~ /^[a-z0-9_]+$/) {
        my $request = {
            login_id => $form->field('login_id'),
            map {;
                $_ => $form->field($_)
            } @fields
        };

        unless ($c->user->is_single_user()) {
            $request->{primary_location} = $form->field("primary_location");

            # Account admin can create users in owned locations only
            unless ($c->user->is_bs_admin()) {
                my $oLoc = BST::Location->load( { account_location_id => $request->{primary_location} } );
                return unless $c->must_write($oLoc);
            }
            $request->{user_role} = $form->field("user_role");
            $request->{block_access} = $form->field("block_access") eq 'true' ? 1 : 0;
        }

        if ($form->field("confirm_password")) {
            $request->{user_password} = $form->field("confirm_password") if ($form->field("confirm_password") && $form->field("password") &&  $form->field("confirm_password") eq $form->field("password"));
        } else {
            $request->{user_password} = $form->field("password") if $form->field("password") && $c->user->is_bs_admin();
        }

        if ($user) {
            eval {$user->update($request);};
            &error->save_failed if $@;
        } else {
            if (my $u = BST::User->load({login_id => $request->{login_id}})) {
                if ($c->user->is_bs_admin() || $u->primary_location->account->account_id eq $c->user->primary_location->account->account_id) {
                    &error->user_exists;
                } else {
                    &error->user_exists_simple;
                }
                $c->stash->{user_id} = $u->user_id;
            } else {
                $user = BST::User->create($request);
                eval {$user->save();};
                &error->save_failed if $@;
            }
        }
    }

    $form->field(
        name => 'user_id', 
        type => 'hidden', 
        value => $user ? $user->user_id : "", 
        required => 0
    );

    $form->field(
        name => 'login_id', 
        value => $user ? $user->login_id : "", 
        type => $c->user->is_single_user() ? 'static' : 'text', 
        required => $c->user->is_single_user() ? 0 : 1
    );
    
    $form->field(
        name => $_,
        value => $user ? $user->$_ : ''
    ) foreach @fields;

    my $account_id = $c->user->is_bs_admin() ? 
        ( $user ? $user->primary_location->account->account_id : $c->req->param('account_id') ) : 
        $c->user->primary_location->account->account_id;
    
    unless ($c->user->is_single_user()) {
        my @locations = BST::Location->search({ account_id => $account_id }, { order_by => 'account_location_id' });
        my $locations = [
            map {
                [$_->account_location_id => $_->location_fullname]
            } @locations
        ];

        unless ($user) {
            $form->field(name => 'password', value => "", required => 1, type => "password");
            $form->field(name => 'confirm_password', value => "", required => 1, type => "password");
        } elsif($c->user->is_bs_admin()) {
            $form->field(name => 'password', value => $user->user_password, required => 1, type => "text");
            $form->field(name => 'confirm_password', value => "", required => 1, type => "hidden");
        }

        $form->field(
               name => 'primary_location',
               options => $locations,
               value => $user ? $user->primary_location->account_location_id : "",
        );
        $form->field(
               name => 'user_role',
               options => [ ['admin' => 'Admin'], ['enduser' => 'Normal'] ],
               value => $user ? $user->user_role : "enduser",
        );
        $form->field(
               name => 'block_access',
               options => [ ['true' => 'Blocked'], ['false' => 'Active'] ],
               value => $user && $user->block_access ? 'true' : 'false',
        );

    } else {
        $form->field(name => 'password', required => 0, type => "password", value => "", size => 40);
        $form->field(name => 'confirm_password', value => "", required => 0, type => "password", size => 40);
        $form->field(
            name => 'primary_location',
            value => $user->primary_location->location_fullname,
            type => 'static', 
            required => 0
        );
        $form->field(
            name => 'user_role', 
            value => 'Normal', 
            type => 'static', 
            required => 0
        );
        $form->field(
            name => 'block_access', 
            value => $user->block_access ? 'Blocked': 'Active',
            type => 'static', 
            required => 0
        );
    }

    $c->stash->{obj} = $user;
    _fill_crumbs($c, user => $user, account => $account_id); 
}



sub delete_user : Path('delete/user') Args{
    my ($self, $c) = @_;
    my $user = BST::User->load( { user_id => $c->req->param("user_id") } );

    return unless $c->must_write($user);
    return $c->deny() if $c->user->user_id eq $user->user_id;

#    BST::User->delete({ user_id => $c->req->param("user_id") });

    $user->block_access(1);
    $user->block_date(time);
    $user->block_reason(sprintf('Deleted by %s (%s)', $c->user->login_id, $c->user->user_id));
    $user->save();

    $c->response->redirect( $c->uri_for('/admin/edit/user', {user_id => $user->user_id}) );
}

sub delete_location : Path('/admin/delete/location') Args{
    my ($self, $c) = @_;
    my $location = BST::Location->load( { account_location_id => $c->req->param("account_location_id") } );

    return unless $c->must_write($location);
    return $c->deny() if $c->user->primary_location->account_location_id eq $location->account_location_id;

    $location->block_access(1);
    $location->block_date(time);
    $location->block_reason(sprintf('Deleted by %s (%s)', $c->user->login_id, $c->user->user_id));
    $location->save();

    $c->response->redirect( $c->uri_for('/admin/edit/location', {location_id => $location->account_location_id}) );
}

sub delete_account : Path('/admin/delete/account') Args{
    my ($self, $c) = @_;
    my $account = BST::Account->load( { account_id => $c->req->param("account_id") } );

    return unless $c->must_write($account);
    return $c->deny() unless $c->user->is_bs_admin();

    $account->block_access(1);
    $account->block_reason(sprintf('Deleted by %s (%s)', $c->user->login_id, $c->user->user_id));
    $account->save();

    $c->response->redirect( $c->uri_for('/admin/account', {account_id => $account->account_id}) );
}


sub dbsyncreports_list : Path('/admin/dbsyncreports') Args {
    my ($self, $c) = @_;
    $c->deny() unless $c->user->is_bs_admin();
    my $dir = BST::config('dbsync_reports_dir') || '/home/pgonchar/bs-app/';

    opendir(my $dh, $dir) || die "can't opendir $dir: $!";
    my @files = grep { -f "$dir/$_" } readdir($dh);
    closedir $dh;

    @files = reverse sort {(stat($a))[9] <=> (stat($b))[9]} @files;
    @files = map { {name => $_, mtime => (stat("$dir/$_"))[9], size => ceil((stat("$dir/$_"))[7] / 1024) } } @files;

    $c->stash->{list} = \@files;
    $c->stash->{template} = 'admin/dbsyncreportslist.tt';
}

sub dbsyncreports_view : Path('/admin/dbsyncreports/view') Args {
    my ($self, $c) = @_;
    $c->deny() unless $c->user->is_bs_admin();

    my $dir = BST::config('dbsync_reports_dir') || '/home/pgonchar/bs-app/';
    my $file = $c->request->param('file');

    open FILE, "$dir/$file" or die "can't open file: $!";
    my $content = join "", <FILE>;
    close FILE;

    $c->stash->{item} = { name => $c->request->param('file'), mtime => (stat("$dir/$file"))[9], size => ceil((stat("$dir/$file"))[7] / 1024), content => $content };
    $c->stash->{template} = 'admin/dbsyncreportsview.tt';
}

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
