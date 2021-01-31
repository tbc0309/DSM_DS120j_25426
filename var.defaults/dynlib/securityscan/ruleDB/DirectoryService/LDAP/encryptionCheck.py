#!/usr/bin/python
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_SYSTEM_CHECK
    _severity = LEVEL_WARNING
    _strId = "rule_ldap_encryption"
    _non_comp_product = ['rt1900ac']

    def getStatus(self):
        resp = execWebAPI("SYNO.Core.Directory.LDAP", "get", 1)

        if not resp or not resp["success"]:
            return SZ_ERROR

        if not resp["data"]["enable_client"]:
            return SZ_SKIP

        return SZ_FAIL if resp["data"]["encryption"] == "no" else SZ_PASS

    def getAction(self):
        return {ACTION_STR_KEY: "action", ACTION_REPLACE_VAR: {'%0': "_T('ldap', 'security_type')"}}

    def getMethod(self):
        method = {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.DirectoryService.Main:ldap'}
        return method

# vim:ts=4 sts=4 sw=4 et
