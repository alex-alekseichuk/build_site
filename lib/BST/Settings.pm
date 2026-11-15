use strict;
use warnings;

package BST::Setting;

use base qw/BST::Core BST::Schema::Setting/;
use BST::Scope;

=head1 DESCRIPTION

User Setting class - makes work with storage sweet

=cut


__PACKAGE__->table("setting");

# setting value (att_val field) is a utf8 string 
__PACKAGE__->load_components(qw/UTF8Columns/);
__PACKAGE__->utf8_columns(qw/att_val/);


sub name  { shift->att_name(@_) }
sub value { shift->att_val(@_) }

sub meta { 
    return BST::Settings->meta(shift->name);
}

sub owner {
    my $self = shift;

    my $r_level = $self->scope;
    my $r_value = $self->scope_value;
    
    if (BST::Scope->is_account($r_level)) {
        $self->{_owner} = BST::Account->load( {account_id => $r_value} );
    } elsif (BST::Scope->is_user($r_level)) {
        $self->{_owner} = BST::User->load( {user_id => $r_value} );
    } elsif (BST::Scope->is_location($r_level)) {
        $self->{_owner} = BST::Location->load( {account_location_id => $r_value} );
    }
    
    return $self->{_owner};
}






########################################

package BST::Settings;

use Params::Validate qw(:all);
use vars qw($SETTINGS $ROLES);

use BST::User;
use BST::Location;
use BST::Account;
use Data::Dumper;


use constant ALL_ROLES => "admin;normal;dealer;guest";


=DESCRIPTION

User settings class, interface to manipulate with a list of settings.
new() - requires settings owner as an argument. It might be one of BST::[User|Account|Location]

To access user (account, location) settings use list() method
If owner is a BST::User instance, you can call get_viewable() method to get the settings
which user can access

=cut
sub new {
    my ($class, $owner) = validate_pos(@_, SCALAR, SCALAR);

    return bless {
        _owner => $owner,
        _list  => {},
    }, $class;
}

sub set {}
sub get {}

sub owner {
    my $self = shift;
    return $self->{_owner};
}

use Carp qw(confess carp);

sub can_list {
    my $self = shift;
    my $scope = shift || carp "need a scope";
    my $val = shift;
    
    my $obj;
    return 0 unless scalar keys %{ $self->get_scope_set($scope) };

    if (BST::Scope->is_user($scope)) {
        my $oUser = BST::User->load( {user_id => $val} );
        return $self->owner->user_id eq $val || $oUser->can_write($self->owner) ? 1 : 0;
    } elsif (BST::Scope->is_location($scope)) {
        my $oLocation = BST::Location->load( {account_location_id => $val} );
        return $oLocation->can_write($self->owner) && $self->owner->is_account_admin ? 1 : 0;
    } elsif (BST::Scope->is_account($scope)) {
        my $oAccount = BST::Account->load( {account_id => $val} );
        return $oAccount->can_write($self->owner) ? 1 : 0;
    } else {
        return 0;
    }
}


=head1 list - class method

Returns hash with setting values, applied to user

=cut 
sub list {
    my $self = shift;

    my ($type, $val);
    if ((ref $self->owner) =~ /::User/) {
        $type = BST::Scope::USER;
        $val  = $self->owner->user_id;
    } elsif ((ref $self->owner) =~ /::Location/) {
        $type = BST::Scope::LOCATION;
        $val  = $self->owner->account_location_id;
    } elsif ((ref $self->owner) =~ /::Account/) {
        $type = BST::Scope::ACCOUNT;
        $val  = $self->owner->account_id;
    }

    return $self->{_list}
        if (scalar keys %{ $self->{_list} });

    my $s = $self->get_settings($type, $val);

    return $self->{_list} = $s->{all_scopes};
}


=head1 get_settings - class method

Returns hash, which contains level-detailed settings for a some scope

