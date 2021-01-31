#!/usr/bin/python
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_NETWORK
    _severity = LEVEL_INFO
    _strId = 'rule_firewall_deny'

    """ please implement the following functions """
    def getStatus(self):
        self._extraData = ""

        result = self.RunCRoutine("FirewallDenyCheck")

        if result["status"] == "success":
            return SZ_PASS
        if result["status"] == "fail":
            self._extraData = "fail"
            return SZ_FAIL
        if result["status"] == "skip":
            return SZ_SKIP
        return SZ_ERROR

    def getMethod(self):
        self._plat = getSynoInfoValue("unique")[0].split('_')[2]
        if 'rt1900ac' == self._plat:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.NSMHome.Instance:SYNO.SDS.NSMHome.Security.Main'}
        else:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.Security.Main'}

    def getAction(self):
        if "" != self._extraData:
            action = {
                ACTION_STR_KEY : 'action',
                ACTION_REPLACE_VAR : {}
            }
            action[ACTION_REPLACE_VAR]['%0'] = "_T('tree', 'leaf_firewall')"
            action[ACTION_REPLACE_VAR]['%1'] = "_T('firewall', 'firewall_no_match_drop')"
            return action
        return {}

