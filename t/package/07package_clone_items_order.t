#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Test::More qw(no_plan);  
use Data::Dumper;

use BST;
use BST::PackageToc;
use BST::File;

use constant LOCATION => 'muller_construction_supply_sanjose';
use constant CREATOR  => 'buildsite279177';
use constant DOCS => qw(document360586 document130954 document263594 document199766);


my $oPkg;
my $user = BST::User->load({ user_id => CREATOR });

unless (@ARGV) {
    $oPkg = BST::PackageToc->create();
    $oPkg->owner(LOCATION);
    $oPkg->creator_user(CREATOR);
    $oPkg->file_title('#685 test');
    $oPkg->is_public(1);
    $oPkg->is_deleted(0);
    $oPkg->file_class('archive');
    $oPkg->scope('user');
    $oPkg->insert();
    printf "Created new package: %s\n", $oPkg->file_id;
} else {
    $oPkg = BST::Package->load({ file_id => shift @ARGV });
    printf "Package loaded: %s\n", $oPkg->file_id;
}

$oPkg->clear();

my $addFiles = 1;
my $moreFiles = 1;
my $items = {};
my $order = [];

print "Switching type to: submittal, filling TOC table\n";
$oPkg->init_toc('submittal', $user); 

my $files = BST::File->search({ scope => ['user', 'company', 'location'], is_deleted => ['false', 'f', undef, 0],  file_class => 'file', owner => LOCATION });
add($_) while (($_ = $files->next) && $addFiles--);
addDoc($_) foreach ((DOCS));
add($_) while (($_ = $files->next) && $moreFiles--);


$oPkg->clear_items_cache();

foreach ($oPkg->items) {
    push @$order, $_->is_file ? scalar $_->file : scalar $_->document;
}


my $new = $oPkg->clone();
$new->scope( 'hidden' );
$new->save(); 

my $i = 0;
foreach ($new->items) {
    my $old = shift @$order;
    my $new = $_->is_file ? scalar $_->file : scalar $_->document;
    ok($new eq $old, sprintf "%d\told: %s, new: %s\n", ++$i, $new, $old);
}


sub add {
    local $_ = shift;
    $oPkg->add_item($_);
    $items->{$_->file_id} = 1;
}

sub addDoc {
    local $_ = shift;
	my $doc = BST::Document->load({ document_id => $_ });
    $oPkg->add_item($doc);
}

sub switch {
    my $type = shift || '';
    printf "Switching type to: %s\n", $type || 'none';
    $oPkg->package_toc_type( $type );
    $oPkg->save();
}
