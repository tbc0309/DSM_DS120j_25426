#!/usr/bin/python
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_NETWORK
    _severity = LEVEL_WARNING
    _strId = 'rule_webdav_http'

    def getStatus(self):
        self._extraData = ""
        resp = execWebAPI("SYNO.Core.FileServ.WebDAV", "get", 1)
        if not resp or not resp["success"]:
            return SZ_ERROR
        if resp["data"]["enable_http"]:
            self._extraData = "fail"
            return SZ_FAIL
        if resp["data"]["enable_https"]:
            return SZ_PASS
        return SZ_SKIP

    def getMethod(self):
        self._plat = getSynoInfoValue("unique")[0].split('_')[2]
        if 'rt1900ac' == self._plat:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.NSMUSBStorage.Instance:SYNO.SDS.NSMUSBStorage.FileServices.Main:webdav',
                    METHOD_LINK_APP_STR: 'router_usbstorage:usb_storage'}
        else:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.FileService.Main:webdav'}

    def getAction(self):
        if "" != self._extraData:
            action = {
                ACTION_STR_KEY : 'action',
                ACTION_REPLACE_VAR : {}
            }
            action[ACTION_REPLACE_VAR]['%0'] = "_T('service','service_webdav')"
            action[ACTION_REPLACE_VAR]['%1'] = "_T('service', 'service_webdav_https')"
            return action
        return {}

