package BST::SettingItem;

use strict;
use base qw( Class::Factory );
use BST::Settings;


=DESCRIPTION

An interface for settings editing.
Subclasses may contain validation routines, value-list generating methods and so on

new() - requires BST::Setting as an argument.

=cut
sub new {
    my $self = shift;
    my $oSetting = shift;
    my $viewer = shift;

    my $ftype = $oSetting->name;
    $ftype = 'default' unless grep m/$ftype/, $self->get_registered_types();
    my $class = $self->get_factory_class( $ftype );

    $self = bless( {_setting => $oSetting, viewer => $viewer }, $class );
    return $self;
}


=head1 init - class method

Abstract initialization, never used yet

=cut 
sub init {}



=head1 owner - class method

Emulates property contains the setting owner (level_type_id-dependent object, determined with level_restrict_val)

=cut 
sub owner {
    my $self = shift;
    return $self->setting->owner;
}


=head1 setting - class method

Emulates property contains the setting object

=cut 
sub setting {
    my $self = shift;
    return $self->{_setting};
}



=head1 can_write - class method

Checks write-access for the setting.
Buildsite admin can write everything, account admin can set (or change) account's settings, settings of all account users and locations. Single user can modify only his own settings.

=cut 
sub can_write {
    my $self = shift;
    my $user = shift;

    return 1 if $user->is_bs_admin();

    if (BST::Scope->is_user($self->setting->scope)) {
        return 1 if $self->setting->scope_value eq $user->user_id;
        return 1 if $user->is_account_admin() && $self->owner->primary_location->account->account_id eq $user->primary_location->account->account_id;
    }
    
    return 0 unless $user->is_account_admin();
    my $aid = $user->primary_location->account->account_id;
    
    if (BST::Scope->is_location($self->setting->scope)) {
        return 1 if $self->owner->account->account_id eq $aid;
    }
    
    if (BST::Scope->is_account($self->setting->scope)) {
        return 1 if $self->owner->account_id eq $aid;
    }
    
    return 0;
}


=head1 can_read - class method

Checks read-access for the setting.
Buildsite admin can read every setting, account admin can see account settings, settings of all account's locations, settings of account's users. Single user can see his own settings, his location's settings and his account's settings

=cut 
sub can_read {
    my $self = shift;
    my $user = shift;

    return 1 if $user->is_bs_admin();
    return $self->can_write($user) if $user->is_account_admin();
    
    return 1 if BST::Scope->is_user($self->setting->scope) && $user->user_id eq $self->setting->scope_value;
    return 1 if BST::Scope->is_location($self->setting->scope) && $user->primary_location->account_location_id eq $self->setting->scope_value;
    return 1 if BST::Scope->is_account($self->setting->scope) && $user->primary_location->account->account_id eq $self->setting->scope_value;
    
    return 0;
}

# Select types
__PACKAGE__->register_factory_type('use_location_address_book' => 'BST::SettingItem::Select::Location');
__PACKAGE__->register_factory_type('use_location_documents' => 'BST::SettingItem::Select::Location');
__PACKAGE__->register_factory_type('default_allow_publishers' => 'BST::SettingItem::Select::Manufacturer');
__PACKAGE__->register_factory_type('time_zone' => 'BST::SettingItem::Select::Timezone');


# Checkbox types
__PACKAGE__->register_factory_type('disable_dealer_search' => 'BST::SettingItem::Checkbox');
__PACKAGE__->register_factory_type('can_send_messages' => 'BST::SettingItem::Checkbox');
__PACKAGE__->register_factory_type('system_additional_docs' => 'BST::SettingItem::Checkbox');
__PACKAGE__->register_factory_type('qa_features' => 'BST::SettingItem::Checkbox');
__PACKAGE__->register_factory_type('disable_send_package_url' => 'BST::SettingItem::Checkbox');
__PACKAGE__->register_factory_type('disable_leed_submittals' => 'BST::SettingItem::Checkbox');


# File types
__PACKAGE__->register_factory_type('logo_file' => 'BST::SettingItem::File');
__PACKAGE__->register_factory_type('signature_file' => 'BST::SettingItem::File');
__PACKAGE__->register_factory_type('fax_cover_template_file' => 'BST::SettingItem::File');
__PACKAGE__->register_factory_type('email_plain_template_file' => 'BST::SettingItem::File');
__PACKAGE__->register_factory_type('sponsor_logo_file' => 'BST::SettingItem::File');


# Other types
__PACKAGE__->register_factory_type('area_code' => 'BST::SettingItem::AreaCode');
__PACKAGE__->register_factory_type('default_message_body' => 'BST::SettingItem::Textarea');
__PACKAGE__->register_factory_type('post_to_url_text' => 'BST::SettingItem::Textarea');

__PACKAGE__->register_factory_type('default' => 'BST::SettingItem::Default');

=head1 AUTHOR

Nikolai Liohenki <kalyansky@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
