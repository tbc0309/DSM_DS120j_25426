#!/usr/bin/python
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_COMPANY]
    _category = CATEGORY_SYSTEM_CHECK
    _severity = LEVEL_WARNING
    _strId = 'rule_snmp_community'

    def getStatus(self):
        self._extraData = ""
        resp = execWebAPI("SYNO.Core.SNMP", "get", 1)
        if not resp or not resp["success"]:
            return SZ_ERROR
        if not resp["data"]["enable_snmp"] or not resp["data"]["enable_snmp_v1v2"]:
            return SZ_SKIP
        if "public" == resp["data"]["rocommunity"]:
            self._extraData = "fail"
            return SZ_FAIL
        return SZ_PASS

    def getMethod(self):
        self._plat = getSynoInfoValue("unique")[0].split('_')[2]
        if 'rt1900ac' == self._plat:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.NSMHome.Instance:SYNO.SDS.NSMHome.Administration.Main:admin_service'}
        else:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.TerminalSNMP.Main:snmp'}

    def getAction(self):
        if "" != self._extraData:
            action = {
                ACTION_STR_KEY : 'action',
                ACTION_REPLACE_VAR : {}
            }
            action[ACTION_REPLACE_VAR]['%0'] = "_T('snmp', 'snmp_rocommunity')"
            return action
        return {}

