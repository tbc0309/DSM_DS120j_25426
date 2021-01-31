#!/usr/bin/python
from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_NETWORK
    _severity = LEVEL_RISK
    _strId = 'rule_telnet_enable'
    _non_comp_product = ['rt1900ac']

    def getStatus(self):
        self._extra_data = ""
        resp = execWebAPI("SYNO.Core.Terminal", "get", 2)
        if not resp or not resp["success"]:
            return SZ_ERROR

        if resp["data"]["enable_telnet"]:
            self._extra_data = "action"
            return SZ_FAIL

        return SZ_PASS

    def getMethod(self):
        return {METHOD_ACTION: METHOD_ACTION_LINK, METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.TerminalSNMP.Main:terminal'}

    def getAction(self):
        if not self._extra_data:
            return {}
        return {
            ACTION_STR_KEY: self._extra_data
        }

