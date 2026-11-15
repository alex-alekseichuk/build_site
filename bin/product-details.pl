use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::Product;

my $p = BST::Product->load( product_id => $ARGV[0] );

my $cat = $p->category->category_id;
if (length $cat > 5) { $cat =~ s/(.{5})(.+)/$1.$2/ }

print join "\n", ('Manufacturer: ' . $p->manufacturer->legal_name || "",
                  'Product Name: ' . $p->product_name,
                  'Category:     '     . $cat . ' - ' . $p->category->category_title,
                  ($p->buildsite_public_notes)
                  ? ( 'Description:   ' . $p->buildsite_public_notes )
                  : (),
                  ($p->productmatch_active)
                  ? ( 'Mfg Flags:      ' . $p->mfg_flags , 
                      'Mfg Short Text: ' . $p->mfg_short_text , 
                      'Mfg Long Text: '  . $p->mfg_long_text )
                  : ()
    );

print "\n\n";
print "Product Documents \n";
foreach ($p->documents) {
    print "\t", $_->doc_type->dt_label;
    printf " - %.f kb", $_->derived_filesize / 1024;
    printf ' - %d pg', $_->derived_pagecount;
    print "\n";
}

print "\nCategory Documents \n";
foreach ($p->category_documents) {
    print "\t", $_->doc_type->dt_label, ' - ', $_->publisher_document_title;
    printf " - %.f kb", $_->derived_filesize / 1024;
    printf ' - %d pg', $_->derived_pagecount;
    print "\n";
}

print "\nCompany Documents \n";
foreach ($p->manufacturer->documents) {
    print "\t", $_->doc_type->dt_label, ' - ', $_->publisher_document_title;
    printf " - %.f kb", $_->derived_filesize / 1024;
    printf ' - %d pg', $_->derived_pagecount;
    print "\n";
}

