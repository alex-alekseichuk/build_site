package GUPE::OnlinePayment;
use strict;
use base 'Exporter';
our @EXPORT_OK = qw(pay);

=head1 NAME

GUPE::OnlinePayment - wrapper object for different payment gateways

=head1 Standards

There have been several efforts at standardizing a set of names
for the attributes in online transactions. Many of these fit
into the larger project of arbitrary EDI transactions (cXML, xCBL, RossettaNet, etc.)
OASIS has started ebXML (UBL is part of this) at ebxml.org .
UBL 1.0 is an OASIS standard as of late 2004.
See http://docs.oasis-open.org/ubl/cd-UBL-1.0/ for the spec itself.
This includes and "Order to Invoice" process and associated set of XML documents.
It is broken down into packages; an image of the "Payment" package is here:

  http://docs.oasis-open.org/ubl/cd-UBL-1.0/uml/concept/comp/UBL-1.0-PaymentPackage.jpg

However, this is not designed for online payment.

Another approach would be to mimic the attributes used in some processing
network itself. An example would be Vital (formerly VisaNet) EIS 1080 and 1081.
These are the protocols used for example in VeriFone terminal "card swipers";
different terminals have slight variants of the Visa protocol (VeriFone Omni (2000s), Ruby (90s), Zon (80s)).

Or to mimic some large vendor of a payment API, such as Verisign or Authorize.net or IBM Payment Manager.

Also, there are these RFCs:

  RFC 1898 Feb 1998, CyberCash, CyberCash Credit Card Protocol Version 0.8
  RFC 2081 April 2000, Commerce One, Internet Open Trading Protocol - IOTP Version 1.0
  RFC 3538 June 2003, Hitachi, Secure Electronic Transaction (SET) Supplement for the v1.0 Internet Open Trading Protocol (IOTP)
  RFC 3867 Nov 2004, Hitachi, Payment Application Programmers Interface (API) for v1.0 Internet Open Trading Protocol (IOTP)

=head1 Software

For online payment gateways, for perl there are:

  Business::OnlinePayment::* (developed as part of Freeside) 
  Vend::Payment::* (developed as part of Interchange)

There is a glue module called Vend::Payment::BusinessOnlinePayment
allowing Interchange to use the Business::OnlinePayment::* modules

=head1 Test Cards

FYI some test cards:

  amex 371111111111111
  discover 6011-1111-1111-1111
  jcb 311111111111111
  mastercard 5111-1111-1111-1111
  mastercard  5419-8400-0000-0003
  visa 4111-1111-1111-1111

=head1 DESCRIPTION

We use Business::OnlinePayment as our gateway abstraction:

    http://420.am/business-onlinepayment/

We have our own mapping it its keys for configuration and transactions,
and it in turn maps to the particular driver.

=cut

use Business::OnlinePayment;
use GUPE::Debug::Log;

=over 4

=item gateway connection keys

   GUPE                 B::OP              Comment
   class                -                  same as B::OP module, such as "LinkPoint"
   url                  server, port, path
   account              login, storename   login, account number, config identifier, etc.
   password             password           when not authenticating by keyfile
   keyfile              keyfile            absolute path, server-local file
   testmode             test_transaction   boolean 1 or 0 

=item credit card fields

   GUPE                 B::OP              Comment
   card_type            type               visa, etc., mapped as per $CC_TYPE_MAPPING
   card_number          card_number
   expire_month         expiration         expiration is MM/YY, vs separate fields MM YYYY  
   expire_year 
   verif_number         cvv2               some gateways also want an excuse field, like LinkPoint cvmindicator
                                           CVV = Cardholder Verification Value

=item transaction fields

   GUPE                 B::OP              Comment
   txn_type             action             auth_only, etc., mapped as per $TXN_TYPE_MAPPING 
   txn_id               order_number       required for void or credit
   refnum               -                  reference number for forced ticket (post auth with auth over phone)
   amount               amount             decimal number
   ipaddr               customer_ip        client ip for this particular request

=item billing fields

These are for the person associated with the card.
This may not be the actual customer (who might be using the card of another
person, or with a different spelling of their name, etc.)

   GUPE                 B::OP              Comment
   fullname             name               name on card. B::OP sometimes splits first_name last_name
   company                                 company name
   street               address            B::OP has no support for 2nd line
   street2
   city                 city
   region               state
   postal_code          zip
   country              country            2-char country code

   street_number        addrnum            or let software figure it from street

   phone                phone
   email                email

=item customer fields

Same as billing fields. Typically not needed by gateway. Might be used for shipping.

=item tracking fields

These are fields that the gateway does nothing with, but may record
on our behalf.

   GUPE                 B::OP              Comment
   description          description
   invoice_number       invoice_number
   customer_id          customer_id 

=item result fields

   GUPE                 B::OP              Comment
   status_flag          is_success()       I/Y/N/U vs. 0 1
   txn_id               order_number()     always set with success, sometimes with failure
   refnum               authorization()    if success, auth code from processor, for later postauth
   result_code          result_code()      success or failure. on success, usually 6-digit code (distinct from authorization code).
   avs_flags            avs_code()         B::OP combines in single field for LinkPoint
   verif_flags          cvv2_code()        distinct for PayflowPro; CyberSource has cvv2_response()
   authent_sig                             for Verified by Visa, etc.
   message              error_message()    B::OP ignores except on error, for LinkPoint

The verification number is called Visa CVV2, MasterCard CVC2, American Express CID.

