package BST::Core;

use strict;
use warnings;

use Params::Validate qw(:all);
use Digest::MD5 qw/md5_hex/;
use Data::Dumper;

use BST qw(schema);

use constant HAS_DBIX_RELATION_BUG => defined $DBIx::Class::VERSION && $DBIx::Class::VERSION < 0.09;

use overload '""' => sub { shift->id }, fallback => 1;

=DESCRIPTION

=head1 Common Methods

=head2 create($params)

creates the new object entity with the params specified

=head2 save()

saves the object (either new or changed) in the db

=head2 search($params)

finds 0 or more records in db, creates objects for them and returns ResultSet of these objects
in scalar context. And array of fetched one - in array.

=head2 delete()

deletes the entity

=head2 working with PK

We need no to specify PK field directly in most of our requests. We can use 'id' as a alias
to class PK. Use it when you load class, get PK value. And set PK value via accessor $obj->id().
$obj->set_columns({ id => 'value' }) does't set PK value!

=cut

sub error  { BST::error()                           }
sub logger { BST::Logger->instance(@_)              }
#sub load   { BST::load(shift =~ /::([^:]+)$/, @_)   }
sub search { BST::search(shift =~ /::([^:]+)$/, @_) }

sub load {
    my ($class, $pkcolumn, $pkvalue, $locking) = validate_pos(@_,
                 { type => SCALAR },
                 { type => HASHREF | SCALAR },
                 { type => SCALAR | UNDEF,  optional => 1 },
                 { type => SCALAR,  optional => 1 },
    );

    my $source = $class;
    if ( $class =~ /::([^:]+)$/ ) { $source = $1; }
    my $rs = BST::schema()->resultset( $source );

    # build the where hash
    my $where;
    if (ref $pkcolumn eq 'HASH') {
        $where = $pkcolumn;
    } elsif( defined $pkvalue ) {
        $where = { $pkcolumn => $pkvalue };
    } else {
        $where = { 'id' => $pkcolumn };
    }

    if ( exists $where ->{id} ) {
        my @pks = $rs->result_source->primary_columns;
        die "can't load object of a class without primary columns: $class\n"
            unless scalar @pks;
        my $val = delete $where->{id};
        # we assume just one pk column:
        $where ->{$pks[0]} = $val;
    }

    if($ENV{DBIC_TRACE}) {
        my @w;
        foreach (keys %$where) {
            push @w, $_ . '=' . $where->{$_};
        }
        my ( $package,   $filename, $line,       $subroutine, $hasargs,
             $wantarray, $evaltext, $is_require, $hints,      $bitmask
            ) = caller(1);
        print STDERR "LOAD $source {", join( ',', @w ), "} from $subroutine, line $line\n";
    }
    #use Data::Dumper;
    #warn Dumper( $where );

    if ($locking) {
        return $rs->find($where, { locking => $locking });
    } else {
        return $rs->find($where);
    }

}



sub create {
    my $obj = BST::create(shift, @_);

    # Bug representation can be found in dbix-relation-belongs.t
    #   related 'belongs_to'-object is set to garbage-value for just created object
    #   we fix it with simple reading of linked field value
    if (HAS_DBIX_RELATION_BUG) {
        sub get_rel_key {
            my $rel = shift;
            my ($key) = grep m/self\./, %{ $rel->{cond} };
            $key =~ s/self\.//;
            return $key;
        }

        foreach ($obj->relationships) {
            my $rel = $obj->relationship_info($_);
            if ($rel->{attrs}->{accessor} eq 'single') {
                my $key = get_rel_key($rel);
                $obj->$key;
            }
        }
    }

    return $obj;
}

sub save   {
    my $self = shift;

    # save object in DBIx
    $self->insert_or_update;

    # save object in our object cache
    #BST::cache()->set($self->table . ":" . $self->id, $self);

    # save related objects
    while ( my ($n, $v) = each %{ $self->{related_resultsets} } ) {
        if ($v->{attrs}->{accessor} ne 'multi' && $v->count == 1) {
            eval { $self->$n->save() };
            if ($@) {
                #print STDERR Dumper ($n, $v);
            }
        }
    }
}

#sub delete {
#}

sub id {
    my $self = shift;
    my $pk = ($self->primary_columns)[0];
    return $self->$pk(@_);
}

=head1 inflate phone columns

use next 2 subs to format\store various phone numbers:

    __PACKAGE__->inflate_column(
        fax_phone  => {
            inflate => \&BST::Core::_phone_inflate,
            deflate => \&BST::Core::_phone_deflate,
        },
    );

