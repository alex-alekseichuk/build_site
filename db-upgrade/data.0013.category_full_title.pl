#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use BST;
use BST::Category;


my @categories = BST::Category->search({})->all;

for my $category (@categories) {
	$category->category_full_title($category->full_title);
	$category->save();
}