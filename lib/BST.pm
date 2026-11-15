package BST;

use strict;
use warnings;

use Data::Dumper;

use Exporter;
use base qw(Exporter Class::Singleton);
use vars qw(@EXPORT_OK);
use DBI;
@EXPORT_OK = qw(config error cache schema);

use Params::Validate qw(:all);

require BST::Schema;
require BST::Config;
require BST::Error;
require BST::Cache;
require BST::Logger;

sub cache { BST::Cache::cache() }

# this will be overriden in BSA:: environment (in
# BSA::Controller::Root):
sub current_user { return undef; }
sub current      { return undef; }

my $schema;

sub schema {
    return $schema
        if $schema;

    my $dbuser      = config('dbuser');
    my $dbpass      = config('dbpass');

    my $dbparams    = {
        PrintError      => 1,
        RaiseError      => 1,
        pg_enable_utf8  => 1,
    };

    if (config('schema_cache')) {
        require BST::Cursor;
        $dbparams->{cursor_class}   = 'BST::Cursor';
    }

    $schema = BST::Schema->connection(
        &dsn(),
        $dbuser, $dbpass, $dbparams,
    );

    if (config('schema_cache')) {
        my $backend = BST::config('schema_cache_backend') || 'Cache::File';
        (my $module = "$backend.pm") =~ s!::!/!gis;

        require $module;

        $schema->default_resultset_attributes({
            cache_object    => $backend->new(config('schema_cache_backend_settings')->{$backend}),
            cache_for       => config('schema_cache'),
        });
    }

    return $schema;
}

sub dsn {
    my $dbname      = config('dbname');
    my $dbhost      = config('dbhost');
    return $dbhost ? "DBI:Pg:dbname=$dbname;host=$dbhost" : "DBI:Pg:dbname=$dbname";
}

sub dbh {
    my $dbuser      = config('dbuser');
    my $dbpass      = config('dbpass');

    my $dbparams    = {
        PrintError      => 1,
        RaiseError      => 1,
        pg_enable_utf8  => 1,
    };

    return DBI->connect(&dsn(), $dbuser, $dbpass, $dbparams);
}

sub run_sql_file {
    my $file        = shift;
    my $psql = config('psql_command') || 'psql -f %%script%% %%dbuser%% %%dbname%% %%dbhost%%';
    my $dbuser_arg;

    if( config('dbuser') ) {
        $dbuser_arg = "-U " . config('dbuser');
    } else {
        $dbuser_arg = "";
    }

    $psql =~ s/%%dbname%%/config('dbname')/eg;
    $psql =~ s/%%dbuser%%/$dbuser_arg/eg;
    $psql =~ s/%%dbpass%%/config('dbpass')/eg;

    if (config('dbhost')) {
        $psql =~ s/%%dbhost%%/"-h " . config('dbhost')/eg;
    } else {
        $psql =~ s/%%dbhost%%//g;
    }

    $psql =~ s/%%script%%/$file/eg;

    my $retval = do {local $ENV{PGPASSWORD} = config('dbpass'); system "$psql";};

    return $retval;
}

=head1 search - class method

returns a arrayref of found objects
First argument is CONDITION. It's a hashref, containing class attributes definition or undef to search in all records
Second argument is search ATTRIBUTES, now we support (such as in SQL::Abstract):
    page|rows => int,
    distinct => 1|0,
    order_by => arrayref, define class attributes, forget about sql_attrs ;)

NOTE: asc and desc in order_by are case intensive.

=cut

sub search {
    my ($class, $cond, $attrs) = validate_pos(@_,
                 { type => SCALAR },
                 { type => HASHREF | UNDEF },
                 { type => HASHREF | UNDEF, optional => 1 },
    );

    # IK: to intercept the data loading, we may inherit from the ResultSet() class
    # see BST::Schema
    if ($ENV{DBIC_TRACE}) {
        print STDERR "search for $class: " , Data::Dumper->Dump( [$cond, $attrs], ['cond','attrs'] );
    }
    my $rs = &schema->resultset( $class )->search($cond, $attrs);

    return wantarray ? $rs->all : $rs;
}

sub create {
    my $class = shift;
    my $columns = shift; # optional

    my $rs = &schema->resultset($class);

    # create new object
    my $obj = $rs->new_result( shift || {} );
    my @pks = $obj->primary_columns;

    # if there is some PK column
    if (scalar @pks) {
        my $pk_name = $pks[0];

        # if there is no PK in args received
        # then get PK from sequence
        if ((! defined $columns) || (! exists $columns->{ $pk_name })) {
            $obj->set_column($pk_name => $obj->get_new_pk());
        }

    }

    # copy columns values
    if (defined $columns) {
        foreach my $key (keys %$columns) {
            $obj->set_column($key => $columns->{$key});
        }
    }

    return $obj;
}


=head1 load - class method

finds the unique record with specific attributes and populates the object with it (or dies)

As a parameter I can take a scalar value -- the primary key value. Or
a hash reference with key value definition. If you dont know or dont
want to know the name of primary key, you can use 'id' instead, I will
find the PK for you.

Variant ->load(id => 'value') is also supported.

=cut

sub load {
    my ($class, $pkcolumn, $pkvalue) = validate_pos(@_,
                 { type => SCALAR },
                 { type => HASHREF | SCALAR },
                 { type => SCALAR,  optional => 1 },
    );

    my $rs = &schema()->resultset( $class );

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

    return $rs->find($where);
}

=head1 error

errors holder. Define your error methods in BST::Error
use like:

    $self->error->user_is_blocked
    if ($self->block_access eq 'true');
    return
        if $self->error->status;

    ...
    later in caller:
    if $obj->error->status { do_error_handling }
    error->messages will contain all that stuff, that causes errors

=cut

sub error { BST::Error->instance() }

my $config;
sub config {
    my $param = shift;
    $config ||=BST::configuration();
    if(defined $param) {
        return $config->{$param};
    } else {
        return $config;
    }
}

1;
