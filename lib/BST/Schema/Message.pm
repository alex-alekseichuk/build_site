package BST::Schema::Message;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("message");
__PACKAGE__->add_columns(
  "message_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "body_file_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "sender",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "owner",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "recipient_fkey",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "recipient_address",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "recipient_address_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "time_sent",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "message_template_type",
  {
    data_type => "character varying",
    default_value => "'generic'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "status_received_epoch",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "message_status",
  {
    data_type => "character varying",
    default_value => "'sent'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "message_status_ack",
  {
    data_type => "character varying",
    default_value => "'none'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "group_message_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "base_message_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "attached_file_ids",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 30000,
  },
  "subject",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "body",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "package_id",
  {
    data_type => "character varying",
    default_value => "NULL::character varying",
    is_nullable => 1,
    size => 250,
  },
  "message_ext_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "attach_type",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 250,
  },
  "auto_ctime",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 0,
    size => 8,
  },
  "auto_mtime",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("message_id");
__PACKAGE__->add_unique_constraint("pk_sent_message", ["message_id"]);
__PACKAGE__->has_many(
  "account_users",
  "BST::Schema::AccountUser",
  { "foreign.current_message_id" => "self.message_id" },
);
__PACKAGE__->has_many(
  "message_recipients",
  "BST::Schema::MessageRecipient",
  { "foreign.message_id" => "self.message_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y+9ZqFSnQkDtLpPiLMTNgQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
