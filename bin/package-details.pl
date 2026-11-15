#!/usr/bin/perl

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;
use BST qw(schema);
use BST::Package;
use BST::Document;
use BST::PackageToc;
#use open OUT => 'utf8';
#use open ":std";

binmode( STDOUT, ":utf8" );

my ($raw, $resettoc, $tweak, $inittoc, $id, $json, $localfiles);
$raw = $resettoc = 0;

for my $arg (@ARGV) {
    if ( $arg =~ m/-raw/) {
        $raw = 1;
    } elsif ( $arg =~ m/-json/) {
        $json = 1;
    } elsif ( $arg =~ m/-resettoc/) {
        $resettoc = 1;
    } elsif ( $arg =~ m/-tweak/) {
        $tweak = 1;
    } elsif ( $arg =~ m/-init:(\w+)/) {
        $inittoc = $1;
    } elsif ( $arg =~ m/-files/ ) {
        $localfiles = 1;
    } else {
        $id = $arg;
    }
}

sub val ($) {
    my $value = shift;
    if (not defined $value) { return 'NULL'; }
    return $value;
}

sub print_raw {
    my $returned = &schema->storage->dbh->selectrow_hashref("SELECT * FROM file WHERE file_id=\'$id\'");
    foreach my $k ( BST::Package->columns )  {
	my $v;
	if (!defined $returned->{$k}) { $v = 'NULL'; }
	else { $v = "'". $returned->{$k} . "'"; }
        print sprintf "%20s: %s\n", $k, $v;
    }
}

if ($resettoc) {
    my $returned = &schema->storage->dbh->selectrow_hashref("SELECT * FROM file WHERE file_id=\'$id\'");
    if ($returned) {
        &schema->storage->dbh->do("UPDATE file SET package_toc_type=NULL, package_toc_data=NULL, package_toc_template=NULL WHERE file_id=\'$id\'");
        print "toc is reseted\n";
        print_raw();
    }
} elsif ($raw) {
    print_raw();

} elsif ($json) {
    my $p = BST::Package->load( id => $id );
    print_json($p);

} elsif ($tweak) {

    #print_raw();

    my $p = BST::Package->load( id => $id );
    my $tocdata = $p->package_toc_data;
    my $table = $tocdata->{table};
    #my $dump = Dumper($table);
    $p->package_toc_data($tocdata);
    $p->save();
    print "\nresaved toc_data\n";

} elsif ($inittoc) {

    #print_raw();

    my $p = BST::Package->load( id => $id );
    $p->init_toc( $inittoc );
    $p->save();
    print "\ninit toc to $inittoc\n";

} else {
    my $p = BST::Package->load( id => $id ) || die "can't find such package";

    print 'id: '    . $p->id . "\n";
    print 'title: ' . val $p->file_title . "\n";
    print 'owner: ' . val $p->owner->account_location_id . "\n";
    print 'replaced by doc: ' . val $p->replaced_by_doc . "\n";

    print 'contents: ' . "\n";
    foreach ($p->items) {
        my $item = ($_->document_id || $_->file_id);
        print "\t(" . $_->id . ") \t" . ($item)->id . ": " . ($item->title || "") . "\n";
    }

    if ($p->package_toc_type) {
        print 'toc type: ' . $p->package_toc_type . "\n";
        print 'toc meta: ' . "\n" ;
        print "\t $_: " . val $p->package_toc_data->{meta}->{$_} . "\n" for (sort keys %{$p->package_toc_data->{meta}});
        print "toc data: \n";
        my $i = 0;
        for my $row (@{$p->package_toc_data->{table}}){
            print "\t\[$i\]: \n";
            print "\t\t$_: " . val $row->{$_} . "\n" for (grep {$_ ne "items"} sort keys %$row );
            print "\t\titems: \n";
            my $j = 0;
            for my $item (@{$row->{items}}) {
                print "\t\t\t\[$j\]: \n";
                print "\t\t\t\t$_: " . val $item->{$_} . "\n" for sort keys %$item;
                $j++;
            }
            $i++;
        }
    }
    if($localfiles) { print_localfiles($p); }
}

sub print_json {
    my $p = shift;
    my $json = $p->json;
    print Dumper( $json );
}



sub print_localfiles {
    my $p = shift;
    my $files = $p -> items_local_files;
    my $faxable = $p->items_can_faxed;
    
    map { delete $_->{self} } @$files;
    map { delete $_->{self} } @$faxable;
    map { delete $_->{related_resultsets} } @$faxable;
    @$faxable = map { $_->file ? $_->file->id : $_->document->id } @$faxable;
    my $items = [$p->items];
    $items = [ map {$_->file || $_->document} @$items ];
    $items = [ map {$_->id} @$items ];
    #print "files: ", Dumper($files);

    print "total size (bytes): ", $p->total_size_bytes, "\n";
    print "total pages: ", $p->total_pages, "\n";
    print "message limits exceeded: ", Dumper( [ $p->check_message_limits ] );

    print "items: ", Dumper($items);
    print "faxable: ", Dumper($faxable);
}
