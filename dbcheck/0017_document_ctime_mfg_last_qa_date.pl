
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBCheck;
use BST;

DBCheck::save_report(
    
    'document_ctime_mfg_last_qa_date'
    , DBCheck::document_ctime_mfg_last_qa_date);

