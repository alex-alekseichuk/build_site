package BST::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->storage_type('BST::Storage');


__PACKAGE__->load_classes;


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-07-10 13:10:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AICwEPQDbTlozl1rfBc5MQ


# You can replace this text with custom content, and it will be preserved on regeneration
# load BST::* classes
__PACKAGE__->load_classes(

    {
        BST => [qw/
Account
Publication
Location
User
Message
MessageRecipient
Contact
ContactCompany
FolderItem
File
Folder
Setting
Product
ProductRelated
ProductStandard
ProductKeyword
Category
Company
Schemaversions
Package
PackageToc
PackageItem
Document
CompanyFeature
Grouping
CompanyGrouping
MsdsGroup
MsdsDocument
CategoryCounts
LeedCredit
LeedArea
ProductLeedCredit
LeedCreditAttribute
CategoryAttribute
Attribute
CreditCard
GatewayPayment
CustomerOrder
CustomerUser
DBCheckReport
        /],
    }
);

1;
