#!/usr/bin/python
from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_COMPANY]
    _category = CATEGORY_NETWORK
    _severity = LEVEL_WARNING
    _strId = 'rule_https_enable'

    def getStatus(self):
        self._extra_data = []
        resp = execWebAPI("SYNO.Core.Web.DSM", "get", 1)
        if not resp or not resp["success"]:
            return SZ_ERROR

        if not resp["data"]["enable_https"]:
            self._extra_data.append("_T('service', 'service_secureui')")
            self._extra_data.append("_T('service', 'redirect_secureui')")
            return SZ_FAIL

        if not resp["data"]["enable_https_redirect"]:
            self._extra_data.append("_T('service', 'redirect_secureui')")
            return SZ_FAIL

        return SZ_PASS
    def getMethod(self):
        self._plat = getSynoInfoValue("unique")[0].split('_')[2]
        if 'rt1900ac' == self._plat:
            method = {
                    METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.NSMHome.Instance:SYNO.SDS.NSMHome.Administration.Main:admin_settings'
            }
        else:
            method = {
                    METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.Network.Main:DSMSettingTab'
            }
        return method

    def getAction(self):
        if not self._extra_data:
            return {}
        if 'rt1900ac' == self._plat:
            action = {
                ACTION_STR_KEY: 'action',
                ACTION_REPLACE_VAR: {
                    '%0': "_T('helptoc', 'router_configure_settings')",
                    '%1': ','.join(self._extra_data)
                }
            }
        else:
            action = {
                ACTION_STR_KEY: 'action',
                ACTION_REPLACE_VAR: {
                    '%0': "_T('tree', 'leaf_dsm')",
                    '%1': ','.join(self._extra_data)
                }
            }
        return action
