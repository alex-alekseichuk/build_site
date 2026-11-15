
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBCheck;
use BST;

DBCheck::save_report(
    
    'multiple_docs_with_same_title'
    , DBCheck::multiple_docs_with_same_title);

