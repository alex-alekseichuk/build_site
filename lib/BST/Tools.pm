package BST::Tools;

=pod 

This is a collection of miscelaneous tools for the other BST modules.

=cut

use strict;
use Exporter;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK= qw(date_now date_now2);

use Date::Format;

# return current time in the local (server's) timezone, formatted as "2008-11-25 17:54:00"
sub date_now {
    my @array = localtime();
    return strftime( "%Y-%m-%d %T", @array );
}
sub date_now2 {
    my @array = localtime();
    return strftime( "%m/%d/%Y", @array );
}

sub test {
    print "Date now (date_now()): ", date_now(), "\n";
}

1;
