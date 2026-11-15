package DBCheck;

use strict;
use warnings;

use Exporter;
use base qw(Exporter Class::Singleton);
use vars qw(@EXPORT_OK);
use DBI;
@EXPORT_OK = qw(
    save_report
    load_report

    bad_checkflags
    checkflags_issue

    company_usa_region
    company_no_nickname
    company_no_logo_file
    company_logo_file_ext

    product_ctime_mfg_last_qa_date
    product_systemness
    no_msds_document
    no_product_data_document
    multiple_docs_with_same_title
    many_docs
    product_obsolete_category

    document_ctime_mfg_last_qa_date
    replaced_by_document_from_other_publisher
    no_external_file
    path_not_set
    publisher_not_equal_about_company
    no_products_in_category

    publisher_no_publications
    publisher_no_docs
    publisher_no_match_publication_id
    publisher_no_products
);


use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Pad = '';

use BST qw(schema);

# do not suppress (admin mode)
undef &BST::Core::hide_suppressed;
*BST::Core::hide_suppressed = sub { 
    return 0;
};






sub save_report {
    my $rule_id = shift;
    my $rows = shift;

    for my $row (@$rows) {
        my $new_record = &schema->resultset('BST::DBCheckReport')->new({
            rule_id => $rule_id
            , bsa_class_name => $row->{bsa_class_name}
            , object_id => $row->{object_id}
            , info_fields => $row->{info_fields}
            , bad_fields => $row->{bad_fields}
        });
        $new_record->insert;
    }
}

sub load_report {
    my $rule_id = shift;

    return [
        &schema->resultset("BST::DBCheckReport")->search(
            { 
                'rule_id' => $rule_id
            }
        )
    ];
}





# Reports functions



# All

our @CHECK_FLAGS = (
    "bad_html_image_file",
    "bad_pdf_image_file",
    "disc_doc",
    "disc_prod",
    "disc_waiting",
    "html_ok",
    "issue",
    "jobsite",
    "manydocs",
    "msds_not_needed",
    "msds_waiting",
    "multiple_product_ok",
    "no_title",
    "noelectronic",
    "nomsds",
    "nopd",
    "notpublic",
    "pdfknownbad",
    "pdfok",
    "suppress",
);
our $CHECK_FLAGS = "bad_html_image_file|bad_pdf_image_file|disc_doc|disc_prod|disc_waiting|html_ok|issue|jobsite|manydocs|msds_not_needed|msds_waiting|multiple_product_ok|no_title|noelectronic|nomsds|nopd|notpublic|pdfknownbad|pdfok|suppress";

sub _bad_checkflags {
    my $class_name = shift;

    my $source = $class_name;
    if ( $class_name =~ /::([^:]+)$/ ) { $source = $1; }
    my $rs = BST::schema()->resultset( $source );

    my @rows = map {
			my $row = $_;

            my $title = '';
            if ($class_name eq 'Document') {
                $title = $row->title;
            } elsif ($class_name eq 'Product') {
                $title = $row->product_name;
            } elsif ($class_name eq 'Company') {
                $title = $row->name;
            } elsif ($class_name eq 'Category') {
                $title = $row->full_title;
            }

			my $bad_check_flags = [];
            foreach my $check_flag (split(';', $row->check_flags)) {
                if (not grep $_ eq $check_flag, @CHECK_FLAGS) {
                    push @{$bad_check_flags}, $check_flag;
                }
            }
			{
                object_id => $row->id
                ,bsa_class_name => $class_name
                ,info_fields => {
                    title => $title
                    ,url => $row->db_editor_relative_url
        			,check_flags => $row->check_flags
                }
                ,bad_fields => {
					bad_check_flags => join(';', @{$bad_check_flags})
				}
	        }
    } $rs->search(undef, {
        where => \"me.check_flags IS NOT NULL AND me.check_flags <> '' AND ';' || me.check_flags !~ e'^(; ?($CHECK_FLAGS))*\$'"
    });

	return @rows;
}

sub bad_checkflags {
	my @items = ();
	push @items, _bad_checkflags('Document');
	push @items, _bad_checkflags('Product');
	push @items, _bad_checkflags('Company');
	push @items, _bad_checkflags('Category');

    return \@items;
}


