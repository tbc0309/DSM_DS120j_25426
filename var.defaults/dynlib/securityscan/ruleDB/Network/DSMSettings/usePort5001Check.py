#!/usr/bin/python
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *
import sys
sys.path.append('/var/dynlib/securityscan/dbutils')
from dbutils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_COMPANY]
    _category = CATEGORY_NETWORK
    _severity = LEVEL_WARNING
    _strId = 'rule_https_port_v2'
    _plat = getSynoInfoValue("unique")[0].split('_')[2]

    def getStatus(self):
        self._extra_data = ""
        resp = execWebAPI("SYNO.Core.Web.DSM", "get", 1)
        if not resp or not resp["success"]:
            return SZ_ERROR

        if not resp["data"]["enable_https"]:
            return SZ_SKIP

        if 5001 == resp["data"]["https_port"]:
            self._extra_data = "action"
            return SZ_FAIL

        return SZ_PASS

    def getMethod(self):
        if 'rt1900ac' == self._plat:
            method = {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.NSMHome.Instance:SYNO.SDS.NSMHome.Administration.Main:admin_settings'}
        else:
            method = {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.Network.Main:DSMSettingTab'}
        return method

    def getAction(self):
        if not self._extra_data:
            return {}
        if 'rt1900ac' == self._plat:
            return {
                ACTION_STR_KEY: self._extra_data,
                ACTION_REPLACE_VAR: {'%0': "_T('helptoc', 'router_configure_settings')"}
            }
        else:
            return {
                ACTION_STR_KEY: self._extra_data,
                ACTION_REPLACE_VAR: {'%0': "_T('tree', 'leaf_dsm')"}
            }
