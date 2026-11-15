package DBProfiler;

use strict;
use warnings;

use base 'DBIx::Class::Storage::Statistics';

use Time::HiRes qw(time);

my $start;
my $count;
my $total;

sub query_start {
    my $self    = shift;
    my $sql     = shift;
    my @params  = @_;
    
    $sql =~ s/\?/shift @params/ge;
    
    $self->print('-' x 80 . "\nEXECUTING SQL QUERY NUMBER $count WITH " . scalar @_ . " PARAMS:\n\n$sql\n\nPARAMS LIST:\n");
    $self->print("$_\n") foreach @_;
    
    $start = time(); $count++;
}

sub query_end {
    my $self    = shift;
    my $sql     = shift;
    
    my $elapsed = sprintf("%0.4f", time() - $start);
    $total += $elapsed;
    $self->print("\nExecution took $elapsed seconds. Total: $total\n" . '-' x 80 . "\n");
    undef $start;
}

1;
