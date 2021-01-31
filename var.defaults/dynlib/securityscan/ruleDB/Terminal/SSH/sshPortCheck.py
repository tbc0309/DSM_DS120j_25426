#!/usr/bin/python
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_NETWORK
    _severity = LEVEL_RISK
    _strId = 'rule_ssh_port'

    def getStatus(self):
        self._extra_data = {}
        resp = execWebAPI("SYNO.Core.Terminal", "get", 2)
        if not resp or not resp["success"]:
            return SZ_ERROR
        if not resp["data"]["enable_ssh"]:
            return SZ_SKIP
        if 22 == resp["data"]["ssh_port"]:
            return SZ_FAIL
        return SZ_PASS

    def getMethod(self):
        self._plat = getSynoInfoValue("unique")[0].split('_')[2]
        if 'rt1900ac' == self._plat:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.NSMHome.Instance:SYNO.SDS.NSMHome.Administration.Main:admin_service'}
        else:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.TerminalSNMP.Main'}

    def getAction(self):
        return {ACTION_STR_KEY: "action"}

