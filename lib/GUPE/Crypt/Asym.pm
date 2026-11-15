package GUPE::Crypt::Asym;
use strict;

=head1 DESCRIPTION

OO wrapper around Crypt::RSA

=cut

# don't do a "use" til actually needed by a call to new
#use Crypt::RSA;
use GUPE::FileUtils qw(slurp);
use GUPE::Debug::Log;

# options:
#  public_file - mandatory if going to encrypt
#  private_file - mandatory if going to decrypt
#  armour - will return an "armoured" value (only safe chars) using Convert::ASCII::Armour
#  password - passphrase to use private key (mandatory if saved that way)
#  password_cipher - cipher used for symmetric password protecting private key (default Blowfish)
#  identity - optional string to associate with key, usually name and email address
sub new {
    my ($class, %opts) = @_;
    require Crypt::RSA;
    # uses OAEP padding by default
    my $rsa = new Crypt::RSA();
    bless {rsa => $rsa, %opts}, $class;
}

# can be called by any user
sub encrypt {
    my ($self, $plaintext) = @_;
    # Key can be a string or a Crypt::RSA::Key::Public object
    my %params = (Message => $plaintext, Key => $self->_public_key(), Armour => $self->{armour} );
    my $rsa = $self->{rsa};
    my $ciphertext = $rsa->encrypt( %params );
    die "encrypt failed: ", $rsa->errstr(), "\nwith params: ", Dumper(\%params) unless defined($ciphertext);
    return $ciphertext;
}

# can be called only by special user
sub decrypt {
    my ($self, $ciphertext) = @_;
    my %params = (Cyphertext => $ciphertext, Key => $self->_private_key(), Armour => $self->{armour} );
    my $rsa = $self->{rsa};
    my $plain = $rsa->decrypt( %params );
    die "decrypt failed: ", $rsa->errstr(), "\nwith params: ", Dumper(\%params) unless defined($plain);
    return $plain;
}

# generate and write the public and private files 
# should only be called by root (or other special user)
sub generate {
    my ($self) = @_;
    my $pubfile = $self->{public_file} || die "no public_file";
    my $prifile = $self->{private_file} || die "no private_file";
    my $rsa = $self->{rsa};
    # returns Crypt::RSA::Key::Public and Private objects
    my %params = (
	  # Size is mandatory
	  Size => 2048, 
	  # show progress on STDOUT
	  Verbosity => 1, 
	  # protect with symmetric passphrase. might be undef.
	  Password => $self->{password},
	  # cipher for password
	  Cipher => $self->{password_cipher},
	  # identity
	  Identity => $self->{identity},
		  );

    info("generating key with params: ", Dumper(\%params));
    my ($public, $private) = $rsa->keygen(%params);

    info("writing public $public to file $pubfile");
    $public->write(Filename => $pubfile);
    chmod(0644, $pubfile) || warning("Could not chmod 644 public key file $pubfile: $!");

    info("writing private $private to file $prifile");
    # will store protected by password if specified at keygen time
    $private->write(Filename => $prifile);
    chmod(0600, $prifile) || warning("Could not chmod 600 private key file $prifile: $!");
}

# read the public key from disk
# any user can do this
sub _public_key {
    my ($self) = @_;
    die "no public_file" unless $self->{public_file};
    require Crypt::RSA::Key::Public;
    return ($self->{public_key} ||= Crypt::RSA::Key::Public->new(Filename => $self->{public_file}));
}

# read the private key from disk
# will fail if not a user with read access
sub _private_key {
    my ($self) = @_;
    die "no private_file" unless $self->{private_file};
    require Crypt::RSA::Key::Private;
    my $key = Crypt::RSA::Key::Private->new
	    (Filename => $self->{private_file},
	     Password => $self->{password},
	     Cipher => $self->{password_cipher},
	     Identity => $self->{identity},
	     );
    die "Could not decrypt private key: ", $key->{errstr} if $key->{errstr};
    return ($self->{private_key} ||= $key);
}


1;