=cut

sub _phone_inflate {
    $_ = $_[0];
    s/[^0-9+]//g;
    return $_ unless /\d+/;
    s/(\d{3})(\d{3})(\d{4})$/ ($1) $2-$3/;
    return $_;
}

sub _phone_deflate {
    $_ = $_[0];
    s/[^0-9+]//g;
    return $_;
}


sub search_field {
    my $self = shift;
    my $fields = shift;
    my $table = shift || 'me';

    my $search_field = join " || ' ' || ", map {
        ref $_ ? $$_ : sprintf "coalesce(%s, '')", (m/\./ ? $_ : $table . "." . $_)
    } @$fields;

    return $search_field;
}

=head2 keywords_filter

    $search_fields = arrayref
    $keywords = arrayref
    $composite_keywords = arrayref
    $term = 'and'/'or'

=cut

sub keywords_filter {
    my $class = shift;
    my $search_field = shift;
    my $keywords = shift;
    my $composite_keywords = shift;
    my $term = shift || 'and';

    return undef unless (@$keywords or @$composite_keywords);
    return undef unless $search_field;

    my $re_keywords = [];
    my $re_composite_keywords = [];

    @$re_keywords = @$keywords;
    @$re_composite_keywords = @$composite_keywords;

    # Processing keywords
    &BST::Core::_keywords_to_regexps_without_split(@$re_keywords);
    &BST::Core::_keywords_to_regexps_without_split(@$re_composite_keywords);


    if ('or' eq $term) {
        # or-search
        push @$re_keywords, @$re_composite_keywords;
        return { $search_field => [ '-or' => @$re_keywords ] },
    }

    # and-search otherwise
    $keywords = scalar(@$keywords) == 1 ?
        { "~*" => "\\m" . $keywords->[0] } :
        [ '-and' => @$re_keywords ]
    ;

    my $filter = {
        $search_field => $keywords
    };

    if (scalar(@$composite_keywords)) {
        my $composite_keywords = 1 == scalar(@$composite_keywords) ?
            { "~*" => "\\m" . $composite_keywords->[0] } :
            ['-or' => @$re_composite_keywords]
        ;

        $filter = {
            '-or' => [
                $filter,
                {
                    $search_field => $composite_keywords
                }
            ]
        };
    }

    return $filter;
}


# returns array of splitted keywords from input string
sub _split_search_keywords {
    my $input = $_[0];

    my $SPACE_CHARS = '_:,!"#%()*+-/;' ;
    my $KEEP_CHARS = 'A-z\d\s@';

    for($input) {
        s/[$SPACE_CHARS]/ /g;
        s/[^$KEEP_CHARS]//g;
    }

    return split(' ', $input);
}


# search conditions in fulltext regexp search
sub _keywords_to_regexps {
    @_ = &_split_search_keywords(@_);
    return undef unless @_;
    return _keywords_to_regexps_without_split(@_);
}
sub _keywords_to_regexps_n {
    my $n = shift;
    @_ = &_split_search_keywords(@_);
    return undef unless @_;
    return _keywords_to_regexps_without_split_n($n, @_);
}

sub _escape_to_regexps {
    my $s = shift;
    $s =~ s/([.*+?[\]()\\\/])/\\$1/g;
    return $s;
}
sub _keywords_to_regexps_without_split {
    return undef unless @_;
    return _keywords_to_regexps_without_split_n(3, @_);
}
sub _keywords_to_regexps_without_split_n {
    my $n = shift;
    return undef unless @_;

    foreach (@_) {

        # escape special regexp chars
        $_ =~ s/([.*+?[\]()\\\/])/\\$1/g;

        # prepare posix postgresql regexp; ignore-case
        if    (/^\d+$/)      { $_ = { '~*' => $_ } }
        elsif (length() < $n) { $_ = { '~*' => "\\m$_\\M" } }
        else                 { $_ = { '~*' => "\\m$_" } }
    }
    return [@_];
}

#sub DESTROY { shift->save() }


=head2 inflate_result

some caching magick

=cut

sub inflate_result {
    my $class       = shift;
    my $struct      = shift;
    my $vals        = shift;
    my $prefetch    = shift;

    # results, where no pk is selected must not be cached. next line duplicates last, cause of some annoying warning
    if (my @map = map { $vals->{$_} } grep { exists($vals->{$_}) } $struct->primary_columns) {
        my $cache   = BST::cache();
        my $id      = $class->table . ":" . join( '-', @map );

        return $cache->get($id) || $cache->set($id, $class->next::method($struct, $vals, $prefetch));
    } else {
        return $class->next::method($struct, $vals, $prefetch);
    }
}


