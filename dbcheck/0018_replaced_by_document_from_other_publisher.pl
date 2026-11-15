
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBCheck;
use BST;

DBCheck::save_report(
    
    'replaced_by_document_from_other_publisher'
    , DBCheck::replaced_by_document_from_other_publisher);

