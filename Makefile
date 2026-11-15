SHELL=/bin/bash
FULLPERL      = /usr/bin/perl5.8.8
FULLPERLRUN   = /usr/bin/perl -w
LIB           = lib
SERVER_PID_FILE = bsa_server.pid

TEST_VERBOSE  = 0
TEST_FILES    = t/*.t
TESTDB_SW     = -d

test ::
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-e" "test_harness($(TEST_VERBOSE), '$(LIB)')" $(TEST_FILES)

use_test ::
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-e" "test_harness($(TEST_VERBOSE), '$(LIB)')" t/00use.t

db_upgrade ::
	$(FULLPERLRUN) bin/db-upgrade.pl

start :: use_test
	BSA_RELOAD=1 $(FULLPERLRUN) script/bsa_control.pl start

stop ::
	$(FULLPERLRUN) script/bsa_control.pl stop

status ::
	$(FULLPERLRUN) script/bsa_control.pl status

restart::
	BSA_RELOAD=1 $(FULLPERLRUN) script/bsa_control.pl restart
