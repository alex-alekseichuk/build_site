
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBCheck;
use BST;

DBCheck::save_report(
    
    'company_no_nickname'
    , DBCheck::company_no_nickname);

