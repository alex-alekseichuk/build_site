package BSA::Controller::Admin::DBCheck;

use strict;
use warnings;
use base 'BSA::Controller';
use Data::Dumper;

use BST qw(schema);
use BST::Company;

use DBCheck;

=head1 NAME

BSA::Controller::Admin::DBCheck - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


our %REPORTS = (
    All => {
        reports => {
            bad_checkflags => {
                title => "Has unknown or deprecated value for check_flags",
            }
            ,checkflags_issue => {
                title => "Issue in check_flags",
            }
        }
    }
    ,Manufacturer => {
        reports => {
            company_usa_region => {
                title => "If the country == 'US', the region should be 2-letter uppercase code or the Capitalized state name",
            }
            ,company_no_nickname => {
                title => "No nickname",
            }
            ,company_no_logo_file => {
                title => "No logo file in DB or on disk",
            }
            ,company_logo_file_ext => {
                title => "Logo file has not correct ext. (jpeg, jpg, gif, png)",
            }
        }
    }
    ,Product => {
        reports => {
            product_ctime_mfg_last_qa_date => {
                title => "Its ctime > mfg's last_qa_complete_date",
            }
            ,product_systemness => {
                title => "Has systemness != 'not' and not empty but system_parts is not set",
            }
            ,no_msds_document => {
                title => "No msds document",
            }
            ,no_product_data_document => {
                title => "No product_data document",
            }
            ,multiple_docs_with_same_title => {
                title => "Has multiple documents with the same publisher_document_title",
            }
            ,many_docs => {
                title => "Has > 9 documents and does not have manydocs checkflag",
            }
            ,product_obsolete_category => {
                title => "Is in a category that has the flag 'obsolete_category'",
            }
        }
    }
    ,Document => {
        reports => {
            document_ctime_mfg_last_qa_date => {
                title => "Its ctime > mfg's last_qa_complete_date",
            }
            ,replaced_by_document_from_other_publisher => {
                title => "Replaced_by_document_id points to document from another publisher",
            }
            ,no_external_file => {
                title => "External file does not exist",
            }
            ,path_not_set => {
                title => "Derived_path or image_path is not set",
            }
            ,publisher_not_equal_about_company => {
                title => "For company-level documents, warn if publisher does not match about_company",
            }
            ,no_products_in_category => {
                title => "For category-level documents, warn if there are no products in the category or below",
            }
        }
    }
    ,Publisher => {
        reports => {
            publisher_no_publications => {
                title => "No publications",
            }
            ,publisher_no_docs => {
                title => "No documents",
            }
            ,publisher_no_match_publication_id => {
                title => "Publication_id does not match publisher_id",
            }
            ,publisher_no_products => {
                title => "No products",
            }
        }
    }
);



sub index :Path Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{user} = $c->user;
    $c->stash->{reports} = \%REPORTS;

    my $sql = "SELECT rule_id, count(object_id) as n FROM dbcheck_reports GROUP BY rule_id";
    $c->stash->{report_counts} = BST::dbh()->selectall_hashref($sql, 'rule_id');
}



sub set_title {
    my ( $self, $c, $type, $report_name ) = @_;
    $c->stash->{report_name} = $report_name;
    $c->stash->{report_title} = $type . ': ' . $REPORTS{$type}->{reports}->{$report_name}->{title};
    $c->stash->{user} = $c->user;
    $c->stash->{base_url} = BST::config('db_editor_site');
}





# Reports views


# All

sub bad_checkflags :Local {
    my ( $self, $c ) = @_;

    $c->stash->{items} = DBCheck::bad_checkflags;
    #$c->stash->{items} = DBCheck::load_report('bad_checkflags');

    $self->set_title($c, 'All', 'bad_checkflags');
}

sub checkflags_issue :Local {
    my ( $self, $c ) = @_;

    $c->stash->{items} = DBCheck::checkflags_issue;
    #$c->stash->{items} = DBCheck::load_report('checkflags_issue');

    $self->set_title($c, 'All', 'checkflags_issue');
}