sub _checkflags_issue {
    my $class_name = shift;

    my $source = $class_name;
    if ( $class_name =~ /::([^:]+)$/ ) { $source = $1; }
    my $rs = BST::schema()->resultset( $source );

    my @rows = map {
		my $row = $_;
        my $title = '';
        if ($class_name eq 'Document') {
            $title = $row->title;
        } elsif ($class_name eq 'Product') {
            $title = $row->product_name;
        } elsif ($class_name eq 'Company') {
            $title = $row->name;
        } elsif ($class_name eq 'Category') {
            $title = $row->full_title;
        }
		{
            object_id => $row->id
            ,bsa_class_name => $class_name
            ,info_fields => {
                title => $title
                ,url => $row->db_editor_relative_url
    			,check_flags => $row->check_flags
            }
            ,bad_fields => {
				buildsite_private_notes => $row->buildsite_private_notes
			}
        }
    } $rs->search(undef, {
        where => \"';' || me.check_flags || ';' ~ e'; ?issue;'"
    });

	return @rows;
}

sub checkflags_issue {
	my @items = ();
	push @items, _checkflags_issue('Document');
	push @items, _checkflags_issue('Product');
	push @items, _checkflags_issue('Company');
	push @items, _checkflags_issue('Category');

    return \@items;
}





# Company

sub company_no_nickname {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Company'
        ,info_fields => {
            title => $_->name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
        }
    }, BST::Company->search(
    { 
        'me.company_nickname' => ['', undef]
    }) ];
}

sub company_no_logo_file {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Company'
        ,info_fields => {
            title => $_->name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
        	company_logo_file => $_->company_logo_file
        }
    }, grep {
        my $no_logo_file = 1;
        if ($_->company_logo_file) {
            my $path = BST::config("publishers_path") . "/" . $_->company_id . '/logo_files/' . $_->company_logo_file;
            if (-f $path and -s _) {
                $no_logo_file = 0;
            }
        }
        $no_logo_file;
    } BST::Company->search() ];
}

sub company_logo_file_ext {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Company'
        ,info_fields => {
            title => $_->name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
        }
    }, BST::Company->search(
    {
        'me.company_logo_file' => { '!~*' => '(\.jpg|\.jpeg|\.gif|\.png)$'}
    }, {
        where => \"me.company_logo_file <> ''"
    }) ];
}


sub company_usa_region {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Company'
        ,info_fields => {
            title => $_->name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
        	addr_country => $_->addr_country
        	,addr_region => $_->addr_region
        }
    }, BST::Company->search(
    { 
        -and => [
            { 'me.addr_country' => { 'in' => ['US', 'us'] } }
            , { 'me.addr_region' => { 'not in' => [
                 'AL', 'Alabama'
                ,'AK', 'Alaska'
                ,'AZ', 'Arizona'
                ,'AR', 'Arkansas'
                ,'CA', 'California'
                ,'CO', 'Colorado'
                ,'CT', 'Connecticut'
                ,'DE', 'Delaware'
                ,'DC', 'District of Columbia'
                ,'FL', 'Florida'
                ,'GA', 'Georgia'
                ,'HI', 'Hawaii'
                ,'ID', 'Idaho'
                ,'IL', 'Illinois'
                ,'IN', 'Indiana'
                ,'IA', 'Iowa'
                ,'KS', 'Kansas'
                ,'KY', 'Kentucky'
                ,'LA', 'Louisiana'
                ,'ME', 'Maine'
                ,'MD', 'Maryland'
                ,'MA', 'Massachusetts'
                ,'MI', 'Michigan'
                ,'MN', 'Minnesota'
                ,'MS', 'Mississippi'
                ,'MO', 'Missouri'
                ,'MT', 'Montana'
                ,'NE', 'Nebraska'
                ,'NV', 'Nevada'
                ,'NH', 'New Hampshire'
                ,'NJ', 'New Jersey'
                ,'NM', 'New Mexico'
                ,'NY', 'New York'
                ,'NC', 'North Carolina'
                ,'ND', 'North Dakota'
                ,'OH', 'Ohio'
                ,'OK', 'Oklahoma'
                ,'OR', 'Oregon'
                ,'PA', 'Pennsylvania'
                ,'RI', 'Rhode Island'
                ,'SC', 'South Carolina'
                ,'SD', 'South Dakota'
                ,'TN', 'Tennessee'
                ,'TX', 'Texas'
                ,'UT', 'Utah'
                ,'VT', 'Vermont'
                ,'VA', 'Virginia'
                ,'WA', 'Washington'
                ,'WV', 'West Virginia'
                ,'WI', 'Wisconsin'
                ,'WY', 'Wyoming'
            ] } }
        ]
    }) ];
}







