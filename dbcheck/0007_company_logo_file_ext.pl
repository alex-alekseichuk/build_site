
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBCheck;
use BST;

DBCheck::save_report(
    
    'company_logo_file_ext'
    , DBCheck::company_logo_file_ext);