Visa markets the "Secure 3D" (http://partnernetwork.visa.com/pf/3dsec/main.jsp) and "Verified by Visa".
"MasterCard SecureCode" is similar.

Visa (VPAS) uses:

  ECI: transaction type
  CAVV: dig sig generated by bank. "Cardholder Authentication Verification Value"
  XID: transaction id

MasterCard uses only the AVV code (similar to CAVV):
  older marketing terms (now "SecureCode"): Universal Cardholder Authentication Field (UCAF), Secure Payment Application (SPA)
  "Accountholder Authentication Value"

=cut

our $CC_TYPE_MAPPING = {
    visa => 'Visa',
    mastercard => 'MasterCard',
    amex => 'American Express',
    discover => 'Discover',
    creditcard => 'CC',  # unspecified which one
};

our $TXN_TYPE_MAPPING = {
    auth_only => 'Authorization Only',
    auth_capture => 'Normal Authorization',
    capture_only => 'Post Authorization',
    credit => 'Credit',
    void => 'Void',
    recur_start => 'Start Recurring',
    recur_cancel => 'Stop Recurring',
    recur_modify => 'Modify Recurring',
};

=back

=cut

sub _map {
    my ($in, $h) = @_;
    return $h->{$in} || (die "no mapping for '$in' in mapping with keys: ", join(' ', keys %$h));
}

sub _new {
    my ($gw) = @_;
    my $bop_class = $gw->{class} || die "no gateway 'class'";
    my %new_params = (
		      login => $gw->{account},
		      storename => $gw->{account},
		      password => $gw->{password},
		      keyfile => $gw->{keyfile},
		      test_transaction => $gw->{testmode},
		      debug => (defined $ENV{GUPE_PAYMENTS_DEBUG}) ? $ENV{GUPE_PAYMENTS_DEBUG} : is_debug(),
		      );
    # die "not a test_transaction: ", Dumper(\%new_params) unless $new_params{test_transaction};
    if (my $u = $gw->{url}) {
	require URI;
	my $url = URI->new($u);
	$new_params{server} = $url->host();
	$new_params{port} = $url->port();
	$new_params{path} = $url->path();
    }
    my $bop = new Business::OnlinePayment($bop_class, %new_params);
    return $bop;
}

sub pay {
    my ($gw, $object_hash) = @_;

    my $bop = _new($gw);

    my ($txn, $cc, $billing, $tracking, $passthru) = @$object_hash{qw(transaction creditcard billing tracking passthru)};
    $tracking ||= {};
    $passthru ||= {};

    my %content_params =
	(
	 action => _map($txn->{txn_type}, $TXN_TYPE_MAPPING),
	 order_number => $txn->{txn_id},
	 amount => $txn->{amount},
	 # ??? => $txn->{txn_refnum}, # unsupported, reference number for forced ticket (post auth with auth over phone)
	 customer_ip => $txn->{ipaddr},

	 type => _map(($cc->{card_type}||'creditcard'), $CC_TYPE_MAPPING),
	 card_number => $cc->{card_number},
	 expiration => $cc->{expire_month} . '/' . $cc->{expire_year},
	 cvv2 => $cc->{verif_number},

	 name => $billing->{fullname},
	 address => $billing->{street},
	 city => $billing->{city},
	 state => $billing->{region},
	 zip => $billing->{postal_code},
	 country => $billing->{country},
	 email => $billing->{email},
	 phone => $billing->{phone},
	 addrnum => $billing->{street_number}, # or let driver do it from address

	 description => $tracking->{description},
	 invoice_number => $tracking->{invoice_number},
	 customer_id => $tracking->{customer_id},

	 %$passthru,
	 );
    $bop->content(%content_params);
    $bop->submit();

    my $avs = $bop->avs_code()||'';
    my ($avs_result, $codenum_result) = ($avs =~ m/^(...)(.)$/);
    my $result = {
	status_flag => ($bop->is_success() ? 'Y' : 'N'),
	txn_id => $bop->order_number(),
	refnum => $bop->authorization(), 
	result_code => $bop->result_code(),
	avs_flags => ($avs_result || $avs),
	verif_flags => $codenum_result,
	# processor_message() is currently just in my patched LinkPoint.pm
	message => ($bop->is_success() ? $bop->processor_message() : $bop->error_message()),
    };

    # maybe log it
    if (my $lf = $gw->{log_file}) {
	if (open(LF, ">>$lf")) {
	    print LF "#### " . localtime() . " = " . time() . " ####\n";
  	    print LF "  ## gateway: ", Dumper($gw);
	    # hide full credit card number, unless testmode
	    unless ($gw->{testmode} || $gw->{log_unmasked} || !$object_hash->{creditcard}->{card_number}) {
		$object_hash = {%$object_hash};
		my $cc_copy = $object_hash->{creditcard};
		$object_hash->{creditcard} = {%$cc_copy};
		$object_hash->{creditcard}->{card_number} =~ s/^\d{12}/xxxxxxxxxxxx/;
	    }
  	    print LF "  ## request: ", Dumper($object_hash);
	    my $rh = $bop->{request_hash};
	    $rh->{cardnumber} =~ s/^\d{12}/xxxxxxxxxxxx/ if $rh->{cardnumber};
  	    print LF "  ## internal request: ", Dumper($rh);
  	    print LF "  ## result: ", Dumper($result);
  	    print LF "  ## internal response: ", Dumper($bop->{response_hash});
	    close LF;
	}
    }
    return $result;
}

sub testme {
}

1;
