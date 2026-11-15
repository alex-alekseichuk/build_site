use strict;

#use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::Message;
use Data::Dumper;

my $rs;
$rs = BST::Message->search({ message_id => 'legacy_sent_message_347042', sender => 'buildsite68104' }, { order_by => \ 'random()' });
my $m = $rs->next;

print Dumper $m->recipients->next->generate_pdf_fax_cover;

1;
