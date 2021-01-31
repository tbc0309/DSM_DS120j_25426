#!/usr/bin/python
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *
import json
import os

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_UPDATE
    _severity = LEVEL_OUT_OF_DATE
    _strId = "rule_latest_pkg"

    def getStatus(self):
        self._extra_data = {}

        if not os.access("/usr/syno/bin/synopkg", os.X_OK):
            SYSLOG(syslog.LOG_ERR, "Cannot find /usr/syno/bin/synopkg so skip check package version")
            return SZ_SKIP

        cmd = "/usr/syno/bin/synopkg checkupdateall"
        result = execute(cmd, False)
        result = json.loads(result)

        if not result:
            return SZ_PASS
        else:
            self._extra_data["packages"] = [i["name"] for i in result]
            return SZ_FAIL
    def getMethod(self):
        return {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: "SYNO.SDS.PkgManApp.Instance:Ext.emptyFn",
                METHOD_LINK_APP_STR: 'tree:leaf_packagemanage'
        }

    def getAction(self):
        if not self._extra_data:
            return {}
        return {
            ACTION_STR_KEY: "action",
            ACTION_REPLACE_VAR: {"@PKG_NAME@": ", ".join(self._extra_data["packages"])},
            ACTION_EXTRA: {"FAIL_PACKAGES_NUM": len(self._extra_data["packages"])}
        }

# vim:ts=4 sts=4 sw=4 et
