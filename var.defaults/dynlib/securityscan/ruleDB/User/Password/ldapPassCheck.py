# Copyright (c) 2000-2014 Synology Inc. All rights reserved.
from utils import *
from datetime import *
import gzip
import os
import sys
sys.path.append('/var/dynlib/securityscan/dbutils')
from dbutils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_USERINFO
    _severity = LEVEL_RISK
    _strId = 'rule_ldap_password_strength_v2'
    _non_comp_product = ['rt1900ac']

    def getStatus(self):
        if not os.access('/var/packages/DirectoryServer/target/tool/synoldapbrowser', os.X_OK):
            return SZ_SKIP

        """ Get week password list """
        pwdPath = '%s/User/Password/pwd.list.gz' % (SECURITY_DB_PATH)
        with gzip.open(pwdPath, "rb") as f:
            _top50000_ = f.read()
        _top50000_ = [_.strip() for _ in _top50000_.split("\n") if _.strip()]

        cmd = '/var/packages/DirectoryServer/target/tool/synoldapbrowser --dump-nt-hash  2>/dev/null'
        with SynoCriticalSection() as cs:
            result = execute(cmd)
        if not result or 0 == len(result[0]):
            return SZ_SKIP

        _usr_ = {val.split(':')[0]:val.split(':')[1] for val in result}
        self.ret = [u for u in _usr_ if _usr_[u] in _top50000_]
        if ([] == self.ret):
            return SZ_PASS
        else:
            return SZ_FAIL

    def getMethod(self):
        method = {
            METHOD_ACTION: METHOD_ACTION_LINK,
            METHOD_ACTION_VAL: 'SYNO.SDS.LDAP.AppInstance:SYNO.SDS.LDAP.AppWindow',
            METHOD_LINK_APP_STR: 'ldap:syno_server'
        }
        return method

    def getAction(self):
        if ([] == self.ret):
            return {}
        else:
            action = {
                ACTION_STR_KEY : 'action',
                ACTION_REPLACE_VAR : {"__USERS__": ", ".join(self.ret)},
                ACTION_EXTRA : {"FAIL_USERS_NUM": len(self.ret)}
            }
        return action
def NTLMPwd(pwd):
    """ Compute the NTLM hash """
    import hashlib, binascii

    ntml = hashlib.new('md4', pwd.encode('utf-16le')).digest()
    return binascii.hexlify(ntml).upper()