# Product

sub product_ctime_mfg_last_qa_date {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Product'
        ,info_fields => {
            title => $_->product_name
            ,url => $_->db_editor_relative_url
            ,auto_ctime => '' . $_->auto_ctime
            ,manufacturer_url => $_->manufacturer ? $_->manufacturer->db_editor_relative_url : ''
            ,manufacturer_title => $_->manufacturer ? $_->manufacturer->name : ''
        }
        ,bad_fields => {
            last_qa_complete_date => $_->manufacturer->last_qa_complete_date
        }
    }, BST::Product->search(
    { 
        'me.auto_ctime' => { '>' => \"CASE WHEN manufacturer.last_qa_complete_date = '' THEN null ELSE manufacturer.last_qa_complete_date END ::timestamp + '1 day'::interval" }
    }, {
        prefetch => 'manufacturer'
    }) ];
}

sub product_systemness {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Product'
        ,info_fields => {
            title => $_->product_name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
            systemness => $_->systemness
        }
    }, BST::Product->search(
    { 
        'me.systemness' => [ -and => {'!=' => undef}, {'<>' => 'not'} ]
        ,-or => [ {'me.system_parts' => undef}, {'me.system_parts' => ''} ]
    }) ];
}


sub no_msds_document {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Product'
        ,info_fields => {
            title => $_->product_name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
        }
    }, BST::Product->search(
    {
        'd1.document_id' => undef
        ,'d2.document_id' => undef
    }, {
        from => [
            [
                { d1 => 'document', -join_type => 'left' }
                ,{
                    'me.product_id' => 'd1.product_id'
                    ,'d1.doc_type' => \" = 'msds'"
                }
            ]
            ,[
                { p => 'publication', -join_type => 'left' }
                ,{
                    'me.manufacturer_id' => 'p.company_id'
                }
            ]
            ,[
                { d2 => 'document', -join_type => 'left' }
                ,{
                    'd2.publication_id' => 'p.publication_id'
                    ,'d2.doc_type' => \" = 'msds'"
                    ,'d2.document_type' => \" = 'category'"
                    ,'d2.category_id' => 'me.category_id'
                }
            ]
        ]
        ,where => \"';' || me.check_flags || ';' !~ e'; ?msds_not_needed;'"
    }) ];
}

sub no_product_data_document {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Product'
        ,info_fields => {
            title => $_->product_name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
        }
    }, BST::Product->search(
    {
        'd1.document_id' => undef
    }, {
        from => [
            [
                { d1 => 'document', -join_type => 'left' }
                ,{
                    'me.product_id' => 'd1.product_id'
                    ,'d1.doc_type' => \" = 'product_data'"
                }
            ]
        ]
        ,where => \"';' || me.check_flags || ';' !~ e'; ?nopd;'"
    }) ];
}

sub multiple_docs_with_same_title {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Product'
        ,info_fields => {
            title => $_->product_name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
            publisher_document_title => $_->get_column('publisher_document_title')
            ,duplicates => $_->get_column('duplicates')
        }
    }, BST::Product->search(
    {
    }, {
        from => [
            [
                {
                    t => \"(select d.product_id, d.publisher_document_title, count(d.document_id) as duplicates from document as d where d.publisher_document_title is not null and d.product_id is not null group by d.product_id, d.publisher_document_title having count(d.document_id) > 1)"
                    , -join_type => 'inner'  },
                {
                    't.product_id' => 'me.product_id',
                }
            ]
        ]
        ,'+select' => [ qw/t.publisher_document_title t.duplicates/ ],
        ,'+as' => [ qw/publisher_document_title duplicates/ ],
    }) ];
}

sub many_docs {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Product'
        ,info_fields => {
            title => $_->product_name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
            docs => $_->get_column('docs')
        }
    }, BST::Product->search(
    {
    }, {
        from => [
            [
                {
                    t => \"(select d.product_id, count(d.document_id) as docs from document as d where d.product_id is not null group by d.product_id having count(d.document_id) > 9)"
                    , -join_type => 'inner'  },
                {
                    't.product_id' => 'me.product_id',
                }
            ]
        ]
        ,'+select' => [ qw/t.docs/ ],
        ,'+as' => [ qw/docs/ ],
        ,where => \"';' || me.check_flags || ';' !~ e'; ?manydocs;'"
    }) ];
}

