package BST::ZIP;

use strict;

use Carp qw/croak/;
use base qw/Class::Singleton/;
use Text::CSV_XS;
use Math::Trig;

use Data::Dumper;

our $zipdb_obj;

sub _zcw_init {
    my $reader = Text::CSV_XS -> new();
    $zipdb_obj = {};
    my ($data,$zip,$lat,$lon);
    my $ZCW_PATH = BST::config('zip_codes_file');
    open(ZCW, "<" . $ZCW_PATH) || croak "can't open $ZCW_PATH: $!";
    $data = $reader->getline( *ZCW ); # first line is the header line
    while ( $data = $reader->getline( *ZCW ) ) {
        $zip = $data->[0];
        $lat = $data->[12];
        $lon = $data->[13];
        last if not $zip;
        $lat =~ s/^[ \-]+//;
        $lon =~ s/^[ \-]+//;
#        die "parsed into '$zip' '$lat' '$lon'";
        $zipdb_obj->{$zip} = [$lon, $lat];
    }
    close(ZCW);
}

sub _new_instance {
    my $class = shift;
    my $self  = bless { }, $class;

    _zcw_init();
    
    return $self;
}


sub _zipdb_calc {
    my ($zcta, $z1, $z2) = @_;
    my $d1 = $zipdb_obj->{$z1};
    my $d2 = $zipdb_obj->{$z2};
    return undef if !$d1 || !$d2;

    my ($lon1, $lat1) = @$d1;
    my ($lon2, $lat2) = @$d2;
    my $dist = _great_circle_distance($lon1,$lat1,$lon2,$lat2);
    #warning("no distance between $z1 ($lon1,$lat1) and $z2 ($lon2,$lat2)") unless defined($dist);
    #warning("zero distance between $z1 ($lon2,$lat2) and $z2 ($lon2,$lat2)") if defined($dist) && $dist == 0 && ($z1 ne $z2);
    return $dist;
}

sub _zipdb_check {
    my ($zcta, $zc) = @_;
    return $zipdb_obj->{$zc};
}


sub _great_circle_distance
{
    my($lon1,$lat1,$lon2,$lat2) = @_;

    # Convert all the degrees to radians
    my $lat_1 = _deg_to_rad($lat1);
    my $lon_1 = _deg_to_rad($lon1);
    my $lat_2 = _deg_to_rad($lat2);
    my $lon_2 = _deg_to_rad($lon2);

    # Find the deltas
    my $delta_lat = $lat_2 - $lat_1;
    my $delta_lon = $lon_2 - $lon_1;

    # Find the Great Circle distance
    my $temp = sin($delta_lat/2.0)**2 + cos($lat_1) * cos($lat_2) * sin($delta_lon/2.0)**2;

    # EARTH_RADIUS = 3956
    my $distance = 3956 * 2 * atan2(sqrt($temp),sqrt(1-$temp));

    return($distance);
}

sub _deg_to_rad
{
    my($deg_2) = @_;
    my $radians = 0.0;
    my $pi = atan2(1,1) * 4;
    $radians = $deg_2 * $pi/180.0;
    return($radians);
}


=head1

It gets $rows as ref. to list of records with $zip_key and $miles_key fields in each record.
Then it sorts that list by distance from that place to specified $to_zip position.
Then it deletes from result list all places that are far from this $to_zip point more then $max_distance.
$max_distance is optional parameter.

$zip_key should be DBIx column name
$miles_key will be created as regular field (non-DBIx)

Returns sorted filtered list or undef if not such $to_zip in database

=cut

sub proximity_sort_rows {
    my ($self, $rows, $zip_key, $to_zip, $miles_key, $max_distance) = @_;

    # we don't need this as it's called in _new_instance
    #_zcw_init() unless $zipdb_obj;

    return undef unless $to_zip;
    # zero pad right
    $to_zip .= '0'x(5-length($to_zip)) if length($to_zip) < 5;
    return undef unless $to_zip =~ m/^\d{5}$/;

    if ( not &_zipdb_check($zipdb_obj, $to_zip) ) {
        return undef;
    }

    my $BAD_ZIP_DIST = 10000000;
    for (@$rows) {
        #my $from_zip = $_->{$zip_key};
        my $from_zip = $_->get_column($zip_key);
        my $dist = $BAD_ZIP_DIST;
        if ($from_zip =~ m/^(\d{5})/) {
            my $zip5 = $1;
            my $miles = $_->{$miles_key} = &_zipdb_calc($zipdb_obj, $zip5, $to_zip);
            if (!defined($miles)) {
                $miles = $BAD_ZIP_DIST;
            }
            $dist = $miles;
        }
        $_->{$miles_key} = ($dist == $BAD_ZIP_DIST ? $dist : sprintf("%0.2f", $dist));
    }
    my $pp = $miles_key;
    my $sorted = [sort {$a->{$pp} <=> $b->{$pp}} @$rows];

    # now clear out the values for miles_key where it was bad
    for (@$sorted) {
        delete $_->{$miles_key} if $_->{$miles_key} == $BAD_ZIP_DIST;
    }

    if ($max_distance) {
        $sorted = [grep {$_->{$pp} <= $max_distance} @$sorted];
    }
    return $sorted;
}


1;
