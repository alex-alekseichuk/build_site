#!/usr/bin/perl

use strict;
use FindBin qw($Bin);

my $home = "$Bin/..";
my $conffile = "$home/lib/BST/Config.pm";
my $pidfile = "$home/bsa_server.pid";

# intro
#print "I'm $0 (in $Bin) at $$\n";

# get path to perl interpreter executable
# http://www.perlmonks.org/?node_id=495992
use Config;
my $perl = $Config{perlpath};
$perl .= $Config{_exe}
  if $^O ne 'VMS' and $perl !~ /$Config{_exe}$/i;
# a simplier alternative is:
#$perl = $^X; 
# but it not as fool-proof


sub is_running {
    if( -f $pidfile ) {
	my $pid = get_running_pid();
	if ($pid) {
	    my $line = `ps axu | grep $pid\[[:space:]] | grep perl`;
	    if ( $line =~ m/perl/ ) {
		# it actually exists
		#print "ps line: $line";
		return 1;
	    }
	}
    }
    return undef;
}

sub get_running_pid {
    return undef if !-f $pidfile;
    my $pid = `cat $pidfile`;
    chomp $pid;
    return $pid;
}

sub get_running_conf {
    my $port   = `cat $home/bsa_server.port`;
    my $dbname = `cat $home/bsa_server.dbname`;
    chomp $port;
    chomp $dbname;
    return { port => $port, dbname => $dbname };
}

sub save_running_conf {
    my $port = shift;
    my $dbname = shift;
    system( "echo $port > $home/bsa_server.port" );
    system( "echo $dbname > $home/bsa_server.dbname" );
}

sub load_current_saved_conf {
    my $current_conf = `cat $conffile`;
    require $conffile;
    return( $current_conf, BST::configuration() );
}

sub save_dbname_conf {
    my $dbname = shift;

    my ($current_conf, $conf) = load_current_saved_conf();
    my $current_dbname = $conf ->{dbname};   
    #print "current dbname: $current_dbname\n";

    if (not $dbname) { return undef; }

    if ($current_dbname eq $dbname) { return 1; }

    # split into lines
    my @lines = split( /\n/, $current_conf );
    foreach (@lines) {
	if( $_ =~ /^\s*#/ ) { next; }
	if( $_ =~ /\bdbname\b/ ) {
	    s/['"]$current_dbname['"]/'$dbname'/;	    
	    last;
	}
    }
    my $newconf = join( "\n", @lines );

    # clear the existing conf
    eval {
	no strict;
	undef *BST::configuration;
    };

    # test the new conf
    eval "# file: testconf
$newconf
";
    if( $@ ) {
	die "failed to create a new configuration: $@";
    }
    my $newconf_db = BST::configuration()->{dbname};
    if ( $newconf_db ne $dbname ) {
	die "failed to create a new configuration: incorrect dbname";
    }
    
    # make a backup
    system( "cp $conffile $conffile.bak" );

    # save the change
    if( open CONF, ">$conffile" ) {
	print CONF $newconf;
	close CONF;
    }
    
    return 1;
}

sub start (;$$) {
    my $nowconf  = get_running_conf() || {};
    my $port   = shift || $nowconf->{port} || $ENV{PORT} || $ENV{BSA_PORT} || $ENV{CATALYST_PORT} || 3000;
    my $dbname = shift || $nowconf->{dbname};

    #print "ARGV: @ARGV\n";
    # get port and dbname from the command-line parameters
    foreach ( @ARGV ) {
	if( /^\d+$/ ) { $port   = $_; }
	if( /[a-z]/i and /^\w+$/ ) { $dbname = $_; }
    }
    
    if ( is_running() ) {
	print "already running:\n";
	status();
	return undef;
    }
   
    unlink "$pidfile" if -f $pidfile;

    # current or the most recently used dbname?
    my $current_dbname;
    {
	my ($current_conf, $conf) = load_current_saved_conf();
	$current_dbname = $conf ->{dbname};
    }

    if (not $dbname) {
	#print "current dbname: $current_dbname\n";
    } else {
	save_dbname_conf( $dbname );
	#print "set dbname to: $dbname\n";
    }

    # fork to start a daemon in the child
    if( fork ) {
	# parent process

	sleep 1;
	# wait till bsa_server.pid appears or until some time runs out
	my $ok;
	for( 1..10 ) {
	    sleep 1;
	    if( -f $pidfile ) { $ok = 1; last; }
	    print ". ";
	}

	if ($ok) {
	    my $db = $dbname || $current_dbname;
	    # print pid?
	    print "server started on port $port, db $db\n";
	    save_running_conf( $port, $db );

	    sleep 3;
	    # check for the 'powered by Catalyst' message in the log?
	    if (is_running()) {
	    } else { 
		print "failed to start\n";
		print "tail bsa_server.log:\n";
		system( "tail bsa_server.log" );
	    }

	} else {
	    print "failed to start server. try checking out the logs\n"; 
	}

    } else {
	# child

	use Proc::Daemon;
	Proc::Daemon::Init;

	chdir $home;

	open STDOUT, ">>$home/bsa_server.log";
	open STDERR, ">&STDOUT";
	$| = 1; 

	exec $perl, "$home/script/bsa_server.pl", qw( -port ), $port;
    }

}

sub stop {
    if( is_running() ) {
	my $pid = get_running_pid();
	print "killing $pid\n";
	system( "kill $pid" ) if $pid;
	sleep 2;
    } else {
	print "no pid file bsa_server.pid (server is not running?)\n";
    }
}

sub status {
    if( is_running() ) {
	my $conf = get_running_conf();
	my $port = $conf->{port};
	my $db   = $conf->{dbname}; 
	print "server process ", get_running_pid(), " running on port $port, db $db\n";
    } else {
	print "no known server is running\n";
    }
}

sub restart {
    my $port;
    my $dbname;

    my $c = get_running_conf();
    if(is_running()) {
	stop();
	if ( $c ) {
	    $port = $c->{port};
	    $dbname = $c->{dbname};
	}
    }
    
    start( $c->{port}, $c->{dbname} );
}


#save_dbname_conf( "bsdata3" );
#start( 3000, 'bsdata_live' );

my @commands = qw( stop start status restart );

my $command = shift @ARGV;
if( $command ) {
    foreach ( @commands ) {
	if ($_ eq $command) {
	    # run it!
	    no strict 'refs';
	    & $command ();
	}
    }
}