sub product_obsolete_category {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Product'
        ,info_fields => {
            title => $_->product_name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
            category_title => $_->category ? $_->category->full_title : ''
            ,category_url => $_->category ? $_->category->db_editor_relative_url : ''
        }
    }, BST::Product->search(
    {
    }, {
        prefetch => "category"
        ,where => \"';' || category.check_flags || ';' !~ e'; ?obsolete_category;'"
    }) ];
}




# Document

sub document_ctime_mfg_last_qa_date {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Document'
        ,info_fields => {
            title => $_->title
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
            document_auto_ctime => '' . $_->auto_ctime
            ,publisher_name => ($_->publication && $_->publication->company) ? $_->publication->company->name : ''
            ,publisher_url => ($_->publication && $_->publication->company) ? $_->publication->company->db_editor_relative_url : ''
            ,publisher_last_qa_complete_date => ($_->publication && $_->publication->company) ? $_->publication->company->last_qa_complete_date : ''
        }
    }, BST::Document->search({ 
        'me.auto_ctime' => { '>' => \"CASE WHEN company.last_qa_complete_date = '' THEN null ELSE company.last_qa_complete_date END ::timestamp + '1 day'::interval" }
    }, {
        prefetch => [{'publication' => 'company'}, 'product']
    }) ];
}

sub replaced_by_document_from_other_publisher {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Document'
        ,info_fields => {
            title => $_->title
            ,url => $_->db_editor_relative_url
            ,publisher_title => ($_->publication && $_->publication->company) ? $_->publication->company->name : ''
            ,publisher_url => ($_->publication && $_->publication->company) ? $_->publication->company->db_editor_relative_url : ''
        }
        ,bad_fields => {
            document_title => $_->replaced_by_document_id ? $_->replaced_by_document_id->title : ''
            ,document_url => $_->replaced_by_document_id ? $_->replaced_by_document_id->db_editor_relative_url : ''
            ,document_company_title => ($_->replaced_by_document_id && $_->replaced_by_document_id->publication && $_->replaced_by_document_id->publication->company) ? $_->replaced_by_document_id->publication->company->name : ''
            ,document_company_url => ($_->replaced_by_document_id && $_->replaced_by_document_id->publication && $_->replaced_by_document_id->publication->company) ? $_->replaced_by_document_id->publication->company->db_editor_relative_url : ''
        }
    }, BST::Document->search(
    { 
        'me.replaced_by_document_id' => {'!=', undef}
        ,'publication.company_id' => \" <> publication_2.company_id"
    }, {
        prefetch => [{'publication' => 'company'}, {'replaced_by_document_id' => {'publication' => 'company'}}]
    }) ];
}

sub no_external_file {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Document'
        ,info_fields => {
            title => $_->title
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
            derived_path => $_->derived_path
        }
    }, grep 
        { (not -f $_->local_file_path) or (not -s _) } 
        BST::Document->search({'me.derived_path' => {'!=' => undef}}) ];
}

sub path_not_set {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Document'
        ,info_fields => {
            title => $_->title
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
            derived_path => $_->derived_path
            ,derived_path => $_->image_path
        }
    }, BST::Document->search(
    { 
        -or => [
            {'me.derived_path' => undef }
            ,{'me.image_path' => undef}
        ]
    }, {
    }) ];
}

sub publisher_not_equal_about_company {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Document'
        ,info_fields => {
            title => $_->title
            ,url => $_->db_editor_relative_url
            ,publisher_title => ($_->publication && $_->publication->company) ? $_->publication->company->name : ''
            ,publisher_url => ($_->publication && $_->publication->company) ? $_->publication->company->db_editor_relative_url : ''
        }
        ,bad_fields => {
            about_company_title => $_->about_company ? $_->about_company->name : ''
            ,about_company_url => $_->about_company ? $_->about_company->db_editor_relative_url : ''
        }
    }, BST::Document->search(
    {
        'me.document_type' => 'company'
        , -or => [
            {'me.about_company_id' => undef}
            , {'publication.company_id' => \" <> me.about_company_id"}
        ]
    }, {
        prefetch => [{'publication' => 'company'}, 'about_company']
    }) ];
}


sub no_products_in_category {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Document'
        ,info_fields => {
            title => $_->title
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
            category_title => $_->category ? $_->category->full_title : ''
            ,category_url => $_->category ? $_->category->db_editor_relative_url : ''
        }
    }, BST::Document->search(
    {
        'category.category_id' => {'!=' => undef}
        ,'category_counts.category_id' => undef
    }, {
        prefetch => [{'publication' => 'company'}, {'category' => 'category_counts'}]
    }) ];
}



