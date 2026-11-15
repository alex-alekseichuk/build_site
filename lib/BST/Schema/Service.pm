package BST::Schema::Service;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("service");
__PACKAGE__->add_columns(
  "service_nickname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "service_title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "amount",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 0,
    size => "2,10",
  },
  "recur_interval",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "service_discontinue_date",
  { data_type => "date", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("service_nickname");
__PACKAGE__->add_unique_constraint("service_pkey", ["service_nickname"]);
__PACKAGE__->add_unique_constraint("service_service_title_key", ["service_title"]);
__PACKAGE__->has_many(
  "customer_orders",
  "BST::Schema::CustomerOrder",
  { "foreign.service_nickname" => "self.service_nickname" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2WYCzxvaph3dnv/AYja72Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
