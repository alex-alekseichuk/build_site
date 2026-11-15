package BSA::Controller::Annotation;

use strict;
use warnings;
use base 'BSA::Controller';
use Data::Dumper;

use BST::FileMarkup;
use BST::File;

=head1 NAME

BSA::Controller::Annotation - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

Original def:
def annotate_file(request, file_id, package_id=None):
    file = get_object_or_404(File, pk=file_id)
    pages = []
    for x in xrange(1, file.num_pages+1):
        try:
            a = FileMarkup.objects.get(file=file_id, package=package_id, page=x).is_active
        except FileMarkup.DoesNotExist:
            a = True
        pages.append((x, a))

    return render_to_response('file_annotate.html',
        {'file': file, 'pages': pages})

=cut

sub edit :Local :Args(1) {
	my($self, $c) = @_;
    my $package_item_id = shift @{ $c->req->args };
	my $package_item = $c->get_object_or_404('PackageItem', id => $package_item_id);

	my $item_type    = $package_item->item_type;
	my $page_count   = $package_item->page_count;

	my $criteria = { package_id => $package_item->package_id };

	if ($item_type eq 'document') {
		$criteria->{document_id} = $package_item->document_id;
	}
	else { # file
		$criteria->{file_id} = $package_item->file_id;
	}
	my @pages;

	for my $page (1..$page_count) {
		$criteria->{page} = $page;
		my($markup) = BST::FileMarkup->search($criteria);
		push @pages, [ $page, $markup ? $markup->is_active : 1 ];
	}

	$c->stash->{package_item_id} = $package_item_id;
	$c->stash->{page_count}      = $page_count;
	$c->stash->{pages}           = \@pages;
	$c->stash->{template}        = 'annotation/edit.tt';
}

sub save :Local :Args(1) {
	my($self, $c) = @_;
}

sub download :Local :Args(1) {
	my($self, $c) = @_;
}

=head1 AUTHOR

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
