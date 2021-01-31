#!/usr/bin/python
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_SYSTEM_CHECK
    _severity = LEVEL_WARNING
    _strId = 'rule_autoblock_enable'

    def getStatus(self):
        resp = execWebAPI("SYNO.Core.Security.AutoBlock", "get", 1)

        if not resp or not resp["success"]:
            return SZ_ERROR

        return SZ_PASS if resp["data"]["enable"] else SZ_FAIL

    def getMethod(self):
        self._plat = getSynoInfoValue("unique")[0].split('_')[2]
        if 'rt1900ac' == self._plat:
            method = {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.NSMHome.Instance:SYNO.SDS.NSMHome.Security.Main:AutoBlockPanel'}
        else:
            method = {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.Security.Main:AutoBlockTab'}
        return method

    def getAction(self):
        action = {
            ACTION_STR_KEY : 'action',
            ACTION_REPLACE_VAR : {}
        }
        action[ACTION_REPLACE_VAR]['%0'] = "_T('tree', 'leaf_autoblock')"
        action[ACTION_REPLACE_VAR]['%1'] = "_T('autoblock', 'autoblock_enable')"
        return action

# vim:ts=4 sts=4 sw=4 et
