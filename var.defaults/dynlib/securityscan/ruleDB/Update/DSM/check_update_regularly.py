#! /usr/bin/env python
#! coding: utf-8
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *
import sys
sys.path.append('/var/dynlib/securityscan/dbutils')
from dbutils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_UPDATE
    _severity = LEVEL_INFO
    _strId = "rule_check_update_regularly_v2"
    _plat = getSynoInfoValue("unique")[0].split('_')[2]

    def getStatus(self):
        self._extra_data = {}
        resp = execWebAPI("SYNO.Core.Upgrade.Setting", "get", 1)
        if not resp or not resp["success"]:
            return SZ_ERROR
        if resp["data"]["auto_download"]:
            return SZ_PASS
        self._extra_data["action"] = "action"
        return SZ_FAIL

    def getMethod(self):
        if 'rt1900ac' == self._plat:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: "SYNO.SDS.NSMHome.Instance:SYNO.SDS.NSMHome.Administration.Main:admin_update_restore"}
        else:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: "SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.Update_Reset.Main"}

    def getAction(self):
        if not self._extra_data:
            return {}
        action = {
            ACTION_STR_KEY : self._extra_data["action"],
            ACTION_REPLACE_VAR : {}
        }
        action[ACTION_REPLACE_VAR]['%0'] = "_T('update', 'update_adv_setting')"
        action[ACTION_REPLACE_VAR]['%1'] = "_T('update', 'autoupdate')"
        return action