=cut 
sub get_settings {
    my $self = shift;
    my $restrict_scope = shift;
    my $restrict_val = shift;
    
    my $s = {
        BST::Scope::ALL => {},
        BST::Scope::ACCOUNT => {},
        BST::Scope::LOCATION => {},
        BST::Scope::USER => {},
        all_scopes => {}
    };
    
    my $scopes = $self->get_scope_set($restrict_scope, BST::Scope::ALL);
    my $values = {};
    $values->{BST::Scope::ALL} = BST::Scope::ALL if ($scopes->{BST::Scope::ALL});
    
    if (BST::Scope->is_user($restrict_scope)) {
        my $oUser = BST::User->load( {user_id => $restrict_val} );
        $values->{BST::Scope::USER} = $restrict_val;
        $values->{BST::Scope::LOCATION} = $oUser->get_column("primary_location") if ($scopes->{BST::Scope::LOCATION});
        $values->{BST::Scope::ACCOUNT}  = $oUser->account->account_id if ($scopes->{BST::Scope::ACCOUNT});
    } elsif (BST::Scope->is_location($restrict_scope)) {
        my $oLocation = BST::Location->load( {account_location_id => $restrict_val} );
        $values->{BST::Scope::LOCATION} = $oLocation->get_column('account_location_id');
        $values->{BST::Scope::ACCOUNT}  = $oLocation->get_column('account_id');
    } elsif (BST::Scope->is_account($restrict_scope)) {
        my $oAccount = BST::Account->load( {account_id => $restrict_val} );
        $values->{BST::Scope::ACCOUNT} = $restrict_val;
    }
    $s->{restrictions} = $values;
    

    # For each allowed scope we add an OR-condition to retrieve scope settings
    my $q = [ map {
        {
            scope => $_, 
            scope_value => $values->{$_}
        }
    } grep { $scopes->{$_} } $self->scopes ];
    
    # Ordering by scope: global settings should be first, user settings should be last
    my @order = map {
        \sprintf "scope = '%s'", $_;
    } (BST::Scope::USER, BST::Scope::LOCATION, BST::Scope::ACCOUNT, BST::Scope::ALL);


    foreach (BST::Setting->search( {'-or' =>  $q }, { order_by => \@order } ) ) {
        $s->{$_->scope}->{$_->name} = $_->value;
        $s->{all_scopes}->{$_->name} = $_->value;
    }

    return $s;
}

=head1 get_viewable - class method

Returns settings which can be viewed by the user

=cut 
sub get_viewable {
    my $self = shift;
    return [] unless ref ($self->owner) =~ m/::User/;

    my $restrict_scope = shift || $self->_get_default_scope();

    my $res = [];
    
    foreach my $setting(@$SETTINGS) {
        my $flag = $self->owner->is_bs_admin();
        foreach ($self->scopes) {
            $setting->{'applies_' . $_} = 1 if ($setting->{applies_levels} =~ m/$_/);
        }
        $flag = 1 if $setting->{'applies_' . $restrict_scope};
        push @$res, $setting if $flag;
    }
    
    my $role = $self->owner->primary_location->account->account_type;

    @$res = grep {$_->{show_to_roles} =~ $role} @$res;
    
    return $res;
}


=head1 meta - class method

Returns setting meta-information

=cut 
sub meta {
    my $pkg = shift;
    my $att_name = shift;
    foreach (@$SETTINGS) {
        return $_ if $_->{att_name} eq $att_name;
    }    
}


=head1 scopes - class method

Returns all possible scopes in the package

=cut 
sub scopes {
    return (BST::Scope::ALL, BST::Scope::ACCOUNT, BST::Scope::LOCATION, BST::Scope::USER);
}


=head1 _get_default_scope - class method

Returns default scope depending on user role

=cut 
sub _get_default_scope {
    my $self = shift;
    unless ((ref $self->owner) =~ m/::User/) {
        return BST::Scope::ACCOUNT if (ref $self->owner) =~ m/::Account/;
        return BST::Scope::LOCATION if (ref $self->owner) =~ m/::Location/;
    }

    return BST::Scope::ALL if ($self->owner->is_bs_admin());
    return BST::Scope::ACCOUNT if ($self->owner->is_account_admin());
    return BST::Scope::USER;
}


=head1 get_scope_list - class method

