#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Getopt::Long;
use Data::Dumper;

use DBI;
use File::Rsync;
use File::Read;
use File::Find;

use BST;

=head1 USAGE

$ perl -w bin/import-accounts.pl \
  --accounts individual_scott_ai_sai_beachsideroofinghawaii_com \
  --fbdb=/database/legacy/app.gdb --fbhost=localhost --fbuser=<fb-user> --fbpass=<fb-pass> \
  --nofilecopy --remote=/bsfiles

=cut 

my $import_addressbook = 1;
my $import_messages = 1;
my $import_files    = 1;
my $import_settings = 1;
my ($config, $rsync, $from_dbh, $to_dbh, $sth);
my (@accounts, $pg_db, $pg_user, $pg_pass, $fb_db, $fb_host, $fb_user, $fb_pass, $remote, $all, $show, $test);
my ($sync_tmp, $sync_src, $sync);
my ($nofilecopy) = 1; # do not rsync or copy any files -- just the database records

GetOptions(
    "accounts=s{1,}" => \@accounts,
    "pgdb=s"        => \$pg_db,
    "pguser=s"      => \$pg_user,
    "pgpass=s"      => \$pg_pass,
    "fbdb=s"        => \$fb_db,
    "fbhost=s"      => \$fb_host,
    "fbuser=s"      => \$fb_user,
    "fbpass=s"      => \$fb_pass,
    "remote=s"      => \$remote,
    "test"          => \$test,
    "show"          => \$show,
    "all"           => \$all,
    "nofilecopy"    => \$nofilecopy,
);

$config = BST::configuration();

$fb_db   ||= $config->{legacy}{db};
$fb_host ||= $config->{legacy}{host};
$fb_user ||= $config->{legacy}{user};
$fb_pass ||= $config->{legacy}{pass};


$sync_tmp    = '/tmp/sync';
$sync_src    = $remote || $config->{bsfiles} 
   or die "no source of files is specified";

$rsync      = File::Rsync->new({
    compress        => 1,
    rsh             => '/usr/bin/ssh',
    links           => 1,
    recursive       => 1,
    times           => 1,
});

if ($nofilecopy) {
    $rsync = RSYNC::MOCK->new();
}

if(not $pg_db and not $pg_user and not $pg_pass) {
    $pg_db   = $config ->{dbname};
    $pg_user = $config ->{dbuser};
    $pg_pass = $config ->{dbpass};
}

$from_dbh   = DBI->connect(
    "DBI:InterBase:db=$fb_db;" . ($fb_host ? "host=$fb_host;" : '') . "ib_dialect=3;ib_charset=UTF8;ib_cache=10",
    $fb_user,
    $fb_pass,
    {
        ReadOnly    => 1,
        PrintWarn   => 1,
        PrintError  => 1,
        RaiseError  => 0,
        AutoCommit  => 0,
    }
) or die;
$to_dbh     = DBI->connect(
    "DBI:Pg:dbname=$pg_db",
    $pg_user,
    $pg_pass,
    {
        PrintWarn       => 1,
        PrintError      => 1,
        RaiseError      => 0,
        AutoCommit      => 1,
        pg_enable_utf8  => 1,
    }
) or die;

if ($show) {
    my @accounts = _get_accounts();

    print "[!] Total accounts " . scalar @accounts . "\n";
    print "[!] Accounts list:\n";
    print "\t\taccount name: $_\n" foreach (@accounts);
}

@accounts = _get_accounts() if $all;

