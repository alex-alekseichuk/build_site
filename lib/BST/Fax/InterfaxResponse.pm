package BST::Fax::InterfaxResponse;

use strict;

sub new {
    my $class = shift;
    my $contents = shift;

	my $self = bless({}, $class);
    ($self->{message_id}) = $contents =~ /Message-ID:\s+<(.*?)>/gim;

    $self->is_xml( $contents ) ?
    	$contents =~ s/.*<OutgoingFax>\s*(.*?)\s*<\/OutgoingFax>.*$/$1/gis :
    	$contents =~ s/.*Interfax Transmission Result\r?\n(=+)\s*(.*?)\s*=+.*$/$2/gis
   	;
 
    $self->text( $contents );

    return $self;
}

sub text {
    my $self = shift;
    $self->{text} = shift if scalar @_;

    return $self->{text};
}

sub is_xml {
    my $self = shift;
    my $text = shift || $self->text;

    return $self->{is_xml} if defined $self->{is_xml};
    return $self->{is_xml} = $text =~ m/<\/OutgoingFax>/gis ? 1 : 0;
}


sub message_id {
    my $self = shift;
    return $self->{message_id};
}

sub subject {
    my $self = shift;
    my ($subj) =
        $self->is_xml ? 
            $self->text =~ m/<Subject>(.*?)<\/Subject>/im :
            $self->text =~ m/Subject:\s*(.*?)\r?\n/is
    ;

    return $subj;
}

sub data {
    my $self = shift;
    return $self->{data} if (defined $self->{data});
    
    my $subj = $self->subject;
    $subj =~ s/::$//;

    return $self->{data} = { 
        map {; 
            my @t = split /::/; 
            push @t, undef if @t < 2;
            splice @t, 2;
            @t;
        } split /;/, $subj
    };
}

sub status {
    my $self = shift;
    my ($status) =
        $self->is_xml ? 
            $self->text =~ m/<Status>(\-?\d+)/im :
            $self->text =~ m/Transmission Results?:\s*(\-?\d+)/im
    ;
    
    return $status;
}

sub recipient_id {
    my $self = shift;
    return $self->data->{rid};
}

sub system_id {
    my $self = shift;
    return $self->data->{system_id};
}


1;
