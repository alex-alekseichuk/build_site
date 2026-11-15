package BST::Schemaversions;

use strict;
use warnings;

use base qw/BST::Core DBIx::Class/;

__PACKAGE__->load_components("Core");
__PACKAGE__->table("schemaversions");
__PACKAGE__->add_columns(
    "version" => {
        data_type => "character varying",
        default_value => undef,
        is_nullable => 0,
        size => 10,
    },
    "installed" => {
        data_type => "character varying",
        default_value => undef,
        is_nullable => 0,
        size => 20,
    },
);

__PACKAGE__->set_primary_key("version");

1;
