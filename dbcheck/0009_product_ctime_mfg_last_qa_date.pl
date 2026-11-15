
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBCheck;
use BST;

DBCheck::save_report(
    
    'product_ctime_mfg_last_qa_date'
    , DBCheck::product_ctime_mfg_last_qa_date);

