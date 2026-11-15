#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use StressCategory;

$ENV{TEST_METHOD} = 'test_stress';
Test::Class->runtests( 'StressCategory' );

=pod

This script runs tests from the t/category/lib/StressCategory.pm file.

To run a single instance, do this:

 $ CATLIST=t/categories/categories-short.txt  perl t/categories/03stress-test.t

or:

 $ perl t/categories/03stress-test.t

But it probaly only makes sense to run them in parallel as a bunch of processes:

$ echo perl t/categories/03stress-test.t | at now
$ echo perl t/categories/03stress-test.t | at now
$ echo perl t/categories/03stress-test.t | at now
$ echo perl t/categories/03stress-test.t | at now

=c
