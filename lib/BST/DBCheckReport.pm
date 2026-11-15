package BST::DBCheckReport;

use strict;
use warnings;

use Data::Dumper;

use base qw/BST::Schema::DBCheckReport/;
__PACKAGE__->table('dbcheck_reports');


sub _fields_inflate {
    my $string = shift;
    return undef unless $string;

    $string =~ s/''/'/g;
    my $VAR1;
    eval($string);
    if ($@) { 
        warn sprintf("Cannot deserialize \n%s\n\n", $string);
        return undef; 
    }
    return $VAR1;
}

sub _fields_deflate {
    my $object = shift;
    my $result = Dumper($object);
    $result =~ s/'/''/g;
    $result =~ s/\\/\\\\/g;
    $result =~ s/\s+/ /g;
    return $result;
}

__PACKAGE__->inflate_column(
    info_fields  => {
        inflate => \&BST::DBCheckReport::_fields_inflate,
        deflate => \&BST::DBCheckReport::_fields_deflate,
    }
);
__PACKAGE__->inflate_column(
    bad_fields  => {
        inflate => \&BST::DBCheckReport::_fields_inflate,
        deflate => \&BST::DBCheckReport::_fields_deflate,
    }
);

=head1 DESCRIPTION
    DBCheckReport record class
=cut

1;
