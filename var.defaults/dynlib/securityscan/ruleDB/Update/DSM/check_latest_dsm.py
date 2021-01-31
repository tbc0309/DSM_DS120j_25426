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
    _severity = LEVEL_OUT_OF_DATE
    _strId = "rule_latest_dsm_v2"
    _plat = getSynoInfoValue("unique")[0].split('_')[2]

    def getStatus(self):
        def _changeDefUpdateTime():
            import random, os

            try:
                UPDATE_FILE = "/var/dynlib/securityscan/ruleDB/_UPDATE_SCHE_"
                # Check if there are flag
                if not os.path.isfile(UPDATE_FILE):
                    return

                # Get taskID and check time
                resp = execWebAPI("SYNO.Core.SecurityScan.Conf", "get", 1)
                if not resp or not resp["success"]:
                    return
                taskID = resp["data"]["scheduleTaskId"]
                if -1 == taskID:
                    return

                data = resp["data"]
                if 2 != data["hour"] or 0 != data["minute"] or "1" != data["weekday"]:
                    return

                # Get new random time
                newWeekday = random.randrange(0, 6)
                newHour = random.randrange(1, 5)
                newMinute = random.randrange(0, 59)

                # Set new time back
                j = {}
                j["enableSchedule"] = data["enableSchedule"]
                j["weekday"] = str(newWeekday)
                j["hour"] = newHour
                j["minute"] = newMinute
                j["scheduleTaskId"] = taskID

                resp = execWebAPI("SYNO.Core.SecurityScan.Conf", "set", 1, Input = j)
                os.unlink(UPDATE_FILE)
            except Exception as e:
                SYSLOG(syslog.LOG_ERR, "Failed to update default time %s" % e)

        _changeDefUpdateTime()
        self._extra_data = {}

        resp = execWebAPI("SYNO.Core.Upgrade.Server", "check", 1)

        if not resp:
            return SZ_ERROR

        if not resp["success"]:
            if resp["error"]["code"] == 5214:
                # WEBAPI_CORE_ERR_UPGRADE_CHECK_NEW_DSM => Failed to check new dsm from server
                self._extra_data["reason"] = "cant_check"
                return SZ_PASS
            else:
                return SZ_ERROR

        if not resp["data"]["available"]:
            return SZ_PASS

        self._extra_data["version"] = resp["data"]["version"]
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
        if "reason" in self._extra_data:
            return {ACTION_STR_KEY: self._extra_data["reason"], ACTION_REPLACE_VAR: {}}
        else:
            return {ACTION_STR_KEY: "action", ACTION_REPLACE_VAR: {"@NEW_VERSION@": self._extra_data["version"]}}

# vim:ts=4 sts=4 sw=4 et
