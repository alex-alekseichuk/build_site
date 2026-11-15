# import all message attachments into sent_message package_id field

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

use BST;
use BST::Message;
use BST::Package;

my $msgs = BST::Message->search({
    attached_file_ids => { '!=' => '' },
    package_id => { '=' => undef },
                                });

while (my $msg = $msgs->next) {
    my $att = attachments($msg);
    next if not $att;
    
    # filling in Package
    my $pkg = BST::Package->create({
        owner         => $msg->owner->id,
        file_title    => $msg->subject || '',
        scope         => 'hidden',
        creator_user  => $msg->sender->id,
                                   });
    $pkg->save;
    $pkg->add_item($att);

    # storing package_id in message table
    $msg->package($pkg);
    $msg->save;
}

# this is old method from BST::Message. It reads attach list from attach's old field
sub attachments {
    my $self = shift;
    my @ids = split(';', $self->attached_file_ids);

    return unless scalar @ids;

    my $result = {};
    foreach (@ids) {
        my ($id, $s) = split '=';
        my $obj = undef;
        if ($s eq 'derived_file') {
            # the following call replaces a LIKE search
            # derived_path => { -like => "$id.%" }
            # because with LIKE it does not use the index (for some reason)
            # and that makes the script too slow
            $obj = BST::Document->search({ 
                derived_path => { '>=' => "$id.",   
                                  '<=' => "$id.z" } 
            })->next;
        } elsif ($s eq 'account_private_file') {
            $obj = BST::File->load({ file_id => $id });
        }
        if ($obj) {
            $result->{$obj->id} = $obj;
        }
    }

    return [ values %$result ];
}
