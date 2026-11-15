#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
# use Test::More qw(no_plan);  
use Data::Dumper;

use BST;
use BST::PackageToc;
use BST::File;


my $oFile = BST::File->load({ file_id => 'file_258464' });
my $oPkg = BST::PackageToc->load({file_id => 'file_258459' });

print Dumper $oPkg->find_toc_item($oFile);
