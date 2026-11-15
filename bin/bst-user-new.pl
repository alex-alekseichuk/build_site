use strict;

use Data::Dumper;

my $u = BST::User->load(user_id => 'vicki');
#print Dumper $u;
print Dumper $u->location;
#$u->given_name('Pats');
#$u->update;

################################################################################
package BST::Core1;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST qw(schema);

sub load {
    my $class = shift;
    my $params = ref $_[0] ? $_[0] : {@_};
    my @obj = $class->search($params);

    return @obj[0]
        if scalar @obj == 1;

    return;
}

sub new { shift->_init(shift) }

sub _init {
    return bless { _row => @_[1] }, @_[0];
}

sub search {
    my $class = shift;
    my $params = shift;

    my @results = schema->resultset( 'BST::Schema::LegacyBuildsiteUser' )->search($params);

    return map { $class->_init($_) } @results;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my ($sub) = ($AUTOLOAD =~ /([^\:]+)$/);

    return $self->{_row}->$sub(@_);
}

sub DESTROY {}
1;
################################################################################
package BST::Location;
use base qw(BST::Core1);
1;
################################################################################
package BST::User;

use Data::Dumper;
use base qw(BST::Core1);

sub location { shift->primary_location }
sub primary_location { BST::Location->new( shift->{_row}->primary_location ) }

sub primary_location { 
	my $self = shift;
	return $self->{primary_location} if $self->{primary_location}; 
	return $self->{primary_location} = BST::Location->new( $self->{_row}->primary_location ); 
}

1;
