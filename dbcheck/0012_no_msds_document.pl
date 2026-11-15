
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBCheck;
use BST;

DBCheck::save_report(
    
    'no_msds_document'
    , DBCheck::no_msds_document);