When user retrieves setting list, it's limits are set according to user rights.
Let's describe it with some cases:
  1. Single user views his own settings. Scopes are:
     [user]
  2. BSAdmin views location settings. Scopes are:
     [world, account, location, user]
  3. Account admin views settings of some user. Scopes are:
     [account, location, user]
     
So, we have the next chain:
  world -> account -> location -> user

Scope list starts from user default scope and ends with setting list scope.

=cut 
sub get_scope_set {
    my $self = shift;
    my $scope = shift;
    my $default_scope = shift || $self->_get_default_scope($self->owner);
    return { $default_scope => 1 } unless $scope;
    
    my @scopes = $self->scopes();
    shift @scopes while (@scopes && $scopes[0] ne $default_scope);
    pop @scopes while (@scopes && $scopes[$#scopes] ne $scope);
    
    return { map {; $_ => 1 } @scopes };
}



$SETTINGS = [ 
   {
        att_name => 'use_location_address_book',
        label => "Use Location's Address Book",
        description => 'The location with this setting will use the address book of the specified other location.',
        
        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'location',
    },
    {
        att_name => 'use_location_documents',
        label => "Use Location's Documents",
        description => 'The location with this setting will use the documents of the specified other location.',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'location',
    },
    { 
        att_name => 'default_allow_publishers',
        label => 'My Manufacturers',
        description => 'The subset of licensed manufacturers that we want to see by default.',

        show_to_roles => 'admin;normal;dealer',
        applies_account_types => 'normal;dealer',
        applies_levels => 'account;location',
    },
    {
        att_name => 'disable_dealer_search',
        label    => 'Disable dealer search',
        description => 'Controls whether dealer search should be blocked.',
        
        show_to_roles => 'admin',
        applies_account_types => 'normal;dealer;guest',
        applies_levels => 'account',
    },
    {
        att_name => 'can_send_messages',
        label    => 'Can send messages',
        description => 'Controls whether user can send email and faxes.&nbsp;&nbsp;Primarily used to give more/less features to demo/guest accounts.',

        show_to_roles => 'admin',
        applies_account_types => 'normal;dealer;guest',
        applies_levels => 'account;location',
    },
    {
        att_name => 'extra_features',
        label    => 'Extra features',
        description => 'What extra BuildSite features this account has access to (comma-separated list of keywords: productmatch, systemseller, relatedseller, companyresource).',

        show_to_roles => 'admin',
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
    {
        att_name => 'system_default_doc_types',
        label    => 'System default doc types',
        description => 'When related system products are shown, what document types to show by default without requiring expansion (comma-separated list of keywords: product_data, msds, installation_instructions, three_part_csi_spec).',

        show_to_roles => 'admin',
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
    {
        att_name => 'system_additional_docs',
        label    => 'System additional docs',
        description => 'When related system products are shown, whether to offer to show/hide the remaining documents beyond the default ones controlled by "system-default_doc_types".',

        show_to_roles => 'admin',
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
    {
        att_name => 'qa_features',
        label    => 'QA features',
        description => 'If true, then the extra features are only visible to the account itself (and buildsite administrators), not to other users.',

        show_to_roles => 'admin',
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
    {
        att_name => 'time_zone',
        label    => 'Time zone',
        description => 'Your time zone may be different than the time zone of the BuildSite server.&nbsp;&nbsp;If we know your time zone, we can correctly display times such as when a message was sent or when a file was uploaded.',

        show_to_roles => 'admin;normal;dealer',
        applies_account_types => 'admin;normal;dealer',
        applies_levels => 'all;account;location',
    },
    {
        att_name => 'area_code',
        description => 'All phone and fax fields will assume the Default Area Code if an area code is not entered.',
        label => 'Area Code Default',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'account;location;user',
    },
    {
        att_name => 'default_message_subject',
        description => 'Text that will be pre-filled in the "Subject:" line for any messages you send.&nbsp;&nbsp;You can override this for any message.',
        label => 'Message Subject Default',

        show_to_roles => 'admin;normal;dealer',
        applies_account_types => ALL_ROLES,
        applies_levels => 'account;location;user',
    },
    {
        att_name => 'default_message_body',
        description => 'Text that will be pre-filled in the "message body" area of any message you send. You can override this for any message.',
        label => 'Message Body Default',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'account;location;user',
    },
    {
        att_name => 'default_submittal_footer_comment',
        description => 'Default submital footer comment',
        label => 'Default Submittal Footer Comment',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'account;location;user',
    },
    {
    
        att_name => 'logo_file',
        label    => 'Logo file',
        description => 'An image file containing my company\'s logo.This logo is used on the top of fax cover pages.',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'account;location',
    },
    {
    
        att_name => 'signature_file',
        label    => 'Signature file',
        description => 'An image file containing a user\'s signature. This image is used for faxing signed forms. It should generally only be specified at the user level.',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'user',
    },
    {
    
        att_name => 'fax_cover_template_file',
        label=> 'Fax Cover Template',
        description => 'Template used to produce the fax cover page.<b>Do not touch this unless you are very sure about what you are doing.</b>',

        show_to_roles => 'admin',
        applies_account_types => 'admin',
        applies_levels => 'all;account',
    },
    {
    
        att_name => 'email_plain_template_file',
        label => 'Email Template',
        description => 'Template used to produce the email body.<b>Do not touch this unless you are very sure about what you are doing.</b>',

        show_to_roles => 'admin',
        applies_account_types => 'admin',
        applies_levels => 'all;account',
    },
    {
    
        att_name => 'sponsor_logo_file',
        label    => 'Sponsor logo file',
        description => 'Sponsoring accounts only: the image to be used in the nav pages of sponsored accounts. Typically color, unlike logo_file.',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
    {
    
        att_name => 'sponsor_logo_link',
        label    => 'Sponsor logo link',
        description => 'Sponsoring accounts only: an external url to go to when the sponsor logo is clicked. If none is specified, nothing happens upon an image click. Should start with "http".',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
    {
    
        att_name => 'sponsor_logo_title',
        label    => 'Sponsor logo title',
        description => 'Sponsoring accounts only: the tooltip and alt text to use for the img. Optional.',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'user',
    },
    {
    
        att_name => 'sponsor_logo_caption',
        label    => 'Sponsor logo caption',
        description => 'Sponsoring accounts only: html to appear after the image, giving the caption. Optional.',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
    {
    
        att_name => 'sponsor_default_folder_id',
        label    => 'Sponsor default folder id',
        description => 'Sponsoring accounts only: id of folder which sponsored accounts should see. "privateNNNN". Optional.',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
    {
    
        att_name => 'sponsor_default_folder_title',
        label    => 'Sponsor default folder title',
        description => 'Sponsoring accounts only: title of folder which sponsored accounts should see. "Some Title". Defaults to same title as in sponsoring account. Optional.',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
    {
    
        att_name => 'sponsor_override_folder_id',
        label    => 'Sponsor override folder id',
        description => 'Sponsored accounts only: override for sponsor_default_folder_title, if any. "privateNNNN". Optional.',

        show_to_roles => 'admin',
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
    {
    
        att_name => 'sponsor_override_folder_title',
        label    => 'Sponsor override folder title',
        description => 'Sponsored accounts only: override for sponsor_default_folder_title, if any. "Some Title". Optional.',

        show_to_roles => 'admin',
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
    {
    
        att_name => 'post_to_url_text',
        label    => 'Post to URL text template',
        description => 'Template used to produce the text for Post to URL block of message.',

        show_to_roles => 'admin',
        applies_account_types => 'admin',
        applies_levels => 'all;account',
    },
    {
    
        att_name => 'disable_send_package_url',
        label    => 'Disable send package as URL',
        description => 'Disable send package as URL',

        show_to_roles => 'admin',
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
    {
    
        att_name => 'disable_leed_submittals',
        label    => 'Disable LEED Submittals',
        description => 'Disable LEED Submittals',

        show_to_roles => ALL_ROLES,
        applies_account_types => ALL_ROLES,
        applies_levels => 'account',
    },
];

1;
