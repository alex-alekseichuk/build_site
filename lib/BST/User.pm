package BST::User;

use strict;
use warnings;
use Carp qw (croak);
use Carp::Assert;
require Exporter;

use Params::Validate qw(:all);

# order of the base classes is significant
use base qw/Exporter BST::Core BST::Schema::AccountUser/;
# this is a hack! :) without whis thing object will be blessed into BST::Schema::*
__PACKAGE__->table('account_user');

use BST::RootFolder;
use BST::Location;
use BST::Settings;
use BST::Contact;
use BST::ContactCompany;
use BST::Package;

use Data::Dumper;
use POSIX qw(strftime);


our @EXPORT_OK = qw( ROLE_SINGLE_USER ROLE_BUILDSITE_ADMIN ROLE_ACCOUNT_ADMIN );
use constant ROLE_SINGLE_USER => 1;
use constant ROLE_BUILDSITE_ADMIN => 2;
use constant ROLE_ACCOUNT_ADMIN => 3;


=head1 DESCRIPTION

User object

=cut

__PACKAGE__->belongs_to(
  "primary_location",
  "BST::Location",
  { "foreign.account_location_id" => "self.primary_location" },
);

__PACKAGE__->has_many(
  "messages",
  "BST::Message",
  { "foreign.sender" => "self.user_id" },
);

__PACKAGE__->might_have(
  "current_message_id",
  "BST::Message",
  { "foreign.message_id" => "self.current_message_id" },
);

__PACKAGE__->might_have(
  "current_package_id",
  "BST::Package",
  { "foreign.file_id" => "self.current_package_id" },
);

sub location         { shift->primary_location(@_)  }
sub account          { shift->location->account(@_) }

sub settings         { 
    my $self = shift;
    $self->{_settings} = new BST::Settings($self) unless defined $self->{_settings};
    return $self->{_settings};
}
sub private_folder   { BST::RootFolder->new(shift, BST::Scope::USER) }
sub location_folder  { BST::RootFolder->new(shift, BST::Scope::LOCATION) }
sub account_folder   { BST::RootFolder->new(shift, BST::Scope::ACCOUNT) }
sub all_folder       { BST::RootFolder->new(shift, BST::Scope::ALL) }

=head1 authenticate_login - class method

do some checks on user login

=cut
sub authenticate_login {
    validate_pos( @_,
                  { type => OBJECT },
                  { type => SCALAR },
    );
    my ($self, $pass) = @_;

# check that user is not blocked
    $self->error->user_is_blocked && return
        if ($self->block_access);

# checking password
    $self->error->wrong_password && return
        unless ($pass eq $self->user_password);

# checking that user account location is not blocked
    $self->error->account_location_is_blocked && return
        if ($self->location->block_access);

# cheking that user account is not blocked
    $self->error->account_is_blocked && return
        if ($self->account->block_access);

# checking account expiration date
    $self->error->account_expired && return
        if ($self->account->expiration_date gt strftime("%Y-%m-%d", localtime));

    return 1
        unless $self->error->status;

    return;
}

# return fullname
sub name {
    my $self = shift;
    my $s = '';
    $s = ucfirst lc $self->given_name;
    $s .= ' ' . ucfirst lc $self->family_name
        if $self->family_name;
    return $s;
}


sub contact_person_search {
    my $self = shift;
    my $q = shift;

    my $keywords;
    if ($q) {
        $keywords = &BST::Core::_keywords_to_regexps_n(1, $q);
        return wantarray ? () : undef
            unless $keywords;
    }

    my $query = shift || {};
    my $order = shift || '';

    $query->{'-or'} = [
        q~given_name || ' ' || family_name~ => [ -and => @$keywords ],
        given_name       => [ -and => @$keywords ],
        family_name      => [ -and => @$keywords ],
        company_fullname => [ -and => @$keywords ],
        email_address => [ -and => @$keywords ],
        fax_phone => [ -and => @$keywords ]
    ] if $q;

    return $self->_find_person($query, $order);
}


sub _find_person {
    my $self = shift;
    my $query = shift;
    my $order = shift || 'private_person_id';

    $query->{owner} = $self->_addressbook_location unless defined $query->{owner};

    my $filter = {};
    my $ambigious = { map {; $_ => 1 } qw(owner addressbook_company_id) };

    foreach (keys %$query) {
        my $field = $ambigious->{$_} ? 'me.' . $_ : $_;
        $filter->{$field} = $query->{$_};
    }
    
    $filter->{fax_phone} =~ s/\D//g if defined $filter->{fax_phone};

    return BST::Contact->search(
        $filter,
        {
            join     => 'addressbook_company_id',
            prefetch => 'addressbook_company_id',
            order_by => $order,
        },
    );
}


# this is used in BSA::Controller::Messages, when creating 
# the message recipients for a message.
sub find_or_create_person {
    my $self = shift;
    my $filter = shift;
    my $create = shift;
    my $obj;    

    my @all = $self->_find_person($filter);

    return shift @all if (@all);
    return undef unless ($create);

    # create a name from email address (or even fax)
    if (not $filter->{given_name}) {
        my $name = $filter->{email_address} ? $filter->{email_address} : $filter->{fax_phone};
        $name ||= '';
        $filter->{given_name} = $name;
    }
    return $self->create_new_contact_person($filter);
}


