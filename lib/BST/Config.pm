package BST;
use strict;

my $HOME = '/home/alex/projects/build-site';

# if you add / modify / remove parameters here, please update
# http://trac.ahinea.com/bs-app/wiki/ConfigurationParameters
# wiki page

sub configuration {
    {
        dbname => 'bsdata',
        dbuser => 'bsadmin',
        dbpass => $ENV{BST_DBPASS}, # optional; provide via BST_DBPASS env var (never hardcode)

        home => $HOME . '/bs-app',
        temp => $HOME . '/temp',
        sent_messages_path     => $HOME . '/bsfiles/sent_messages',
        account_locations_path => $HOME . '/bsfiles/account_locations',
        publishers_path        => $HOME . '/bsfiles/publishers',
        settings_path          => $HOME . '/bsfiles/settings',

        toc             => $HOME . '/bsfiles/toc',
        templates       => $HOME . '/bs-app/templates',
        root_static     => $HOME . '/bs-app/root',

        pdf_generator   => $HOME . '/bs-app/pdf/generate_pdf.sh',

        toc_thumb_size  => 400,

        document_url => 'http://buildsite.com/dbderived/%%publicationid%%/derived_files/%%derived_path%%',

        cache_db => 60,

        smtp_host => "localhost",
        email_size_limit => 500,
        smtp_port => 25,
        send_message => 1,
        send_address_whitelist => {
          'kurmanka@yandex.ru' => 1,
          'test1@test.com' => 1,
          '+375-29-6664555' => 1,
          'kikudjiro@gmail.com' => 0,
          '+375-29-6664555' => 0,
        },
        # send a copy of each outbound message to this address. useful for debugging:
        #send_message_BCC => 'debug-messages@ahinea.com',

        # Session
        session_storage_plugin => 'Session::Store::File',
        session_storage_params => {
            storage     => '/tmp/session',
        },

        #session_storage_plugin  => 'Session::Store::Memcached',
        #session_storage_params  => {
        #    servers     => ['127.0.0.1:11211'],
        #    namespace   => '',
        #},

        # fax sending account info
        fax_pagecount_limit        => 10,
        interfax_account           => 'buildsite@crunch.ahinea.com',
        interfax_reply_to          => 'buildsite@crunch.ahinea.com',
        interfax_domain            => '@fax.tc',

        log_dir => $HOME . '/bs-app/log2',
        logger => {
            prefix => $HOME . '/bs-app/log2',
            mode => 'append',
            categories => {
                # package       => name
                'BST::Product'  => 'search',
                'BST::Category' => 'category',
                'BST'           => 'bst',
                'dbcheck.pl'    => 'dbcheck',
            },
        },

        zip_codes_file => $HOME . '/bs-app/ZIPCODEWORLD-US-PREMIUM.CSV',
        zip_search_max_distance => 150,

        page_count_command => {
            word => '/usr/bin/wvSummary "%s" | grep Pages',
            pdf  => '/usr/bin/pdfinfo "%s" | grep Pages',
        },

        # Object cache
        #cache   => 'BST::Cache::Dumb',
        cache   => 'BST::Cache::Null',

        # CGI::FormBuilder config:
        #formbuilder_debug => 1,

        # Log::Dispatch captures and redirects the usual server output
        # like the list of actions and controllers and their exceptions
        # to a log. Exceptions (die-s) go to bsa-error-{date} log, and
        # the list of actions and request details go to bsa-debug-{date}
        # log in log2/ dir.

        'Log::Dispatch' => [{
            class       => 'File::Stamped',
            name        => 'bsa-debug',
            min_level   => 'debug',
            filename    => $HOME . '/bs-app/log2/bsa-debug',
            mode        => 'append',
            stamp_fmt   => '%Y%m%d',
#        format    => '[%p] %m %n',
        },{
            class       => 'File::Stamped',
            name        => 'bsa-error',
            min_level   => 'error',
            filename    => $HOME . '/bs-app/log2/bsa-error',
            mode        => 'append',
            stamp_fmt   => '%Y%m%d',
#        format    => '[%p] %m %n',
        }],

        # START: BST::Schema cache
        schema_cache_backend    => 60 * 5,
        schema_cache_tables     => [qw/
            category category_descendant category_grouping category_keyword
            company company_feature company_grouping company_keyword
            product product_keyword product_related product_standard
            document document_list document_list_member doc_type_info
            publication
            grouping
            standard
        /],
        schema_cache_backend            => 'Cache::Memcached',
        schema_cache_backend_settings   => {
            'Cache::Memcached'      => {
                servers             => [
                    '127.0.0.1:11211'
                ],
                namespace           => 'BST::Schema::',
                connect_timeout     => 0.2,
                io_timeout          => 0.5,
                close_on_error      => 1,
                compress_threshold  => 200_000,
                compress_ratio      => 0.9,
                compress_methods    => [
                    \&IO::Compress::Gzip::gzip,
                    \&IO::Uncompress::Gunzip::gunzip
                ],
                max_failures        => 3,
                failure_timeout     => 2,
                ketama_points       => 150,
                nowait              => 1,
                hash_namespace      => 2,
                serialize_methods   => [
                    \&Storable::freeze,
                    \&Storable::thaw
                ],
                utf8                => ($^V ge v5.8.1 ? 1 : 0),
                max_size            => 512 * 1024,
                debug               => 0
            },
            'Cache::File'           => {
                cache_root          => '/tmp/bst-schema-cache',
            }
        },
        # END: BST::Schema cache

        ###
        email_errors    => {
            from            => 'randal@buildsite.com',
            to              => 'bs-ah-project@googlegroups.com',
            response_status => 500,
            error_template  => 'default.tt'
        },
        ###


        # "post to URL" feature
        enable_send_package_URL => 1,

        # max lifetime period for the "cached" toc xhtml+pdf+thumb files, in minutes
        package_toc_output_cache_min => 1, 

        # max lifetime period for the stored Current Package JSON
        package_json_lifetime   => 5, 
        undelivered_messages_list_lifetime => 10,

        undelivered_messages_check_after_seconds => 10,

        # the Google Analytics website id for user tracking
        google_analytics_id => "UA-9236361212-1", 
        #user_tracking_snippet => q~<script type='text/javascript'>alert('user tracking!');</script>~,
        system_id => "BS5555",

        # height limit for 2nd page logo of pdf toc
        # it needs to correct appropriate values in CSS as well: pdf_toc.css, ext.css
        toc_pdf_2nd_page_header_logo_height_max => 50,

        db_editor_site => 'http://crunch.ahinea.com/dbadm/admin/dbadm'

    }
}

1;
