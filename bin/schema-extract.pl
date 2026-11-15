use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBIx::Class::Schema::Loader qw/make_schema_at/;
use File::Copy;
use BST;

my $config = BST::config;
BST::Schema->storage_type("::DBI::Pg");

#DBIx::Class::Schema::Loader->dump_to_dir('../doc');
my $schemaPm = "$Bin/../lib/BST/Schema.pm";
my $schemaPmBak = $schemaPm . ".bak";

move($schemaPm, $schemaPmBak);

make_schema_at(
    'BST::Schema',
    {
        really_erase_my_files => 1,
        components => 'InflateColumn::DateTime',
        resultset_components => '',
        additional_classes => '',
        exclude => qr/(legacy)/,
#        debug => 1,
        dump_directory => "$Bin/../lib",
    },
        [
            &BST::dsn(),
            $config->{dbuser},
            $config->{dbpass}
        ]
    );

move($schemaPmBak, $schemaPm);
