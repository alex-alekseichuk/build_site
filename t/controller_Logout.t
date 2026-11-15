use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'BSA' }
BEGIN { use_ok 'BSA::Controller::Search' }

ok( request('/logout')->is_success, 'Request should succeed' );