# create a new contact person record
sub create_new_contact_person {
    my $self = shift || die;
    my $data = shift || {};
    assert( $data->{given_name} ) if DEBUG;
    $data->{fax_phone} =~ s/[^0-9\+]//g if defined $data->{fax_phone};
    $data->{fax_phone} =~ s/(.)\+/$1/g;

    my $obj = BST::Contact->create(
        {%$data, owner => $self->_addressbook_location } 
    );
    
    $obj->save();
    return $obj;
}

# create a new contact company record
sub create_new_contact_company {
    my $self = shift || die;
    my $data = shift || {};
    assert( $data->{company_fullname} ) if DEBUG;

    my $obj = BST::ContactCompany->create(
        {%$data, owner => $self->_addressbook_location } 
    );
    
    $obj->save();
    return $obj;
}


sub _addressbook_location {
    my $self = shift;
    return $self->settings->list->{'use_location_address_book'} || $self->location->account_location_id;
}

sub contact_company_search {
    my $self = shift;
    my $q = shift;
    my $order = shift || '';

    # kill all trash
    {local $/ = ' '; chomp $q }
    $q =~ s/\W{2,}/ /g;

    my $query  = {};

    $query->{'-or'} = [
        company_fullname => [ -and => map +{'~*', "\\m$_"}, split(' ', $q) ],
        ] if $q;

    return BST::ContactCompany->search(
        {
            owner => $self->_addressbook_location,
            %$query,
        },
        {
            order_by => $order,
        },
    );
}





sub _complete_scope_list {
    my $element = shift;
    my $parent_id = shift;
    my $folders = shift;

    return unless $parent_id;
    return unless $folders->{$parent_id};

    my $parent = $folders->{$parent_id};
    $element->{path} = $parent->{title} . "\\" . $element->{path};
    _complete_scope_list($element, $parent->{parent_id}, $folders) if ($parent->{parent_id});

    #print Dumper($folders) . "\n";
}

sub _get_scope_list {
    my $scope = shift;
    my $ref_folders = shift;
    my @folders = @$ref_folders;

    my %scopes = map {
            my $hash = {
                id => $_->file_id,
                title => $_->file_title,
                path => $_->file_title . "\\",
                parent_id => undef
            };
            $hash->{parent_id} = $_->parent->file_id if ($_->parent);

            $_->file_id => $hash;
        } @folders;
    map {
        _complete_scope_list($_, $_->{parent_id}, \%scopes) if ($_->{parent_id});
    } values %scopes;
    map {
        delete $_->{parent_id};
        delete $_->{title};
    } values %scopes;

    my @sorted = sort { uc($a->{path}) cmp uc($b->{path}) } values %scopes;

    unshift @sorted,
        {
            id => "_" . $scope,
            path => ""
        };
    return @sorted;
}


=head1 get_all_folders - class method

returns all drawer folders available for the user
call with $scopes param to hide specified folders from users without required permissions

=cut

sub get_all_folders {
    my $self = shift;
    my $scopes = shift || [BST::Scope::USER, BST::Scope::LOCATION, BST::Scope::ACCOUNT];

    my $titles = {
        BST::Scope::USER => 'Private',
        BST::Scope::LOCATION => 'Location',
        BST::Scope::ACCOUNT => 'Company'
    };

    my @all_folders = ();

    foreach my $scope (@$scopes) {
        my @folders = BST::Folder->search( {
            %{ BST::FolderItem->get_default_search_filter(file_class => 'folder') },
            %{ BST::FolderItem->get_scope_search_filter($scope, $self) },
            scope => $scope,
        } );

        @folders = _get_scope_list $scope, \@folders;
        my $title = $titles->{$scope};
        map { $_->{path} = $title . ":\\" . $_->{path}; } @folders;
        splice @all_folders, $#all_folders + 1, 0, @folders;
     }

    return @all_folders;
}


=head1 get_role - class method

returns user role (single-user, account admin, buildsite admin)

=cut

sub get_role {
    my $self = shift;
    return $self->{_role} if defined $self->{_role};

    my $atype = $self->primary_location->account->account_type;
    return $self->{_role} = ROLE_BUILDSITE_ADMIN if ($atype eq 'admin');
    return $self->{_role} = ROLE_ACCOUNT_ADMIN if ($self->user_role eq 'admin');
    return $self->{_role} = ROLE_SINGLE_USER;
}


sub is_bs_admin {
    my $self = shift;
    return $self->get_role() == ROLE_BUILDSITE_ADMIN;
}

sub is_account_admin {
    my $self = shift;
    return $self->get_role() == ROLE_ACCOUNT_ADMIN;
}

sub is_single_user {
    my $self = shift;
    return $self->get_role() == ROLE_SINGLE_USER;
}


sub can_read {
    my $self = shift;
    return 1;
}


sub can_write {
    my $self = shift;
    my $accessor = shift;

    return 1 if $accessor->is_bs_admin();
    return 1 if $accessor->is_account_admin() && $self->primary_location->account->account_id eq $accessor->primary_location->account->account_id;
    return 0;
}

sub get_submittal_meta_from {
    my $self = shift;

    my $company = $self->primary_location->account->company;
    return $self->name . ($self->job_title ? ", " . $self->job_title : "")
                . ($company ?  ", " . $company->name : "")
                . ($self->fax_phone ? (', ' . $self->email_address) : "")
                . ($self->email_address ? ( ', ' . $self->email_address) : '');
}

sub cache_group_id {
    my $self = shift;
    
    return 'staff'
        if $self->is_bs_admin;
        
    return 'guest'
        unless $self->account->company;
        
    return $self->account->company->company_id
        if grep { $_->feature_status eq 'qa' } $self->account->company->features;
        
    return 'guest';
}

1;
