#! /usr/bin/env python
#! coding: utf-8
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *
from datetime import *
import gzip
import sys
sys.path.append('/var/dynlib/securityscan/dbutils')
from dbutils import *
import codecs

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_USERINFO
    _severity = LEVEL_RISK
    _strId = 'rule_password_strength_v2'
    _plat = getSynoInfoValue("unique")[0].split('_')[2]

    def getStatus(self):
        def userAvailCheck(userData):
            '''
                True -> avaiable
                False -> expire or no need to check
            '''

            """We don't check guest"""
            if 'guest' == userData['name']:
                return False

            if userData['expired'] in ('Must Change', 'Password Expired', 'Locked', 'now'):
                # not check the account which cannot login
                return False
            elif "normal" == userData["expired"]:
                return True
            elif (datetime.strptime(userData["expired"], "%Y/%m/%d") + timedelta(days=1)) <= datetime.today():
                return False
            else:
                return True

        """ Check the NTLM hash one by one """
        pwdPath = '%s/User/Password/pwd.list.gz' % (SECURITY_DB_PATH)
        with gzip.open(pwdPath, "rb") as f:
            _top50000_ = f.read()
        _top50000_ = [_.strip() for _ in _top50000_.split("\n") if _.strip()]
        _SMBPASSWD_ = "/etc/samba/private/smbpasswd"

        with SynoCriticalSection() as cs:
            with codecs.open(_SMBPASSWD_, encoding='UTF-8') as f:
                _usr_ = [_ for _ in f.read().split('\n') if _]
                _usr_ = {_.split(":")[0]: _.split(":")[3] for _ in _usr_}

        resp = execWebAPI("SYNO.Core.User", "list", 1, additional=["expired"])
        if not resp or not resp["success"] or not resp["data"]["users"]:
            return SZ_ERROR

        """ Only check non-expire users """
        availUsers = [userData['name'] for userData in resp["data"]["users"] if userAvailCheck(userData)]
        _usr_ = {key : _usr_[key] for key in _usr_ if key in availUsers}

        self.ret = [u for u in _usr_ if _usr_[u] in _top50000_]
        if ([] == self.ret):
            return SZ_PASS
        else:
            return SZ_FAIL

    def getMethod(self):
        if 'rt1900ac' == self._plat:
            method = {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.NSMUSBStorage.Instance:SYNO.SDS.NSMUSBStorage.Privilege.Main:userMain',
                    METHOD_LINK_APP_STR: 'router_usbstorage:usb_storage'}
        else:
            method = {METHOD_ACTION: METHOD_ACTION_LINK, METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.User.Main'}
        return method

    def getAction(self):
        if ([] == self.ret):
            return {}
        else:
            action = {
                ACTION_STR_KEY : 'action',
                ACTION_REPLACE_VAR : {"%0": ", ".join(self.ret)},
                ACTION_EXTRA : {"FAIL_USERS_NUM": len(self.ret)}
            }
        return action

def NTLMPwd(pwd):
    """ Compute the NTLM hash """
    import hashlib, binascii

    ntml = hashlib.new('md4', pwd.encode('utf-16le')).digest()
    return binascii.hexlify(ntml).upper()