foreach my $account (@accounts) {
    my ($account_data, @locations, $total);

    print "\n[!] Start import data for '$account' account.\n";

    $account_data->{account}    = _get_data('account', { account_id => $account });
    unless ($account_data->{account}) { print "[-] Data for '$account' not found.\n"; next; }

    $account_data->{account_location}   = _get_data('account_location', { account_id => $account });
    @locations   = map { $_->{ACCOUNT_LOCATION_ID} } @{ $account_data->{account_location} };

    next unless scalar @locations;

    $account_data->{account_user}               = _get_data('buildsite_user', { primary_location => [ @locations ] });

    if ($import_addressbook) {
        $account_data->{account_private_company}    = _get_data('account_private_company', { owner => [ @locations ] });

        if(0) { # see comment below
            my @addressbook_companies = _get_select('account_private_company', 'private_company_id', 
                                                    { owner => [ (1..scalar(@locations)) ] },
                );
            
            $account_data->{account_private_location}   = _get_data('account_private_location', {
                account_private_company_ref => \@addressbook_companies
                                                                    },
                                                                    [ @locations ]
                );
            $account_data->{account_private_person}     = _get_data('account_private_person', {
                account_private_company_ref => \@addressbook_companies 
                                                                    },
                                                                    [ @locations ]
                );
        } # end if
        # that was an attempt to rewrite the following code:
        # but that attempt didn't work

        $account_data->{account_private_location}   = _get_data('account_private_location', {
            account_private_company_ref => \_get_select('account_private_company', 'private_company_id', 
                                                        { owner => [ (1..scalar(@locations)) ] }), },
                                                        [ @locations ]
            );

        $account_data->{account_private_person}     = _get_data('account_private_person', {
            account_private_company_ref => \_get_select('account_private_company', 'private_company_id', { owner => [
                                                                                                               (1..scalar(@locations))
                                                                                                               ] }),
                                                                },
                                                                [ @locations ]
            );

    }

    if ($import_messages) {
        $account_data->{account_messages}           = _get_data('sent_message', { owner => [ @locations ] });
    }

    if ($import_files) {
        $account_data->{account_files}              = _get_data('account_private_file', { owner => [ @locations ] });
    }

    if ($import_settings) {
        $account_data->{account_settings}           = _get_data('setting', { level_restrict_val => $account });
    }

    print "[+] Get data from legacy database for this account";
    print "\n\t- ", total($account_data->{account_location}), " locations";
    print "\n\t- ", total($account_data->{account_user}), " users";
    print "\n\t- ", total($account_data->{account_private_company}), " company items in addressbook";
    print "\n\t- ", total($account_data->{account_private_person}), " person items in addressbook";
    print "\n\t- ", total($account_data->{account_private_location}), " private locations";
    print "\n\t- ", total($account_data->{account_messages}), " messages";
    print "\n\t- ", total($account_data->{account_files}), " files";
    print "\n\t- ", total($account_data->{account_settings}), " settings";

    # ACCOUNT->ACCOUNT
    import_data(
        $account_data->{account},
        'account',
        'account',
        [qw/ACCOUNT_ID/]
    ) if $account_data->{account};

    # ACCOUNT_LOCATION->ACCOUNT_LOCATION
    import_data(
        $account_data->{account_location},
        'account_location',
        undef,
        [qw/ACCOUNT_LOCATION_ID/]
    ) if $account_data->{account_location};

    # BUILDSITE_USER->ACCOUNT_USER
    import_data(
        $account_data->{account_user},
        'buildsite_user',
        'account_user',
        [qw/USER_ID/]
    ) if $account_data->{account_user};

    # ACCOUNT_PRIVATE_COMPANY->ADDRESSBOOK_COMPANY
    import_data(
        $account_data->{account_private_company},
        'account_private_company',
        'addressbook_company',
        [qw/OWNER PRIVATE_COMPANY_ID/],
        [qw/OWNER ADDRESSBOOK_COMPANY_ID/]
    ) if $account_data->{account_private_company};

    # ACCOUNT_PRIVATE_LOCATION->ACCOUNT_PRIVATE_LOCATION
    import_data(
        $account_data->{account_private_location},
        'account_private_location',
        undef,
        [qw/PRIVATE_LOCATION_ID/],
    ) if $account_data->{account_private_location};

    # ACCOUNT_PRIVATE_PERSON->ADDRESSBOOK_PERSON
    import_data(
        $account_data->{account_private_person},
        'account_private_person',
        'addressbook_person',
        [qw/PRIVATE_PERSON_ID/],
    ) if $account_data->{account_private_person};

    # SENT_MESSAGE->MESSAGE
    import_data(
        $account_data->{account_messages},
        'sent_message',
        'message',
        [qw/MESSAGE_ID/]
    ) if $account_data->{account_messages};

    # ACCOUNT_PRIVATE_FILE->FILE
    import_data(
        $account_data->{account_files},
        'account_private_file',
        'file',
        [qw/PRIVATE_FILE_ID/],
        [qw/FILE_ID/],
    ) if $account_data->{account_files};

    # SETTING->SETTING
    import_data(
        $account_data->{account_settings},
        'setting',
        undef,
        [qw/SETTING_ID/],
    ) if $account_data->{account_settings};

    foreach my $package (@{ sql_query($from_dbh, sql_select('account_private_file', undef, { owner => [ @locations ], file_class => 'archive' })) }) {
        my ($package_file, $package_file_content, $package_items, $have_package_items, $todo);

        $package_file    = join(q{/}, $config->{account_locations_path}, $package->{OWNER}, 'account_private_files', $package->{PRIVATE_FILE_ID} . '.txt');

        open(PKG, q{<}, $package_file) or open(PKG, q{<}, $package_file . '.DELETED') or print "\n[-]\tCan't open file $package_file: $!" and next;
            local $/;
            $package_file_content = <PKG>;
        close(PKG);

        my $i = 1;

        foreach (split(q{;}, $package_file_content)) {
            $package_items->{/(document[a-z0-9]+)$/i ? $1 : $_} = $i;
            ++$i;
        }

        foreach (@{ sql_query($to_dbh, sql_select('package_item', ['COALESCE(document_id, file_id) as package_item'], { package_id => $package->{PRIVATE_FILE_ID} })) }) {
            $have_package_items->{$_->{package_item}}++;
        }

        foreach (keys %$package_items) {
            push @{ exists($have_package_items->{$_}) ? $todo->{update} : $todo->{insert} }, $_;
            delete $have_package_items->{$_};
        }

        $todo->{delete} = [ map { $_ } keys %$have_package_items ] if keys %$have_package_items;

        foreach my $action (qw/delete insert update/) {
            next unless exists($todo->{$action});

            foreach (@{ $todo->{$action} }) {
                my $type = $_ =~ /^d/i ? 1 : 0;

                if (! $type && $action ne 'delete' && ! scalar @{ sql_query($from_dbh, sql_select('account_private_file', [qw/PRIVATE_FILE_ID/], { PRIVATE_FILE_ID => $_ })) }) {
                    print "\n[-]\tFile $_ in package $package->{PRIVATE_FILE_ID} does't exists in legacy database!";
                    next;
                }

                if ($type && $action ne 'delete' && ! (
                    scalar @{ sql_query($from_dbh, sql_select('product_document', [qw/DOCUMENT_ID/], { DOCUMENT_ID => $_ })) } ||
                    scalar @{ sql_query($from_dbh, sql_select('category_document', [qw/DOCUMENT_ID/], { DOCUMENT_ID => $_ })) } ||
                    scalar @{ sql_query($from_dbh, sql_select('company_document', [qw/DOCUMENT_ID/], { DOCUMENT_ID => $_ })) })) {
                        print "\n[-]\tDocument $_ in package $package->{PRIVATE_FILE_ID} does't exists in legacy database!";
                        next;
                }

                if ($action eq 'delete') {
                    print "\n[+]\tDelete package item $_ in package $package->{PRIVATE_FILE_ID}";

                    sql_query($to_dbh, sql_delete('package_item', {
                        package_id => $package->{PRIVATE_FILE_ID},
                        ($type ? (document_id => $_) : (file_id => $_)),
                    }));

                } elsif ($action eq 'insert') {
                    print "\n[+]\tInsert package item $_ into package $package->{PRIVATE_FILE_ID}";

                    insert('package_item', {
                        package_id  => $package->{PRIVATE_FILE_ID},
                        ($type ? (document_id => $_) : (file_id => $_)),
                        item_type   => $type ? 'document' : 'file',
                        position    => $package_items->{$_},
                    });

                } else {
                    print "\n[+]\tUpdate package item $_ in package $package->{PRIVATE_FILE_ID}";

                    update('package_item',
                        { package_id => $package->{PRIVATE_FILE_ID}, ($type ? (document_id => $_) : (file_id => $_)), },
                        { position => $package_items->{$_} }
                    );
                }
            }
        }
    }
}

