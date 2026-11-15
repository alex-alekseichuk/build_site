#!/usr/bin/perl -w
use Data::Dumper;

use strict;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use BST;
use BST::PackageToc; 


my $oFile = BST::PackageToc->load( { file_id => shift @ARGV } );
my $data = $oFile->package_toc_data;

$Data::Dumper::Pad = '<br>';
$data->{meta}->{ajax} = 2;
$oFile->package_toc_data($data);
$oFile->save();
