# -*- coding: utf-8 -*-
from __future__ import absolute_import
import json

from django.conf import settings
from django_auth_ldap.backend import LDAPBackend
from django_cas_ng.backends import CASBackend
from josepy.jws import JWS
from mozilla_django_oidc.auth import OIDCAuthenticationBackend
from shibboleth.backends import ShibbolethRemoteUserBackend

from components.helpers import generate_api_key


class CustomShibbolethRemoteUserBackend(ShibbolethRemoteUserBackend):
    def configure_user(self, user):
        generate_api_key(user)
        return user


class CustomCASBackend(CASBackend):
    def configure_user(self, user):
        generate_api_key(user)
        # If CAS_AUTOCONFIGURE_EMAIL and CAS_EMAIL_DOMAIN settings are
        # configured, add an email address for this user, using rule
        # username@domain.
        if settings.CAS_AUTOCONFIGURE_EMAIL and settings.CAS_EMAIL_DOMAIN:
            user.email = "{0}@{1}".format(user.username, settings.CAS_EMAIL_DOMAIN)
            user.save()
        return user


class CustomLDAPBackend(LDAPBackend):
    """Append a usernamed suffix to LDAP users, if configured"""

    def ldap_to_django_username(self, username):
        return username.rstrip(settings.AUTH_LDAP_USERNAME_SUFFIX)

    def django_to_ldap_username(self, username):
        return username + settings.AUTH_LDAP_USERNAME_SUFFIX


class CustomOIDCBackend(OIDCAuthenticationBackend):
    """
    Provide OpenID Connect authentication
    """

    def get_userinfo(self, access_token, id_token, verified_id):
        """
        Extract user details from JSON web tokens
        These map to fields on the user field.
        """
        access_info = json.loads(JWS.from_compact(access_token.encode('utf8')).payload.decode("utf-8"))

        info = {'email': access_info['upn']}

        return info

    def create_user(self, user_info):
        # We want to explicitly gate the creation of users here --
        # don't just create a user because OIDC has told us who they are.
        #
        # OIDC is an *identity* service, not an *authorisation* service.
        # It call tell us "this person is Henry Wellcome", not "Henry Wellcome
        # should have Archivematica access".
        #
        # Using `get_or_create_user()` instead of `create_user()` means we
        # can control the creation of users with `OIDC_CREATE_USER`.
        user = super(CustomOIDCBackend, self).get_or_create_user(user_info)

        if user is not None:
            for attr, value in user_info.items():
                setattr(user, attr, value)
            user.save()
            generate_api_key(user)
            return user