$from_dbh->disconnect;
$to_dbh->disconnect;

print "\n";

sub import_data {
    my @data        = @{ +shift };
    my $from_table  = shift;
    my $to_table    = shift || $from_table;
    my $from_pk     = shift;
    my $to_pk       = shift || $from_pk;

    foreach my $data (@data) {
        #---
        #Postgres TIMESTAMP 2002-06-19 17:28:35
        $data->{TIME_SENT} = sprintf(
            "%04d-%02d-%02d %02d:%02d:%02d",
            sub {shift(@_) + 1900, shift(@_) + 1, shift(@_), shift(@_), shift(@_), shift(@_)}->((localtime($data->{TIME_SENT}))[5,4,3,2,1,0])
        ) if $to_table eq 'message';

        $data->{ADDRESSBOOK_COMPANY_ID} = $data->{PRIVATE_COMPANY_ID} if $to_table eq 'addressbook_company';
        $data->{ADDRESSBOOK_COMPANY_ID} = $data->{ACCOUNT_PRIVATE_COMPANY_REF} if $to_table eq 'addressbook_person';

        $data->{FILE_ID} = $data->{PRIVATE_FILE_ID} if $to_table eq 'file';
        #---

        my $check    = check(
            $from_table,
            $to_table,
            { map { $_ => $data->{$_} } @{ $from_pk } },
            { map { $_ => $data->{$_} } @{ $to_pk } }
        );

        #---
        if ($to_table eq 'setting') {
            my $scope_compliance = {
                buildsite_user     => 'user',
                account            => 'account',
                account_location   => 'location',
                world              => 'all',
                abstract           => 'hidden',
            };

            $data->{SCOPE}          = $scope_compliance->{$data->{LEVEL_TYPE_ID}} || undef;
            $data->{SCOPE_VALUE}    = $data->{LEVEL_RESTRICT_VAL};
            delete $data->{LEVEL_TYPE_ID};
            delete $data->{LEVEL_RESTRICT_VAL};
        }
        delete $data->{CURRENT_MESSAGE} if $to_table eq 'account_user';
        delete $data->{PRIVATE_FILE_ID} if $to_table eq 'file';
        #---

        # addressbook
        delete $data->{ACCOUNT_PRIVATE_COMPANY_REF} if $to_table eq 'addressbook_person';
        delete $data->{PRIVATE_COMPANY_ID} if $to_table eq 'addressbook_company';
        if ($to_table eq 'addressbook_person' 
            and ($check == 0 or $check == 1) ) {
            # db-upgrade/data.0010.addressbook_person_owners.pl 
            # ticket #650
            
            # we assume the addressbook company records where already copied over.
            # this probably can be done much simplier, without this select query.
            # owner here is the location_id, i think. So it's just one
            # of the several locations usually.
            my ($owner) = $to_dbh->selectrow_array( 
                "SELECT owner FROM addressbook_company WHERE addressbook_company_id = ?", 
                undef, $data->{ADDRESSBOOK_COMPANY_ID});
            $data->{OWNER} = $owner || die 'no contact owner found';
        }


        if ($to_table eq 'message') {
            my $message_dir     = join(q{/}, $config->{sent_messages_path}, substr($data->{AUTO_CTIME}, 0, 4), substr($data->{AUTO_CTIME}, 5, 2), $data->{MESSAGE_ID});
            my $message_file    = join(q{/}, $message_dir, $data->{BODY_FILE_NAME});
            my $remote_dir      = join(q{/}, $sync_src, 'sent_messages', $data->{MESSAGE_ID});
            my $remote_file     = join(q{/}, $remote_dir, $data->{BODY_FILE_NAME});

            unless (-d $message_dir) {
                print "\n[+]\tImport message files for $data->{MESSAGE_ID}";

                my $year_dir    = join(q{/}, $config->{sent_messages_path}, substr($data->{AUTO_CTIME}, 0, 4));
                my $month_dir	= join(q{/}, $year_dir,  substr($data->{AUTO_CTIME}, 5, 2));

                mkdir($year_dir) or die "Can't create dir $year_dir: $!" unless (-d $year_dir);
                mkdir($month_dir) or die "Can't create dir $month_dir: $!" unless (-d $month_dir);
                mkdir($message_dir) or die "Can't create dir $message_dir: $!";

                $rsync->exec({
                    src     => $remote_dir,
                    dest    => $month_dir,
                }) or print "\n[-]\tCan't syncronize files '$remote_dir' from remote server: " . join(q{ }, $rsync->err) unless $test;

            } else {
                if ($check == 0 || $check == 1) {
                    print "\n[+]\tImport message body from file for $data->{MESSAGE_ID}";

                    $rsync->exec({
                        src     => $remote_file,
                        dest    => $message_dir,
                    }) or print "\n[-]\tMessage file '$remote_file' does not exist on remote server" unless $test;

                    my $body    = eval read_file($message_file) unless $rsync->status;

                    utf8::encode($body->{main_plain});

                    $data->{BODY} = $body->{main_plain} ? $body->{main_plain} : '';
                }
            }

            # in fact at this moment there is not a single "processed" message in the legacy db
            my $status = "failed";
            $status = "sent" if ($data->{MESSAGE_STATUS} eq "sent" || $data->{MESSAGE_STATUS} eq "processed");
            $status = "sent" if ($data->{MESSAGE_STATUS} eq "received");
            $data->{MESSAGE_STATUS} = $status;

            # XXX also need to import the message attachments, if
            # any. create a package for each message that had
            # attachments.
            # see db-upgrade/data.0004.import_sent_message_attachments.pl
            # for details        
        }
    
        if ($to_table eq 'file') {

            if ($data->{PARENT} && ! scalar @{ sql_query($to_dbh, sql_select('file', [qw/file_id/], { file_id => $data->{PARENT} })) }) {
                $data->{PRIVATE_FILE_ID} = delete $data->{FILE_ID};
                push @data, $data;
                next;
            }

            my $file_format = {
                bform       => '.frm',
                dwf         => '.dwf',
                dwg         => '.dwg',
                dxf         => '.dxf',
                excel       => '.xls',
                gif         => '.gif',
                html        => '.html',
                jpg         => '.jpg',
                pdf         => '.pdf',
                powerpoint  => '.ppt',
                rtf         => '.rtf',
                text        => '.txt',
                tiff        => '.tif',
                word        => '.doc',
            };

            my $extension = 
                ($data->{FILE_FORMAT_TYPE}) 
                ? ($file_format->{$data->{FILE_FORMAT_TYPE}} || '.' . $data->{FILE_FORMAT_TYPE})
                : '';

            $data->{FILE_EXTENSION} = 
                ($data->{FILE_FORMAT_TYPE}) 
                ? substr($extension,1)
                : '';

            my $scope_compliance = {
                buildsite_user          => 'user',
                account_location        => 'location',
                hidden                  => 'hidden',
                account                 => 'account',
            };

            my $file_class  = {
                archive     => '.txt',
                shortcut    => '.txt',
                file        => $data->{FILE_FORMAT_TYPE} ? $extension : '.txt',
                folder      => '.txt',
            };

            my $files_dir   = join(q{/}, $config->{account_locations_path}, $data->{OWNER}, 'account_private_files');
            my $file        = join(q{/}, $files_dir, "$data->{FILE_ID}$file_class->{$data->{FILE_CLASS}}");
            my $remote_dir  = join(q{/}, $sync_src, 'account_locations', $data->{OWNER}, 'account_private_files');
            my $remote_file = join(q{/}, $remote_dir, "$data->{FILE_ID}$file_class->{$data->{FILE_CLASS}}");

            $data->{SCOPE} = $scope_compliance->{$data->{SCOPE}} || 'all';
            $data->{FILE_CLASS} ||= 'file';

            unless (-d $files_dir) {
                print "\n[+]\tImport private files '$remote_dir' for $data->{OWNER}";

                mkdir(join(q{/}, $config->{account_locations_path}, $data->{OWNER}));
                mkdir($files_dir);

                $rsync->exec({
                    src     => $remote_dir . '/',
                    dest    => $files_dir,
                }) or print "\n[-]\tCan't syncronize remote files $remote_dir" unless $test;

                $sync->{$data->{OWNER}}->{files} = 1;

            } else {

                if (! $sync->{$data->{OWNER}}->{files}) {
                #if ($check == 0 || $check == 1 && ! $sync->{$data->{OWNER}}->{files}) {
                    print "\n[+]\tImport private file '$remote_file' for $data->{OWNER}";

                    #unlink($file);

                    $rsync->exec({
                        src     => $remote_file,
                        dest    => $files_dir,
                    }) or print "\n[-]\tCan't syncronize remote file $remote_file" unless $test;
                #}
                }
            }
        }

        if ($to_table eq 'setting' && $data->{ATT_NAME} =~ /_file$/) {
            (my $file              = $data->{ATT_NAME}) =~ s/^(.*)_file$/$1/;
            my $setting_dir        = "$data->{SCOPE}-$data->{SCOPE_VALUE}";
            my $local_dir          = join(q{/}, $config->{settings_path}, $setting_dir);
            my $remote_dir         = join(q{/}, $sync_src, 'settings', $setting_dir);

            unless (-d $local_dir) {
                print "\n[+]\tImport settings files '$local_dir' for $data->{SCOPE_VALUE}";

                mkdir $local_dir;
                $rsync->exec({
                    src     => join(q{/}, $sync_src, 'settings', $setting_dir),
                    dest    => $config->{settings_path},
                }) or print "\n[-]\tCan't syncronize remote files $remote_dir" unless $test;
            } else {
                if ($check == 0 || $check == 1) {
                    print "\n[+]\tImport settings file '$local_dir' for $data->{SCOPE_VALUE}";
                }
            }

            find({
                wanted => sub {
                    if ($File::Find::name =~ /.*(logo|signature|sponsor_logo|fax_cover_template|email_plain_template_file)\.(\w+)$/) {
                        $data->{ATT_VAL} = "$setting_dir/$1.$2";
                    };
                },
            }, $local_dir) unless $test;
        }

        utf8::encode($data->{ATT_VAL}) if $data->{ATT_VAL};
        utf8::encode($data->{COMPANY_FULLNAME}) if $data->{COMPANY_FULLNAME};
        utf8::encode($data->{FAMILY_NAME}) if $data->{FAMILY_NAME};

        unless ($test) {
            if ($check == 0) {
                insert($to_table, $data);
            } elsif ($check == 1) {
                update($to_table, { map { $_ => $data->{$_} } @{ $to_pk } }, $data);
            } elsif ($to_table eq 'file' || $to_table eq 'setting') {
                update($to_table, { map { $_ => $data->{$_} } @{ $to_pk } }, $data);
            }

            #if ($to_table eq 'file' || $to_table eq 'setting') {
            #    update($to_table, { map { $_ => $data->{$_} } @{ $to_pk } }, $data);
            #}
        }

        if ( $to_table eq 'message' ) {

            # import message recipients too #650
            # db-upgrade/data.0002.import_message_recipients.m03.pl
            if( $check == 0 and $data->{RECIPIENT_FKEY} ) {

                print "\n[+]\tImport message recipients for $data->{MESSAGE_ID}";

                my $status = "failed";
                $status = "sent" if ($data->{MESSAGE_STATUS} eq "sent" || $data->{MESSAGE_STATUS} eq "processed");
                $status = "sent" if ($data->{MESSAGE_STATUS} eq "received");

                # get nextval from main
                my @_nextid_q = sql_query($to_dbh, ["select nextval('main') as nextid", [] ] );
                my $id = $_nextid_q [0] [0] {nextid};
                die if not $id;
                die if $id < 100000;
                my $recipient_id = "message_recipient_$id";
                my $type    = $data->{RECIPIENT_ADDRESS_TYPE} || die;
                my $address = $data->{RECIPIENT_ADDRESS} || die;
                insert( 'message_recipient', 
                        { message_id => $data->{MESSAGE_ID},
                          recipient_id => $recipient_id,
                          type => $type,
                          send_type => 'to',
                          address => $address,
                          contact_id => $data->{RECIPIENT_FKEY},
                          status => $status,
                        }
                );
            }
            # import message attachements too #650
            # db-upgrade/data.0004.import_sent_message_attachments.pl
            if( $check == 0 and $data->{ATTACHED_FILE_IDS} ) {
              my @ids = split(q/;/, $data->{ATTACHED_FILE_IDS});
              
              foreach (@ids) {
                my ($_id, $s) = split '=';
                my $obj = undef;
                #if ($s eq 'derived_file') {
                #    $obj = BST::Document->search({ 
                #        derived_path => { '>=' => "$id.",   
                #                          '<=' => "$id.z" } 
                #    })->next;
                #} elsif ($s eq 'account_private_file') {
                #    $obj = BST::File->load({ file_id => $id });
                #}
                #if ($obj) {
                #    $result->{$obj->id} = $obj;
                #}
              }
            }
        } # if to_table == message

    }
}

