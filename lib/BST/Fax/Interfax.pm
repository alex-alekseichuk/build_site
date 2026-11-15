package BST::Fax::Interfax;

use strict;

use BST;
use Params::Validate qw/validate_pos/;

sub allowed_ext { qw/DOC DOT DOCX XML PDF TIF TXT XLS XLSX HTM HTML MHT URL PPT PPTX GIF JPG JPEG PS EPS RTF BMP PCX SNP ZIP/ }
sub allowed_format { qw/ bmp eps excel  jpeg html pdf powerpoint rtf tiff text word / }
sub domain { '@fax.tc' }


sub is_format_accepted {
    my $s = shift;
    my $e = lc shift;

    # my $accepted = grep /^$e$/, $s->allowed_ext(); 
    my $accepted = grep /^$e$/, $s->allowed_format();
    return $accepted;
}

sub headers {
    my $s = shift;
    my $r = shift;

    # remove unuseful stuff from address
    my $addr = $r->address;
    $addr =~ s/[+()\-\s]//g;                        # remove all spec. chars
    $addr = '+' . $addr if $r->address =~ /^\+/;    # leave only one + if it's first

    return {
        'From'     => BST::config('interfax_account'),
        'To'       => $addr . $s->domain,
        'Reply-To' => BST::config('interfax_reply_to'),
        'Subject'  => 'rid::' . $r->id . (BST::config('system_id') ? ';system_id::' . BST::config('system_id') : ''),
        'Type'     => 'multipart/mixed',
    };
}

sub get_status {
    my $self = shift;
    my $errorcode = shift;

    my %statuses = (
                        "failed-telephony" => [qw(3072 3080 3211 3220 3223 3224 3225 3231 3264 3267 3268 3269 3300 3510 3830 8010 8021)],
                        "failed-line-busy" => [qw(3931 3933 3937 6017 8025)],
                        "failed-disconnected" => [qw(3223 3230)],
                        "failed-number" => [qw(3912 3932 3936 3938 6001 6018 6022 6027 6028)],
                        "failed-rendering" => [qw(204000 204001)],
                    );

    for my $status (keys %statuses) {
         if (grep {$_ == $errorcode} @{$statuses{$status}}) {
             return $status;
         }
    }
    
	return "failed-telephony" if ($errorcode >= 6000 && $errorcode < 8000);
    return "failed-unknown";
}


1;
