# fix scope of all folder items. 3 scopes should be separated absolutely.

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

use BST;
use BST::Message;
use BST::Package;

sub update_folder_items {
    my $fis = shift;
    my $scope = shift;

    while (my $fi = $fis->next) {
        $fi->scope($scope);
        $fi->save;

        if (ref $fi eq 'BST::Folder') {
            my $fis2 = BST::FolderItem->search({
                parent => $fi->file_id
            });
            update_folder_items($fis2, $scope) if ($fis2);
        }
    }

}

sub update_root_items {
    my $scope = shift;
    my $fis = BST::FolderItem->search({
        scope => $scope
        ,parent => undef
    });
    &update_folder_items ($fis, $scope);
}

update_root_items ("user");
update_root_items ("location");
update_root_items ("account");
