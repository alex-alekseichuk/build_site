#!/usr/bin/perl

use strict;
use Getopt::Compact;

our $VERSION = 0.3;

# sort param => [array index, sort type (string|numeric), default sort direction]
my %SORT = (
    url    => [1, 's', 'asc'],
    count  => [2, 'n', 'desc'],
    total  => [3, 'n', 'desc'],
    method => [4, 'n', 'desc'],
    tt     => [5, 'n', 'desc'],
);

# trim uls that are too long
my $URL_LENGTH = 40;

my $opts = new Getopt::Compact(
    name => 'perfomance statistics',
    struct => [
        [[qw(l log)],      qq(log file path), '=s'],
        [[qw(u url)],      qq(url to search), ':s'],
        [[qw(o format)],   qq(output format: table [default], tabs, avg or cumulative), ':s'],
        [[qw(f from)],     qq(start time, eq 12.00), ':s'],
        [[qw(t to)],       qq(end time, eg 18.00), ':s'],
        [[qw(s sort)],     qq(sort field: count [default], url, total, method or tt), ':s'],
        [[qw(d dir)],      qq(sort direction: asc or desc), ':s'],
    ]
)->opts();

$opts->{log} or die "--log parameter is required";
$opts->{format} ||= 'table'; $opts->{sort} ||= 'count';

my @from = split /\D+/, $opts->{from}; $opts->{from} and scalar @from != 2 and die 'Incorrect --from parameter';
my @to   = split /\D+/, $opts->{to};   $opts->{to}   and scalar @to   != 2 and die 'Incorrect --to parameter';

substr($opts->{url}, 0, 1) eq '/' or $opts->{url} = '/' . $opts->{url} if $opts->{url};

open FILE, $opts->{log} or die "Can't open $opts->{log}: $!";

my %request; my %avg; my @pool;
while (<FILE>) {
    if (/\[\w+\s+\w+\s+\d+\s+(\d+):(\d+):\d+\s+\d+\]\s*\*+/) {
        $request{time} and $request{url} and push @pool, {%request};

        %request = ();
        next if (scalar @from and cmp_time([$1, $2], [@from ]) == -1);
        next if (scalar @to   and cmp_time([@to   ], [$1, $2]) == -1);
        $request{time} = "$1:$2";
    }
    $request{time} or next;

    if (/"\w+" request for "([^"]+)" from "/) {
        my $url = $1;
        substr($url, 0, 1) eq '/' or $url = '/' . $url;
        if ($opts->{url}) {
            index($url, $opts->{url}) == 0 or next;
        }

        substr($url, $URL_LENGTH) = '...' if length $url > $URL_LENGTH;
        $request{url} = $url;

        $url =~ s/\?.*$//;
        $request{url_stripped} = $url;

        $avg{$url}->{count}++;
    }
    $request{url} or next;

    if (/Request took (\d+(\.\d+)?)s/) {
        $request{full} = $1; $avg{$request{url_stripped}}->{full} += $1;
    }
    elsif (/\|\s*\/?(\w+).*?\|\s*(\d+(\.\d+)?)s/) {
        $1 eq 'auto' and next; $1 eq 'end' and next;
        $request{method} += $2; $avg{$request{url_stripped}}->{method} += $2;
    }
    elsif (/\|.*?->process.*?\|\s*(\d+(\.\d+)?)s/) {
        $request{template} += $1; $avg{$request{url_stripped}}->{template} += $1;
    }
}
close FILE;

$request{time} and $request{url} and push @pool, {%request};

my @output; my @output_avg;

if ($opts->{format} ne 'avg' and $opts->{format} ne 'cumulative') {
    foreach my $row(@pool) {
        push @output, [map { $row->{$_} } qw(time url undef full method template)];
    }
}

foreach my $url(sort { $avg{$b}->{count} <=> $avg{$a}->{count} } keys %avg) {
    push @output_avg, [
        ($opts->{format} eq 'cumulative' ? 'cumulative' : 'avg'),
        $url,
        $avg{$url}->{count},
        map {
            $opts->{format} eq 'cumulative'
            ?
            $avg{$url}->{$_}
            :
            $avg{$url}->{$_} / $avg{$url}->{count}
        } qw(full method template)];
}

foreach my $row(@output, @output_avg) {
    map { $row->[$_] = sprintf "%.3f", $row->[$_] } (3..5);
}

# sorting
if (my $sort = $SORT{$opts->{sort}}) {
    my $dir = $opts->{dir} || $sort->[2];
    @output = $sort->[1] eq 's'
        ?
        sort { die $a->[$sort->[0]] cmp $b->[$sort->[0]] } @output
        :
        sort { $a->[$sort->[0]] <=> $b->[$sort->[0]] } @output
    unless $opts->{sort} eq 'count';

    @output_avg = $sort->[1] eq 's'
        ?
        sort { $a->[$sort->[0]] cmp $b->[$sort->[0]] } @output_avg
        :
        sort { $a->[$sort->[0]] <=> $b->[$sort->[0]] } @output_avg
    ;

    @output     = reverse @output     if $dir eq 'desc' and $opts->{sort} ne 'count';
    @output_avg = reverse @output_avg if $dir eq 'desc';
}

if ($opts->{format} eq 'tabs') {
    foreach (@output, [], @output_avg) {
        print scalar @$_ ? join "\t", @$_ : "-" x 80;
        print "\n";
    }
}
else {
    use Text::Table;
    my $table = Text::Table->new(\' | ', map { $_, \' | ' } 'Time', 'URL', 'Count', 'Total time', 'Method time', 'TT time');

    $table->load(@output, [undef], @output_avg);
    print $table->title;
    print $table->rule('-', '+');
    print $table->body;
    print $table->rule('-', '+');
}

sub cmp_time {
    my @time1 = @{$_[0]};
    my @time2 = @{$_[1]};

    return ($time1[0] <=> $time2[0]) || ($time1[1] <=> $time2[1]);
}