sub insert {
    my $table   = shift;
    my $values  = shift;

    my $rows = $to_dbh->do(
        "INSERT INTO $table (" .
            lc(join(q{, }, sort keys %{ $values })) .
            ") VALUES (" .
            '?, ' x ((keys %{ $values }) - 1) .
            "?)",
        undef,
        map { $values->{$_} } sort keys %{ $values },
    ) or die "Can't insert data into table $table: " . $to_dbh->errstr . "\n" . Dumper($table, $values);

    return $rows;
}

sub update {
    my $table   = shift;
    my $pk      = shift;
    my $values  = shift;

    delete $values->{uc($_)} foreach keys %{ $pk };

    my $rows = $to_dbh->do(
        "UPDATE $table SET " .
            join(q{, }, map { lc($_) .
            ' = ?'} sort keys %{ $values }) .
            " WHERE " .
            join(q{ AND }, map { lc($_) . ' = ?'} sort keys %{ $pk }),
        undef,
        (map { $values->{$_} } sort keys %{ $values }), map { $pk->{$_} } sort keys %{ $pk },
    ) or die "Can't update data into table $table: " . $to_dbh->errstr . "\n" . Dumper($table, $values);

    return $rows;
}

sub check {
    my $from_table  = shift;
    my $to_table    = shift || $from_table;
    my $from_pk     = shift;
    my $to_pk       = shift || $from_pk;

    my (@from_cmtime, @to_cmtime);

    @from_cmtime    = _get_cmtime($from_dbh, $from_table, $from_pk);
    @to_cmtime      = _get_cmtime($to_dbh, $to_table, $to_pk);

    if (scalar @to_cmtime == 0) {
        print "\n[+]\tCheck data '$to_table' keys:" . join(q{ }, map { "$_=$from_pk->{$_}" } sort keys %{ $from_pk }) . "\n";
        print "[-]\t\t- data for " . join(q{ }, map { "$from_pk->{$_}" } sort keys %{ $from_pk }) . " does not exist\n";
        print "[+]\tImport data to '$to_table' for keys:" . join(q{ }, map { "$to_pk->{$_}" } sort keys %{ $to_pk });
        return 0;

    } elsif ((defined($from_cmtime[0]) && defined($to_cmtime[0]) && $from_cmtime[0] ne $to_cmtime[0])
            ||
            (defined($from_cmtime[1]) && defined($to_cmtime[1]) && $from_cmtime[1] ne $to_cmtime[1])
            ||
            (defined($from_cmtime[0]) && ! defined($to_cmtime[0]) || ! defined($from_cmtime[0]) && defined($to_cmtime[0]))
            ||
            (defined($from_cmtime[1]) && ! defined($to_cmtime[1]) || ! defined($from_cmtime[1]) && defined($to_cmtime[1]))
            ) {

        print "\n[+]\tCheck data '$to_table' keys:" . join(q{ }, map { "$_=$from_pk->{$_}" } sort keys %{ $from_pk }) . "\n";
        print "[-]\t\t- data for " . join(q{ }, map { "$from_pk->{$_}" } sort keys %{ $from_pk }) . " is not equivalent\n";
        print "[+]\tUpdate '$to_table' data for keys:" . join(q{ }, map { "$to_pk->{$_}" } sort keys %{ $to_pk });
        return 1;

    } elsif ((defined($from_cmtime[0]) && defined($to_cmtime[0]) && $from_cmtime[0] eq $to_cmtime[0])
            ||
            (defined($from_cmtime[1]) && defined($to_cmtime[1]) && $from_cmtime[1] eq $to_cmtime[1])) {
        return 2;
    }
}

