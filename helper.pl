die; # in developement
use strict;

use Template;
use FindBin qw~$Bin~;
use Data::Dumper;

my %cache;

#print Dumper(@ARGV);
my $file = shift @ARGV;
$file =~ s/\:\:/\//;
my $fullname = $Bin . '/lib/' . $file . '.pm';

print Dumper($fullname);
#render_file( 'appclass', $fullname );

exit;
=head1 DESCRIPTION

Bootstrap a Catalyst application. Autogenerates scripts.

=head2 METHODS

=head3 get_file

Slurp file from DATA.

=cut

sub get_file {
    my ( $self, $class, $file ) = @_;
    unless ( $cache{$class} ) {
        local $/;
        $cache{$class} = eval "package $class; <DATA>";
    }
    my $data = $cache{$class};
    my @files = split /^__(.+)__\r?\n/m, $data;
    shift @files;
    while (@files) {
        my ( $name, $content ) = splice @files, 0, 2;
        return $content if $name eq $file;
    }
    return 0;
}

=head3 mk_file

writes content to a file.

=cut

sub mk_file {
    my ( $self, $file, $content ) = @_;
    if ( -e $file ) {
        print qq/ exists "$file"\n/;
        return 0
    }
    if ( my $f = IO::File->new("> $file") ) {
        binmode $f;
        print $f $content;
        print qq/created "$file"\n/;
        return 1;
    }
}
=head3 render_file

Render and create a file from a template in DATA using 
Template Toolkit.

=cut

sub render_file {
    my ( $self, $file, $path, $vars ) = @_;
    $vars ||= {};
    my $t = Template->new;
    my $template = $self->get_file( ( caller(0) )[0], $file );
    return 0 unless $template;
    my $output;
    $t->process( \$template, { %{$self}, %$vars }, \$output )
      || Catalyst::Exception->throw(
        message => qq/Couldn't process "$file", / . $t->error() );
    $self->mk_file( $path, $output );
}

sub _mk_appclass {
    my $self = shift;
    my $mod  = $self->{mod};
    $self->render_file( 'appclass', "$mod.pm" );
}

1;

__DATA__

__appclass__
package [% name %];

use strict;
use warnings;

=head1 NAME

    [% name %] - Package description.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    Quick summary of what the module does.
    Perhaps a little code snippet.

=head1 EXPORT
    None
    
=head1 FUNCTIONS

=head2 f1

=cut

sub f1 {
}

=head1 AUTHOR

[% author %]

=cut

1;

__testcase__
use strict;
use warnings;

use Test::Unit;
1;
