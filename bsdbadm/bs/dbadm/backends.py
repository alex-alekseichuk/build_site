from django.http import HttpResponseRedirect, HttpResponseForbidden
from django.contrib.auth import authenticate, login
from django.contrib.auth.models import User
from django.contrib.auth.backends import ModelBackend

from datetime import date

import logging

import settings
from dbadm.models import AccountUser, AccountLocation, Account

class BSBackend(ModelBackend):
    def authenticate(self, username=None, password=None):
        try:
            logging.info('User is trying to auth. Login: %s, Password: %s' % (username, password))
            print 'User is trying to auth. Login: %s, Password: %s' % (username, password)
            
            accountUser = AccountUser.objects.get(login_id__exact=username)

            # check that user is not blocked
            if accountUser.block_access:
                return None

            # checking password
            if accountUser.user_password != password:
                return None

            # checking that user account location is not blocked
            try:
                location = AccountLocation.objects.get(account_location_id__exact=accountUser.primary_location)
                if location.block_access:
                    return None
            except AccountLocation.DoesNotExist:
                return None

            # cheking that user account is not blocked
            if not location.account:
                return None
            account = location.account
            if account.block_access:
                return None

            # checking account expiration date
            if account.expiration_date:
                #"2005-09-30"
                sExp = account.expiration_date
                dExp = date(int(sExp[0:4]), int(sExp[5:7]), int(sExp[8:10]))
                if dExp < date.today():
                    return None

            # checking account is BS_ADMIN
            if account.account_type != 'admin':
                return None

            # get/create django user
            try:
                user = User.objects.get(username__exact=username)
            except User.DoesNotExist:            
                user = User.objects.create_user(username, accountUser.email_address, password)
                user.is_staff = True
                user.is_active = True
                user.is_superuser = True
                user.first_name = accountUser.given_name
                user.last_name = accountUser.family_name
                user.save()
            return user
        except AccountUser.DoesNotExist:
            return None