sub _get_cmtime {
    my $dbh     = shift;
    my $table   = shift;
    my $pk      = shift;

    return $dbh->selectrow_array(
        "SELECT auto_ctime, auto_mtime FROM $table WHERE " .
            join(q{ AND }, map { lc($_) .
            ' = ?'} sort keys %{ $pk }),
        undef,
        map { $pk->{$_} } sort keys %{ $pk }
    );
}

sub _get_data {
    my $table       = uc(shift);
    my $pk          = shift;
    my $additional  = shift;
    my $order       = shift;

    my ($result, $query);

    $query  = "SELECT * FROM $table WHERE " .
        join(q{ AND },
            map {
                ref $pk->{$_} eq 'SCALAR' ?
                    lc($_) . ' IN (' . ${ $pk->{$_} }. ')' :
                ref $pk->{$_} eq 'ARRAY' ?
                    lc($_) . ' IN (' . '?, ' x (scalar @{ $pk->{$_} } - 1) . '?)' :
                    lc($_) . ' = ?'
            } sort keys %{ $pk }

        ) . ($order ? " ORDER BY $order" : '');#. " ORDER BY auto_mtime ASC";

    $sth    = $from_dbh->prepare($query);

    grep { delete $pk->{$_} if ref $pk->{$_} eq 'SCALAR' } keys %{ $pk };

    $sth->execute(
        (map {
            ref $pk->{$_} ne 'ARRAY' ?
            $pk->{$_}                :
            @{ $pk->{$_} }
        } sort keys %{ $pk }),
        @{ $additional }
    ) or Carp::confess $from_dbh->errstr;

    if ($sth->rows) {
        while (my $row = $sth->fetchrow_hashref) {
            push @{ $result }, $row;
        }
    }

    return $result;
}

