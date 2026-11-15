
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBCheck;
use BST;

DBCheck::save_report(
    'bad_checkflags'
    , DBCheck::bad_checkflags);

