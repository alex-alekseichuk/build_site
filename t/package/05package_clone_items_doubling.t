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
my $moreFiles = 2;
my $firstFile;
my $items = {};

my $files = BST::File->search({ scope => ['user', 'company', 'location'], is_deleted => ['false', 'f', undef, 0],  file_class => 'file', owner => LOCATION });
die 'no files found' if not $files->count;

add($_) while (($_ = $files->next) && $addFiles--);

#print "Switching type to: submittal, filling TOC table\n";
$oPkg->init_toc('submittal', $user); 

die if not scalar $oPkg->items;

#switch();
my $new = $oPkg ->clone;

#add($_) while (($_ = $files->next) && $moreFiles--);
#remove( $firstFile) if $firstFile;
#switch('submittal');

$new->scope( 'hidden' );
$new->save;

my $table = $new->package_toc_data->{table};
my $items = {};
my $extra = {};

foreach ($new->items) {
    my $id = ($_->file) ? $_->file->id : $_->document->id;
    $items->{$id} = 1;
}

die if not scalar keys %$items;

foreach (@$table) {
    my $rowitems = $_->{items};
    foreach( @$rowitems ) {
        my $id = $_->{id};
        if (defined $items->{$id}) {
            delete $items->{$id};
#            print "found correct package_item $id\n";
        } else {
            $extra->{$id} = 1;
            print "found extra package_item $id\n";
        }
    }
}

#print scalar keys %$extra, "\n";
#print scalar keys %$items, "\n";

ok(scalar keys %$extra eq 0, 'Each item happens just once');
#ok(scalar keys %$items eq 0, 'All items were synchronized');




sub add {
    local $_ = shift;
    $firstFile = $_ unless $firstFile;
#    printf "Adding %s\t(%s)\n", $_->file_id, $_->file_title;
    $oPkg->add_item($_);
    $items->{$_->file_id} = 1;
}

sub remove {
    local $_ = shift;
#    printf "Removing %s\t(%s)\n", $_->file_id, $_->file_title;
    $oPkg->remove( $_ );
    delete $items->{$_->file_id};
}


sub switch {
    my $type = shift || '';
#    printf "Switching type to: %s\n", $type || 'none';
    $oPkg->package_toc_type( $type );
    $oPkg->save();
}
