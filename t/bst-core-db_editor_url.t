use strict;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

use BST;
use BST::Attribute;

my $attr = BST::Attribute->load(id => 'material_cost');

isa_ok($attr, 'BST::Core');

ok($attr->db_editor_url eq 
        BST::config('db_editor_site')
        . '/'
        . 'attribute'
        . '/'
        . 'material_5Fcost'
    , 'db_editor_url ok');

1;