# Company

sub company_no_nickname :Local {
    my ( $self, $c ) = @_;

    $c->stash->{items} = DBCheck::company_no_nickname;
    #$c->stash->{items} = DBCheck::load_report('company_no_nickname');

    $self->set_title($c, 'Manufacturer', 'company_no_nickname');
}
sub company_no_logo_file :Local {
    my ( $self, $c ) = @_;

    #$c->stash->{items} = DBCheck::company_no_logo_file;
    $c->stash->{items} = DBCheck::load_report('company_no_logo_file');

    $self->set_title($c, 'Manufacturer', 'company_no_logo_file');
}
sub company_logo_file_ext :Local {
    my ( $self, $c ) = @_;

    $c->stash->{items} = DBCheck::company_logo_file_ext;
    #$c->stash->{items} = DBCheck::load_report('company_logo_file_ext');

    $self->set_title($c, 'Manufacturer', 'company_logo_file_ext');
}
sub company_usa_region :Local {
    my ( $self, $c ) = @_;

    $c->stash->{items} = DBCheck::company_usa_region;
    #$c->stash->{items} = DBCheck::load_report('company_usa_region');

    $self->set_title($c, 'Manufacturer', 'company_usa_region');
}




# Product

sub product_ctime_mfg_last_qa_date :Local {
    my ( $self, $c ) = @_;

    $c->stash->{items} = DBCheck::product_ctime_mfg_last_qa_date;
    #$c->stash->{items} = DBCheck::load_report('product_ctime_mfg_last_qa_date');

    $self->set_title($c, 'Product', 'product_ctime_mfg_last_qa_date');
}

sub product_systemness :Local {
    my ( $self, $c ) = @_;

    $c->stash->{items} = DBCheck::product_systemness;
    #$c->stash->{items} = DBCheck::load_report('product_systemness');

    $self->set_title($c, 'Product', 'product_systemness');
}


sub no_msds_document :Local {
    my ( $self, $c ) = @_;

    #$c->stash->{items} = DBCheck::no_msds_document;
    $c->stash->{items} = DBCheck::load_report('no_msds_document');

    $self->set_title($c, 'Product', 'no_msds_document');
}

sub no_product_data_document :Local {
    my ( $self, $c ) = @_;

    #$c->stash->{items} = DBCheck::no_product_data_document;
    $c->stash->{items} = DBCheck::load_report('no_product_data_document');

    $self->set_title($c, 'Product', 'no_product_data_document');
}

sub multiple_docs_with_same_title :Local {
    my ( $self, $c ) = @_;

    #$c->stash->{items} = DBCheck::multiple_docs_with_same_title;
    $c->stash->{items} = DBCheck::load_report('multiple_docs_with_same_title');

    $self->set_title($c, 'Product', 'multiple_docs_with_same_title');
}

sub many_docs :Local {
    my ( $self, $c ) = @_;

    #$c->stash->{items} = DBCheck::many_docs;
    $c->stash->{items} = DBCheck::load_report('many_docs');

    $self->set_title($c, 'Product', 'many_docs');
}

sub product_obsolete_category :Local {
    my ( $self, $c ) = @_;

    $c->stash->{items} = DBCheck::product_obsolete_category;
    #$c->stash->{items} = DBCheck::load_report('product_obsolete_category');

    $self->set_title($c, 'Product', 'product_obsolete_category');
}


# Document

sub document_ctime_mfg_last_qa_date :Local {
    my ( $self, $c ) = @_;

    #$c->stash->{items} = DBCheck::document_ctime_mfg_last_qa_date;
    $c->stash->{items} = DBCheck::load_report('document_ctime_mfg_last_qa_date');

    $self->set_title($c, 'Document', 'document_ctime_mfg_last_qa_date');
}

