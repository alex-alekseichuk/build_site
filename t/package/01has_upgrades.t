#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
# use Test::More qw(no_plan);
use Data::Dumper;

use BST;
use BST::FolderItem;
use BST::Package;


# Preparing a package containing replaced file
my $oFile = BST::Package->load( { file_id => 'file_346950' } );
foreach ($oFile->items) {
    print $_->file->file_title . "\n";
}

print "After upgrade: \n";
my $newFile = $oFile->upgrade;
foreach ($newFile->items) {
    print $_->file->file_title . "\n";    
}

# $newFile->delete();
