package BST::PDF;

use strict;
use warnings;
use Data::Dumper;


=head1 DESCRIPTION
    contains method to generate PDF
=cut


=head generate

Generates xhtml by tt template. Then generates PDF by that xhtml.
    
=cut
sub logger { BST::Logger->instance(@_)              }

sub generate {
    my $self      = shift; # package name
    my $path_tt   = shift;
    my $path_html = shift;
    my $path_pdf  = shift;
    my $stash     = shift;
    
    if (defined $path_tt) {
        # generate xhtml
        my $template = Template->new( {ABSOLUTE=>1} );
        $template->process(
            $path_tt,
            $stash,
            $path_html, binmode => ':utf8')
            or die "template $path_tt failed for $path_html: " . $template->error;
    }

    # convert xhtml to pdf
    my @args = (
        BST::config('pdf_generator')
        ,$path_html
        ,$path_pdf
        ,BST::config('home')
    );

    # for debugging
    #warn ( join( ' ', @args ) );

    #my $sysret = system( join( ' ', @args ) );
    #if ($sysret != 0) {
        #warn "it seems we failed to start the pdf generation script. result: $sysret";
    #}
    
    my $command = join ' ', @args;
    my $output = `$command 2>&1`;
    if ($? == -1) {
        logger->log({ name => 'bst', email => 1, level => 'error', message => 'xhtml to pdf convert failed: ' . $! });
    }
    elsif ($?) {
        logger->log({ name => 'bst', email => 1, level => 'error', message => 'xhtml to pdf convert failed: ' . $output });
    }

    if ( -f $path_pdf and -s _ ) { return 1; }
    else { return undef; }

}

1;
