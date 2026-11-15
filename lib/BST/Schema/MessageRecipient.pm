package BST::Schema::MessageRecipient;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("message_recipient");
__PACKAGE__->add_columns(
  "recipient_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "message_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
  "address",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "contact_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "status",
  {
    data_type => "character varying",
    default_value => "'pending'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "send_type",
  {
    data_type => "character varying",
    default_value => "'to'::character varying",
    is_nullable => 0,
    size => 10,
  },
);
__PACKAGE__->set_primary_key("recipient_id");
__PACKAGE__->add_unique_constraint("pk_message_recipient", ["recipient_id"]);
__PACKAGE__->belongs_to(
  "message_id",
  "BST::Schema::Message",
  { message_id => "message_id" },
);
__PACKAGE__->belongs_to(
  "contact_id",
  "BST::Schema::AddressbookPerson",
  { private_person_id => "contact_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Wx7BGQu+vjN9arwmyliobA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
