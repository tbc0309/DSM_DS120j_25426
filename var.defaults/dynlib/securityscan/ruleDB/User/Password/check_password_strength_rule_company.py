#! /usr/bin/env python
#! coding: utf-8
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *


class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_COMPANY]
    _category = CATEGORY_USERINFO
    _severity = LEVEL_WARNING
    _strId = "rule_check_password_strengh_rule_company"

    def getStatus(self):
        self._extra_data = {}
        self._extra_data["rules"] = []
        resp = execWebAPI("SYNO.Core.User.PasswordPolicy", "get", 1)
        if not resp or not resp["success"]:
            return SZ_ERROR

        if ("exclude_username" not in resp["data"]["strong_password"]
            or not resp["data"]["strong_password"]["exclude_username"]):
            self._extra_data["rules"].append("_T('passwd', 'exclude_username')")
        if ("mixed_case" not in resp["data"]["strong_password"]
            or not resp["data"]["strong_password"]["mixed_case"]):
            self._extra_data["rules"].append("_T('passwd', 'mixed_case')")
        if ("included_numeric_char" not in resp["data"]["strong_password"]
            or not resp["data"]["strong_password"]["included_numeric_char"]):
            self._extra_data["rules"].append("_T('passwd', 'included_numeric_char')")
        if ("included_special_char" not in resp["data"]["strong_password"]
            or not resp["data"]["strong_password"]["included_special_char"]):
            self._extra_data["rules"].append("_T('passwd', 'included_special_char')")
        if ("min_length_enable" not in resp["data"]["strong_password"]
            or not resp["data"]["strong_password"]["min_length_enable"]):
            self._extra_data["rules"].append("_T('passwd', 'min_length_enable')")
        if [] == self._extra_data["rules"]:
            return SZ_PASS
        else:
            self._extra_data["action"]="action"
            return SZ_FAIL

    def getMethod(self):
        self._plat = getSynoInfoValue("unique")[0].split('_')[2]
        if 'rt1900ac' == self._plat:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: "SYNO.SDS.NSMUSBStorage.Instance:SYNO.SDS.NSMUSBStorage.Privilege.Main:userOption",
                    METHOD_LINK_APP_STR: 'router_usbstorage:usb_storage'}
        else:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: "SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.User.Main:option_tab"}

    def getAction(self):
        if ([] != self._extra_data["rules"]):
            action = {
                ACTION_STR_KEY : self._extra_data["action"],
                ACTION_REPLACE_VAR : {},
                ACTION_EXTRA: {}
            }
            action[ACTION_REPLACE_VAR]['%0'] = "_T('tree', 'leaf_user')"
            action[ACTION_REPLACE_VAR]['%1'] = "_T('common', 'advanced')"
            action[ACTION_REPLACE_VAR]['%2'] = ", ".join(self._extra_data["rules"])

            action[ACTION_EXTRA]['FAIL_OPTION_NUM'] = len(self._extra_data["rules"])
            return action
        else:
            return {}

