use strict;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::Message;

my $rs;
$rs = BST::Message->search({}, { order_by => \ 'random()' });
my $m = $rs->next;

ok(ref $m->time_sent eq 'DateTime', 'Result class for datetime field is DateTime');

1;
