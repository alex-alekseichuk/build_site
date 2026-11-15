# copied from Template::Plugin::Cache

package Template::Plugin::BSACache;

use strict;
use vars qw( $VERSION );
use base qw( Template::Plugin );
use Template::Plugin;

$VERSION   = '0.1';

use constant BSA_HEAD_OPEN  => "<!-- bsa-cache\n";
use constant BSA_HEAD_CLOSE => "/bsa-cache -->\n";

#------------------------------------------------------------------------
# new(\%options)
#------------------------------------------------------------------------

sub new {
    my ( $class, $context, $params ) = @_;
    my $cache;
    
    unless ($params and ref $params eq 'HASH' and %$params) {
       my $self = bless { CONTEXT => $context }, $class;
       return $self;
    }
    elsif ( $params->{cache} ) {
        $cache = delete $params->{cache};
    }
    else {
        require Cache::FileCache;
        $cache = Cache::FileCache->new($params);
    }
    my $self = bless {
        CACHE   => $cache,
        CONFIG  => $params,
        CONTEXT => $context,
    }, $class;
    return $self;
}

#------------------------------------------------------------------------
# $cache->include({
#                 template => 'foo.html',
#                 keys     => {'user.name', user.name},
#                 ttl      => 60, #seconds
#                });
#------------------------------------------------------------------------

sub inc {
    my ( $self, $params ) = @_;
    $self->_cached_action( 'include', $params );
}

sub proc {
    my ( $self, $params ) = @_;
    $self->_cached_action( 'process', $params );
}

sub _cached_action {
    my ( $self, $action, $params ) = @_;
    my $key;
    if ( $params->{key} ) {
        $key = delete $params->{key};
    }
    else {
        my $cache_keys = $params->{keys};
        $key = join(
            ':',
            (
                $params->{template},
                map { "$_=$cache_keys->{$_}" } keys %{$cache_keys}
            )
        );
    }
    my $result = exists $self->{CACHE} ? $self->{CACHE}->get($key) : undef;
    if ( $result ) {
        substr(
            $result,
            index($result, BSA_HEAD_OPEN),
            index($result, BSA_HEAD_CLOSE) - index($result, BSA_HEAD_OPEN) + length(BSA_HEAD_CLOSE)
        ) = undef;
    }
    else {
        $result = $self->{CONTEXT}->$action( $params->{template} );
        
        my $bsa_head;
        $bsa_head .= 'bsa-cache-url: "'   . BST->current->{req}->uri->as_string . "\"\n"
            if BST->current and BST->current->{req};
        $bsa_head .= 'bsa-cache-group: "' . BST->current_user->cache_group_id   . "\"\n"
            if BST->current_user;
        $bsa_head .= 'bsa-cache-key: "'   . $key                                . "\"\n";
        
        $result = BSA_HEAD_OPEN . $bsa_head . BSA_HEAD_CLOSE . $result;
        
        $self->{CACHE}->set( $key, $result, $params->{ttl} )
            if exists $self->{CACHE};
    }
    return $result;
}

1;