sub _get_select {
    my $table   = uc(shift);
    my $values  = shift || '*';
    my $pk      = shift;

    return "SELECT $values FROM $table WHERE " .
        join(q{ AND },
            map {
                ref $pk->{$_} ne 'ARRAY' ?
                    lc($_) . ' = ?'      :
                    lc($_) . ' IN (' . '?, ' x (scalar @{ $pk->{$_} } - 1) . '?)'
            } sort keys %{ $pk }
        );
}

sub _get_accounts {
    my @accounts;

    $sth = $from_dbh->prepare('SELECT account_id FROM ACCOUNT'); $sth->execute();
    while (my $row = $sth->fetchrow_hashref) { push @accounts, $row->{ACCOUNT_ID}; }

    return @accounts;
}

sub total {
    return $_[0] ? scalar @{ $_[0] } : 0
}

sub sql_query {
    my $dbh     = shift;
    my $query   = shift;

    my $sth     = $dbh->prepare(shift(@$query));

    $sth->execute(@{ shift(@$query) }) or die $dbh->errstr;

    return $sth->{Statement} =~ /^\s*SELECT\s/i ? $sth->fetchall_arrayref({}||[]) : $sth->rows;
}

sub sql_select {
    my $table   = shift;
    my $select  = shift;
    my $where   = shift;

    my $sql = "SELECT " . ($select ? join(q{, }, @{ $select }) : '*') . " FROM $table";

    if ($where) {
        $sql .= " WHERE " .
            join(q{ AND },
                map {
                    ref $where->{$_} eq 'CODE'                         ?
                        lc($_) . ' IN (' . ($where->{$_}->())[0] . ")" :
                    ref $where->{$_} ne 'ARRAY'                        ?
                        lc($_) . ' = ?'                                :
                        lc($_) . ' IN (' . '?, ' x (scalar @{ $where->{$_} } - 1) . '?)'
                } sort keys %{ $where }
            );
    }

    return [ $sql, [ map {
        ref $where->{$_} eq 'CODE'  ?
            @{ ($where->{$_}->())[1] }  :
        ref $where->{$_} ne 'ARRAY' ?
            $where->{$_}            :
            @{ $where->{$_} }
    } sort keys %{ $where } ] ];
}

