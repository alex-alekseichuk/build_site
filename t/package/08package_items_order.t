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
use constant DOCS => qw(document130954 document199766);


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

my $addFiles = 3;
my $firstFile;
my $items = {};

my $files = BST::File->search({ scope => ['user', 'company'], is_deleted => ['false', 'f', undef, 0],  file_class => 'file', owner => LOCATION });
addDoc($_) foreach ((DOCS));
add($_) while (($_ = $files->next) && $addFiles--);

# print "Switching type to: submittal, filling TOC table\n";
# $oPkg->init_toc('submittal', $user); 
# switch();





sub add {
    local $_ = shift;
    $firstFile = $_ unless $firstFile;
    printf "Adding %s\t(%s)\n", $_->file_id, $_->file_title;
    $oPkg->add_item($_);
    $items->{$_->file_id} = 1;
}

sub addDoc {
    local $_ = shift;
	my $doc = BST::Document->load({ document_id => $_ });
	printf "Adding %s\t(%s)\n", $doc->document_id, $doc->title;
    $oPkg->add_item($doc);
}

sub remove {
    local $_ = shift;
    printf "Removing %s\t(%s)\n", $_->file_id, $_->file_title;
    $oPkg->remove( $_ );
    delete $items->{$_->file_id};
}


sub switch {
    my $type = shift || '';
    printf "Switching type to: %s\n", $type || 'none';
    $oPkg->package_toc_type( $type );
    $oPkg->save();
}