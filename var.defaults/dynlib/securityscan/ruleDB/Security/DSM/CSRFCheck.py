#!/usr/bin/python
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *


class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_COMPANY]
    _category = CATEGORY_SYSTEM_CHECK
    _severity = LEVEL_WARNING
    _strId = 'rule_improve_csrf'
    _non_comp_product = ['rt1900ac']

    def getStatus(self):
        resp = execWebAPI("SYNO.Core.Security.DSM", "get", 1)

        if not resp or not resp["success"]:
            return SZ_ERROR

        return SZ_PASS if resp["data"]["enable_csrf_protection"] else SZ_FAIL

    def getMethod(self):
        method = {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.Security.Main:DSMTab'}
        return method

    def getAction(self):
        action = {
            ACTION_STR_KEY : 'action',
            ACTION_REPLACE_VAR : {}
        }
        action[ACTION_REPLACE_VAR]['%0'] = "_T('dsmsetting', 'session_legend')"
        action[ACTION_REPLACE_VAR]['%1'] = "_T('dsmsetting', 'dsm_token')"
        return action