=item find_related

find_related() method is called on DBIx::Row objects by itself, when
a related object is requested.

remove preceding __ to enable it.

see DBIx::Class::Relationship::Base for more info
http://search.cpan.org/~ash/DBIx-Class-0.08010/lib/DBIx/Class/Relationship/Base.pm

=cut

sub find_related {
    my $self = shift;
    my $accessor = shift;

    if ($ENV{DBIC_TRACE}) {
        my $class= ref $self;

        my ( $package,   $filename, $line,       $subroutine, $hasargs,
             $wantarray, $evaltext, $is_require, $hints,      $bitmask );
        my $i = 1;
        while($i) {
            ( $package,   $filename, $line,       $subroutine, $hasargs,
              $wantarray, $evaltext, $is_require, $hints,      $bitmask ) = caller($i++);
            last if not $subroutine;
            last if $subroutine =~ m/^BS[TA]::/;
            last if $subroutine eq "(eval)";
        }
        $subroutine ||= $package || '';
        $line ||= '';
        print STDERR "FIND RELATED $class($self) \-> $accessor from $subroutine, line $line\n";
        if (not $subroutine) {
            $i = 1;
            while($i) {
                ( $package,   $filename, $line,       $subroutine, $hasargs,
                  $wantarray, $evaltext, $is_require, $hints,      $bitmask ) = caller($i);
                last if not $subroutine;
                print STDERR " [$i] $subroutine, line $line"
                    ,($evaltext) ? " (eval: $evaltext)"   : ''
                    ,"\n"
                    ;
                $i++;
            }
        }
    }
#    print Dumper( [$accessor, @_] ); # @_ == ({},{})


    # Q: how do we know the primary key or other details of the
    # related object, if we are not given anything here?
    # if we knew, we could look it up in our cache.

    # A: see below, actually -- it works.
    # it's something like that.
    # only for objects with single primary_key field linked to some foreign key
    my $rel_obj = $self->result_source->relationship_info($accessor);
    my $id;

    if ($rel_obj->{attrs}->{accessor} eq 'single') {
        foreach my $k (keys %{$rel_obj->{cond}}) {
          my $v = $rel_obj->{cond}->{$k};
          if (
              $k =~ s/^foreign\.//
              &&
              $v =~ s/^self\.(.*)$//
              ) {
              $id = $self->get_column($1);
              last;
          }
        }
    }

    # there is not ID, so, use non-cache way
    if (! defined $id) {
        return $self->next::method($accessor, @_);
    }

    my $cache   = BST::cache();
    my $key     = $rel_obj->{class} ->table . ":$id";

    return $cache->get($key) || $cache->set($key, $self->next::method($accessor, @_));
}


=item can_read() and can_write()

These methods are called on BST::* object to check access to it.
BST::User instance as an argument required for each method.

Re-define methods in sub-classes if you need real access-check

Usage in controller:
my ($self, $c) = shift;
my $obj = BST::File->load( { file_id => $c->req->param('file_id') } );
$self->deny() unless $obj->can_read($c->user);

=cut
sub can_read {
    return 1;
}

sub can_write {
    return 1;
}

sub hide_suppressed {
    return 1;
}


=head2 returns relative url to the form of this object in db_editor

=cut

sub db_editor_relative_url {
    my $self = shift;

    my $table_name = $self->table;
    $table_name =~ s/[\s_-]//;

    my $id = $self->id;
    $id =~ s/([:\/_#?;@&=+\$,"<>%\\])/sprintf('_%02X', ord($1))/ge;

    return
        '/'
        . lc($table_name)
        . '/'
        . $id;
}

=head2 returns absolute url to the form of this object in db_editor

=cut

sub db_editor_url {
    return BST::config('db_editor_site') . shift->db_editor_relative_url;
}


=item get_new_pk()

get_new_pk() is called by BST->create method to create the primary key
for the new object automatically.

redefine sequence_name method for classes with auto-increment fields

=cut


sub get_new_pk {
    my $class = shift;
    my $sequence = $class->sequence_name();
    my $nextval = $class->get_nextval($sequence);
    return ($sequence eq sequence_name() ? $class->table . "_" : '') . $nextval;

}

sub get_nextval {
    my $class = shift;
    my $sequence = shift;
    my ($nextval) = BST::schema()->storage->dbh->selectrow_array("SELECT nextval('" . $sequence . "') AS nextval");
    return $nextval;
}

sub sequence_name {
    return 'main';
}

1;
