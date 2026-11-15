
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBCheck;
use BST;

DBCheck::save_report(
    
    'publisher_no_publications'
    , DBCheck::publisher_no_publications);

