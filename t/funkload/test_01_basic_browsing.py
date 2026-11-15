# -*- coding: iso-8859-15 -*-
"""bs-app basic browsing test

$Id: $
"""
import os
import unittest
from funkload.FunkLoadTestCase import FunkLoadTestCase
from webunit.utility import Upload
from funkload.utils import Data
#from funkload.utils import xmlrpc_get_credential

class Bsa(FunkLoadTestCase):
    """XXX

    This test use a configuration file bsa.conf.
    """

    def setUp(self):
        """Setting up test."""
        self.logd("setUp")
        self.server_url = self.conf_get('main', 'url')
        # XXX here you can setup the credential access like this
        # credential_host = self.conf_get('credential', 'host')
        # credential_port = self.conf_getInt('credential', 'port')
        # self.login, self.password = xmlrpc_get_credential(credential_host,
        #                                                   credential_port,
        # XXX replace with a valid group
        #                                                   'members')

    def test_basic_browsing(self):
        # The description should be set in the configuration file
        server_url = self.server_url
        # begin of test ---------------------------------------------


        self.get(server_url + "/",
            description="Get /")

        self.post(server_url + "/login", params=[
            ['login', 'ik@ahinea.com'],
            ['password', os.environ.get('BST_TEST_PASS')],
            ['goto', '']],
            description="Post /login")

        self.get(server_url + "/categories/list",
            description="Get /categories/list")

        self.get(server_url + "/companies/view?id=lmscofield",
            description="Get /companies/view")

        self.get(server_url + "/product/list?manufacturer=lmscofield",
            description="Get /product/list")

        self.get(server_url + "/product/view?id=lithochrome_chemstain",
            description="Get /product/view")

        self.get(server_url + "/categories/list?manufacturer=lmscofield",
            description="Get /categories/list")

        self.get(server_url + "/product/list?category=03390a&manufacturer=lmscofield",
            description="Get /product/list")

        self.get(server_url + "/categories/list?manufacturer=lmscofield",
            description="Get /categories/list")

        self.get(server_url + "/categories/view?id=03390a",
            description="Get /categories/view")

        self.get(server_url + "/companies/list?category=03390a",
            description="Get /companies/list")

        self.get(server_url + "/product/list?category=03390a",
            description="Get /product/list")

        self.get(server_url + "/companies/view?id=whitecaplabel",
            description="Get /companies/view")

        self.get(server_url + "/messages/list",
            description="Get /messages/list")

	# this was present in the bsdata_v3_copy database 
        # on crunch on Monday, Apr 27 and this should stay 
        # in beta and production v3 database
        self.get(server_url + "/ext/message/617f894418bcb7b0d49414d1038ed15e427270777",
            description="Get /ext/message/617f89...d1038ed15e427270777")

        self.get(server_url + "/folders/list?scope=all",
            description="Get /folders/list")

        self.get(server_url + "/folders/list?scope=account",
            description="Get /folders/list")

        self.get(server_url + "/folders/list?scope=location",
            description="Get /folders/list")

        self.get(server_url + "/folders/list?scope=user",
            description="Get /folders/list")

        self.get(server_url + "/settings",
            description="Get /settings")

        self.get(server_url + "/logout",
            description="Get /logout")

        # end of test -----------------------------------------------

    def tearDown(self):
        """Setting up test."""
        self.logd("tearDown.\n")



if __name__ in ('main', '__main__'):
    unittest.main()
