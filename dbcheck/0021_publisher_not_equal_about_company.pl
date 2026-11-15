
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBCheck;
use BST;

DBCheck::save_report(
    
    'publisher_not_equal_about_company'
    , DBCheck::publisher_not_equal_about_company);

