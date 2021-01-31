#! /usr/bin/env python
#! coding: utf-8
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *
from datetime import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_COMPANY]
    _category = CATEGORY_USERINFO
    _severity = LEVEL_WARNING
    _strId = "rule_disable_guest"

    def getStatus(self):
        self._extra_data = {}
        resp = execWebAPI("SYNO.Core.User", "get", 1, name="guest", additional=["expired"])
        if not resp or not resp["success"] or not resp["data"]["users"]:
            return SZ_ERROR
        try:
            if "now" == resp["data"]["users"][0]["expired"]:
                return SZ_PASS
            elif "normal" == resp["data"]["users"][0]["expired"]:
                self._extra_data["action"] = "action"
                return SZ_FAIL
            elif (datetime.strptime(resp["data"]["users"][0]["expired"], "%Y/%m/%d")+timedelta(days=1)) <= datetime.today():
                return SZ_PASS
            else:
                self._extra_data["action"] = "action"
                return SZ_FAIL
        except Exception as e:
            SYSLOG(syslog.LOG_ERR, "Fail to check diable_guest %s " % e)
            return SZ_ERROR

    def getMethod(self):
        self._plat = getSynoInfoValue("unique")[0].split('_')[2]
        if 'rt1900ac' == self._plat:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: "SYNO.SDS.NSMUSBStorage.Instance:SYNO.SDS.NSMUSBStorage.Privilege.Main:userMain",
                    METHOD_LINK_APP_STR: 'router_usbstorage:usb_storage'}
        else:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: "SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.User.Main"}

    def getAction(self):
        if not self._extra_data:
            return {}
        return {
            ACTION_STR_KEY: self._extra_data["action"],
            ACTION_REPLACE_VAR: {
                '%0': "_T('tree', 'leaf_user')"
            }
        }

