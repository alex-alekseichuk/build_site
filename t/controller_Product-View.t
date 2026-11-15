use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'BSA' }
BEGIN { use_ok 'BSA::Controller::Product::View' }

ok( request('/product/view')->is_success, 'Request should succeed' );