sub replaced_by_document_from_other_publisher :Local {
    my ( $self, $c ) = @_;

    #$c->stash->{items} = DBCheck::replaced_by_document_from_other_publisher;
    $c->stash->{items} = DBCheck::load_report('replaced_by_document_from_other_publisher');

    $self->set_title($c, 'Document', 'document_ctime_mfg_last_qa_date');
}

sub no_external_file :Local {
    my ( $self, $c ) = @_;

    #$c->stash->{items} = DBCheck::no_external_file;
    $c->stash->{items} = DBCheck::load_report('no_external_file');

    $self->set_title($c, 'Document', 'no_external_file');
}

sub path_not_set :Local {
    my ( $self, $c ) = @_;

    #$c->stash->{items} = DBCheck::path_not_set;
    $c->stash->{items} = DBCheck::load_report('path_not_set');

    $self->set_title($c, 'Document', 'path_not_set');
}

sub publisher_not_equal_about_company :Local {
    my ( $self, $c ) = @_;

    #$c->stash->{items} = DBCheck::publisher_not_equal_about_company;
    $c->stash->{items} = DBCheck::load_report('publisher_not_equal_about_company');

    $self->set_title($c, 'Document', 'publisher_not_equal_about_company');
}

sub no_products_in_category :Local {
    my ( $self, $c ) = @_;

    #$c->stash->{items} = DBCheck::no_products_in_category;
    $c->stash->{items} = DBCheck::load_report('no_products_in_category');

    $self->set_title($c, 'Document', 'no_products_in_category');
}




# Publisher

sub publisher_no_publications :Local {
    my ( $self, $c ) = @_;

    $c->stash->{items} = DBCheck::publisher_no_publications;
    #$c->stash->{items} = DBCheck::load_report('publisher_no_publications');

    $self->set_title($c, 'Publisher', 'publisher_no_publications');
}

sub publisher_no_docs :Local {
    my ( $self, $c ) = @_;

    $c->stash->{items} = DBCheck::publisher_no_docs;
    #$c->stash->{items} = DBCheck::load_report('publisher_no_docs');

    $self->set_title($c, 'Publisher', 'publisher_no_docs');
}


sub publisher_no_match_publication_id :Local {
    my ( $self, $c ) = @_;

    $c->stash->{items} = DBCheck::publisher_no_match_publication_id;
    #$c->stash->{items} = DBCheck::load_report('publisher_no_match_publication_id');

    $self->set_title($c, 'Publisher', 'publisher_no_match_publication_id');
}

sub publisher_no_products :Local {
    my ( $self, $c ) = @_;

    $c->stash->{items} = DBCheck::publisher_no_products;
    #$c->stash->{items} = DBCheck::load_report('publisher_no_products');

    $self->set_title($c, 'Publisher', 'publisher_no_products');
}



# Summary report

sub summary :Local {
    my ( $self, $c ) = @_;

    my $timestamp = $c->req->param('timestamp');
    my $row = DBCheck::load_summary_report($timestamp);

    $c->stash->{timestamps} = [ map {substr($_->auto_ctime, 0, 10)}
        &schema->resultset("BST::DBCheckReport")->search(
        {
            'rule_id' => 'summary'
        }, {
            order_by => 'auto_ctime DESC'
        })
    ];

    if ($row) {
        $c->stash->{info_fields} = $row->info_fields;

        my $now = substr($row->auto_ctime, 0, 10);
        $c->stash->{now} = $now;

        my $doc_type_live = $row->info_fields->{document_doctype_live};
        $c->stash->{doc_type_live} = [
            map  { [$_, $doc_type_live->{$_}] }
            sort { $a cmp $b }
            keys %$doc_type_live
        ];
        #$row->info_fields->{document_doctype_live}
    }

    $c->stash->{report_name} = 'summary';
    $c->stash->{report_title} = 'Summary';
    $c->stash->{user} = $c->user;
    $c->stash->{base_url} = BST::config('db_editor_site');
}




=head1 AUTHOR

Alex <kikudjiro@gmail.com>

=cut

1;
