#!/usr/bin/perl

use strict;
use Getopt::Compact;
use Cache::FileCache;
use Text::Table;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use Template::Plugin::BSACache;

my @INFO_FIELDS = qw(url group key); my $INFO_FIELDS = join '|', @INFO_FIELDS;

my $BSA_HEAD_CLOSE = Template::Plugin::BSACache->BSA_HEAD_OPEN;

my $getopt = new Getopt::Compact(
    name => 'template cache cleaner',
    struct => [
        [[qw(u url)],   qq(URL pattern), ':s'],
        [[qw(g group)], qq(user group), ':s'],
        [[qw(a all)],   qq(clean all files), '!'],
    ]
);
my $opts = $getopt->opts();

unless ($opts->{url} or $opts->{group} or $opts->{all}) {
    print $getopt->usage();
    exit;
}

my $cache = new Cache::FileCache(BST::config('html_cache'));
my $root  = BST::config('html_cache')->{cache_root} . '/' . (BST::config('html_cache')->{namespace} || 'Default');
my $cmd   = "find $root -type f";

if ($opts->{url}) {
    $cmd .= " | xargs grep -l 'bsa-cache-url: \".*$opts->{url}.*\"'";
}

if ($opts->{group}) {
    $cmd .= " | xargs fgrep -l 'bsa-cache-group: \"$opts->{group}\"'";
}

if ($cmd) {
    if (-e $root) {
        my $table = Text::Table->new(\' | ', map { $_, \' | ' } 'Key', "Size\n&right", 'Group', 'URL');
        
        my $size = 0; my $count;
        foreach my $file(split /\n+/, `$cmd`) {
            my %info = get_info($file) or next;
            $count++; $size += $info{size};
            $table->add(
                $info{key},
                (sprintf "%.1f K", $info{size} / 1024),
                $info{group},
                $info{url}
            );
            
            unlink $file;
        }
        
        $table->add(undef);
        $table->add(undef, (sprintf "%.1f K", $size / 1024));
        
        if ($count) {
            print $table->rule('-', '+');
            print $table->title;
            print $table->rule('-', '+');
            print $table->body;
            print $table->rule('-', '+');
        }
        else {
            print "   No files found\n\n";
        }
    }
    else {
        print "   Cache root doesn't exist\n\n";
    }
}

print "   Files left: ", scalar $cache->get_keys(), "\n";
print "   Cache size: ", (sprintf "%.1f K", $cache->size() / 1024), "\n";

sub get_info {
    local $_;
    my $file = shift;
    my %info = ();
    
    open FILE, $file or return undef;
    while (<FILE>) {
        last if $_ eq $BSA_HEAD_CLOSE;
        next unless /^bsa\-cache\-($INFO_FIELDS)\: "(.*)"$/;
        $info{$1} = $2;
    }
    close FILE;
    
    $info{size} = (stat $file)[7];
    
    return %info;
}