package BST::Cursor;

use strict;
use warnings;
use 5.6.1;
use Storable;
use Digest::SHA1;

use BST qw(config);

sub new {
  my $class = shift;
  my ($storage, $args, $attrs) = @_;
  
  $class = ref $class if ref $class;
  # This gives us the class the storage object -would- have used
  # (since cursor_class is inherited Class::Accessor::Grouped type)
  my $inner_class = (ref $storage)->cursor_class;
  my $inner = $inner_class->new(@_);
  
  if ($attrs->{cache_for} && grep { $_ eq $args->[0]->[0]->{me} } @{ config('schema_cache_tables') }) {
    my %args = (
      inner => $inner,
      cache_for => delete $attrs->{cache_for},
      cache_object => delete $attrs->{cache_object},
      # this must be here to ensure the deletes have happened
      cache_key => $class->_build_cache_key(@_),
      pos => 0
    );
    return bless(\%args, $class);
  }
  return $inner; # return object that -would- have been constructed.
}

sub next {
  my ($self) = @_;
  return @{($self->{data} ||= $self->_fill_data)->[$self->{pos}++]||[]};
}

sub all {
  my ($self) = @_;
  return @{$self->{data} ||= $self->_fill_data};
}

sub reset {
  shift->{pos} = 0;
}

sub _build_cache_key {
  my ($class, $storage, $args, $attrs) = @_;
  return Digest::SHA1::sha1_hex(Storable::nfreeze([ $args, $attrs ]));
}

sub _fill_data {
  my $self  = shift;
  
  my $cache = $self->{cache_object};
  my $key   = $self->{cache_key};
  
  return $cache->get($key) || do {
    my $data = [ $self->{inner}->all ];
    $cache->set($key, $data, $self->{cache_for});
    $data;
  };
}

sub clear_cache {
  my ($self) = @_;
  $self->{cache_object}->remove($self->{cache_key});
  delete $self->{data};
}

sub cache_key { shift->{cache_key} }

1;