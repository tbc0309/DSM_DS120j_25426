#!/usr/bin/python
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
    _strId = 'rule_notify_download_ready_v2'
    _plat = getSynoInfoValue("unique")[0].split('_')[2]

    def getStatus(self):
        self._extra_data = {}
        self._extra_data["reason"] = ""

        resp = execWebAPI("SYNO.Core.Notification.Mail.Conf", "get", 1)
        if not resp or not resp["success"]:
            return SZ_ERROR
        if not resp["data"]["enable_mail"]:
            self._extra_data["reason"] = "basic"  # notification itself not enabled
            return SZ_FAIL

        resp = execWebAPI("SYNO.Core.Notification.Advance.FilterSettings", "list", 1)
        if not resp or not resp["success"]:
            return SZ_ERROR
        match = filter(lambda s: s["name"] == "DSMUpdateAvailable", resp["data"]["All"])
        if match == [] or not match[0]["mail"]:
            self._extra_data["reason"] = "advance"  # mail for download-ready event not enabled
            return SZ_FAIL
        return SZ_PASS

    def getMethod(self):
        if 'rt1900ac' == self._plat:
            if self._extra_data["reason"] == "advance":
                return {METHOD_ACTION: METHOD_ACTION_LINK,
                        METHOD_ACTION_VAL: "SYNO.SDS.NSMHome.Instance:SYNO.SDS.NSMHome.Notification.Main:filterTab"}
            else:
                return {METHOD_ACTION: METHOD_ACTION_LINK,
                        METHOD_ACTION_VAL: "SYNO.SDS.NSMHome.Instance:SYNO.SDS.NSMHome.Notification.Main:mailSettingTab"}
        else:
            if self._extra_data["reason"] == "advance":
                return {METHOD_ACTION: METHOD_ACTION_LINK,
                        METHOD_ACTION_VAL: "SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.Notification.Main:filterTab"}
            else:
                return {METHOD_ACTION: METHOD_ACTION_LINK,
                        METHOD_ACTION_VAL: "SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.Notification.Main:mailSettingTab"}

    def getAction(self):
        if not self._extra_data:
            return {}
        return {ACTION_STR_KEY: self._extra_data["reason"]}

# vim:ts=4 sts=4 sw=4 et