sub sql_delete {
    my $table   = shift;
    my $where   = shift;

    my $sql = "DELETE FROM $table";

    if ($where) {
        $sql .= " WHERE " .
            join(q{ AND },
                map {
                    ref $where->{$_} eq 'CODE'                         ?
                        lc($_) . ' IN (' . ($where->{$_}->())[0] . ")" :
                    ref $where->{$_} ne 'ARRAY'                        ?
                        lc($_) . ' = ?'                                :
                        lc($_) . ' IN (' . '?, ' x (scalar @{ $where->{$_} } - 1) . '?)'
                } sort keys %{ $where }
            );
    }

    return [ $sql, [ map {
        ref $where->{$_} eq 'CODE'  ?
            @{ ($where->{$_}->())[1] }  :
        ref $where->{$_} ne 'ARRAY' ?
            $where->{$_}            :
            @{ $where->{$_} }
    } sort keys %{ $where } ] ];
}

package RSYNC::MOCK;
use Data::Dumper;
sub new { 
    my $class = shift;
    return bless {}, $class;
}
sub err { return undef; }
sub exec { my ($s,$sync) = @_; 
           #print "\nrsync from ", $sync->{src}, 
           #" to ", $sync->{dest}, "\n";
           return 1; }
sub status { return 0; }
1;
