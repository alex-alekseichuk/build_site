
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBCheck;
use BST;

DBCheck::save_report(
    
    'product_obsolete_category'
    , DBCheck::product_obsolete_category);

