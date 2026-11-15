
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBCheck;
use BST;

DBCheck::save_report(
    
    'publisher_no_match_publication_id'
    , DBCheck::publisher_no_match_publication_id);