# Publisher

sub publisher_no_publications {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Company'
        ,info_fields => {
            title => $_->name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
        }
    }, BST::Company->search(
    { 
        'me.publisher_status' => { "!=" , undef }
        ,'publications.publication_id' => undef
    }, {
        join => 'publications'
    }) ];
}

sub publisher_no_docs {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Company'
        ,info_fields => {
            title => $_->name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
        }
    }, BST::Company->search(
    { 
        'me.publisher_status' => { "!=" , undef }
        ,'publications.publication_id' => { '!=' => undef }
        ,'documents.document_id' => undef
    }, {
        join => { 'publications' => 'documents' }
    }) ];
}

sub publisher_no_match_publication_id {
    my @items = BST::Company->search(
    { 
        'me.publisher_status' => { "!=" , undef }
        ,'publications.publication_id' => { "!=" , undef }
    }, {
        prefetch => 'publications'
        ,where => \'publications.publication_id <> publications.company_id'
    });
    my @result = ();
    for my $item (@items) {
        for my $publication ($item->publications) {
            push @result, {
                object_id => $item->id
                ,bsa_class_name => 'Company'
                ,info_fields => {
                    title => $item->name
                    ,url => $item->db_editor_relative_url
                }
                ,bad_fields => {
                    publication_id => $publication->publication_id
                    ,publication_url => $publication->db_editor_relative_url
                }
            };
        }
    }
    return \@result;
}

sub publisher_no_products {
    [ map {
        object_id => $_->id
        ,bsa_class_name => 'Company'
        ,info_fields => {
            title => $_->name
            ,url => $_->db_editor_relative_url
        }
        ,bad_fields => {
        }
    }, BST::Company->search(
    { 
        'me.publisher_status' => { "!=" , undef }
        ,'products.product_id' => undef
    }, {
        join => 'products'
    }) ];
}








# TODO
sub orphan_directory {
    return [];
}




# Summary report

sub load_summary_report {
    my $timestamp = shift;

    my $row;
    if ($timestamp) {
        $row = &schema->resultset("BST::DBCheckReport")->search(
        {
            'rule_id' => 'summary'
            , 'auto_ctime' => \" <= '$timestamp'::timestamp + '1 day'::interval"
        }, {
            order_by => 'auto_ctime DESC'
        })->first();
    }
    if (! $row) {
        $row = &schema->resultset("BST::DBCheckReport")->search(
        {
            'rule_id' => 'summary'
        }, {
            order_by => 'auto_ctime DESC'
        })->first();
    }
    return $row;
}

sub summary {
    {
        object_id => ''
        ,bsa_class_name => ''
        ,info_fields => {
            company_live => BST::Company->search({'publisher_status' => 'live', 'compnay_type' => 'manufacturer'})->count
            ,company_qa => BST::Company->search({'publisher_status' => 'qa', 'compnay_type' => 'manufacturer'})->count
            ,company_no_products => BST::Company->search({ 'product_id' => undef, 'compnay_type' => 'manufacturer'}, {join => 'products'})->count
            ,product => BST::Product->search({})->count
            ,product_live => BST::Product->search({'manufacturer.publisher_status' => 'live'}, {join => 'manufacturer'})->count
            ,product_qa => BST::Product->search({'manufacturer.publisher_status' => 'qa'}, {join => 'manufacturer'})->count
            ,product_suppressed => BST::Product->search({ 'me.suppress_reason_code' => {'<>' => ''} })->count
            ,document => BST::Document->search({})->count
            ,document_live => BST::Document->search({'company.publisher_status' => 'live'}, {join => {'publication' => 'company'}})->count
            ,document_qa => BST::Document->search({'company.publisher_status' => 'qa'}, {join => {'publication' => 'company'}})->count
            ,document_suppressed => BST::Document->search({ 'me.suppress_reason_code' => {'<>' => ''} })->count
            ,document_replaced => BST::Document->search({ 'replaced_by_document_id' => {'!=' => undef} })->count
            ,document_doctype_live => { 
                map {$_->get_column('doc_type') => $_->get_column('doc_count') } 
                BST::Document->search(
                    {'company.publisher_status' => 'live'}
                    , {
                        join => {'publication' => 'company'}
                        , group_by => [qw/ doc_type /]
                        , select   => [ 'doc_type', { count => 'document_id' } ],
                        , as       => [qw/ doc_type doc_count /],
                    }
                )->all
            }
        }
        ,bad_fields => {
        }
    };
}



1;

