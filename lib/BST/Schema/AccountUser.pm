package BST::Schema::AccountUser;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("account_user");
__PACKAGE__->add_columns(
  "given_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "family_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "vcard_fullname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "vcard_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "job_title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "work_phone",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "cell_phone",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "fax_phone",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "home_phone",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "pager_phone",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "email_address",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "comment",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "user_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "staff_user",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "user_password",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "preferences",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "user_role",
  {
    data_type => "character varying",
    default_value => "'enduser'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "primary_location",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "primary_only",
  {
    data_type => "character varying",
    default_value => "'false'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "login_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "mail_opt_out",
  {
    data_type => "character varying",
    default_value => "'false'::character varying",
    is_nullable => 1,
    size => 250,
  },
  "user_department",
  {
    data_type => "character varying",
    default_value => "'other'::character varying",
    is_nullable => 1,
    size => 250,
  },
  "email_opt_out",
  {
    data_type => "character varying",
    default_value => "'false'::character varying",
    is_nullable => 1,
    size => 250,
  },
  "block_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "block_access",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "block_reason",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "test_user",
  {
    data_type => "character varying",
    default_value => "'false'::character varying",
    is_nullable => 1,
    size => 250,
  },
  "email_opt_out_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "mail_opt_out_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "document_queue",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11000,
  },
  "current_message_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "current_package_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
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
__PACKAGE__->set_primary_key("user_id");
__PACKAGE__->add_unique_constraint("pk_buildsite_user", ["user_id"]);
__PACKAGE__->belongs_to(
  "current_message_id",
  "BST::Schema::Message",
  { message_id => "current_message_id" },
);
__PACKAGE__->belongs_to(
  "current_package_id",
  "BST::Schema::File",
  { file_id => "current_package_id" },
);
__PACKAGE__->has_many(
  "files",
  "BST::Schema::File",
  { "foreign.creator_user" => "self.user_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jGrxOUsSzvl48Rjyn/tmVA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
