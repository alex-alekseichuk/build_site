use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

print `perl $Bin/db-upgrade.pl`;
print `perl $Bin/static-compress.pl`;