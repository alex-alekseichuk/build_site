package BST::Schema::Company;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("company");
__PACKAGE__->add_columns(
  "company_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "company_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "branch_of_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "division_of_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "linecard_grouping_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "location_phone",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "location_fax",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_po",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_street",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_city",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_region",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_postal_code",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_country",
  {
    data_type => "character varying",
    default_value => "'US'::character varying",
    is_nullable => 1,
    size => 250,
  },
  "legal_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "company_nickname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "company_url",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "company_logo_file",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "sweets_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "company_summary_text",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11000,
  },
  "public_contact_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "public_contact_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "public_contact_phone",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "public_visible",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 1,
    size => 1,
  },
  "suppress_reason_code",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 250,
  },
  "buildsite_public_notes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11000,
  },
  "check_flags",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "buildsite_private_notes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 15000,
  },
  "incident_log",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 30000,
  },
  "publisher_status",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "permission_granted",
  {
    data_type => "character varying",
    default_value => "'false'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "content_via",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "last_qa_complete_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "last_media_received_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "last_publish_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "last_update_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "next_media_update_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "next_paper_update_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "next_web_update_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "web_update_interval",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "went_live_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "company_search_tsvector",
  {
    data_type => "tsvector",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "company_search_keywords",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
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
__PACKAGE__->set_primary_key("company_id");
__PACKAGE__->add_unique_constraint("company_pkey", ["company_id"]);
__PACKAGE__->has_many(
  "accounts",
  "BST::Schema::Account",
  { "foreign.company_id" => "self.company_id" },
);
__PACKAGE__->has_many(
  "account_locations",
  "BST::Schema::AccountLocation",
  { "foreign.company_location_ref" => "self.company_id" },
);
__PACKAGE__->belongs_to(
  "linecard_grouping_id",
  "BST::Schema::Grouping",
  { grouping_id => "linecard_grouping_id" },
);
__PACKAGE__->belongs_to(
  "division_of_id",
  "BST::Schema::Company",
  { company_id => "division_of_id" },
);
__PACKAGE__->has_many(
  "company_division_of_ids",
  "BST::Schema::Company",
  { "foreign.division_of_id" => "self.company_id" },
);
__PACKAGE__->belongs_to(
  "branch_of_id",
  "BST::Schema::Company",
  { company_id => "branch_of_id" },
);
__PACKAGE__->has_many(
  "company_branch_of_ids",
  "BST::Schema::Company",
  { "foreign.branch_of_id" => "self.company_id" },
);
__PACKAGE__->has_many(
  "company_features",
  "BST::Schema::CompanyFeature",
  { "foreign.company_id" => "self.company_id" },
);
__PACKAGE__->has_many(
  "company_groupings",
  "BST::Schema::CompanyGrouping",
  { "foreign.company_id" => "self.company_id" },
);
__PACKAGE__->has_many(
  "company_keywords",
  "BST::Schema::CompanyKeyword",
  { "foreign.company_id" => "self.company_id" },
);
__PACKAGE__->has_many(
  "customer_accounts",
  "BST::Schema::CustomerAccount",
  { "foreign.company_id" => "self.company_id" },
);
__PACKAGE__->has_many(
  "document_original_publisher_ids",
  "BST::Schema::Document",
  { "foreign.original_publisher_id" => "self.company_id" },
);
__PACKAGE__->has_many(
  "document_about_company_ids",
  "BST::Schema::Document",
  { "foreign.about_company_id" => "self.company_id" },
);
__PACKAGE__->has_many(
  "legacy_account_locations",
  "BST::Schema::LegacyAccountLocation",
  { "foreign.company_location_ref" => "self.company_id" },
);
__PACKAGE__->has_many(
  "products",
  "BST::Schema::Product",
  { "foreign.manufacturer_id" => "self.company_id" },
);
__PACKAGE__->has_many(
  "publications",
  "BST::Schema::Publication",
  { "foreign.company_id" => "self.company_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EWKFrsVbsQZDCMyR3wm2hw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
