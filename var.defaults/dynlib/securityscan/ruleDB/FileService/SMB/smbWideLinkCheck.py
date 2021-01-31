#!/usr/bin/python
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_COMPANY]
    _category = CATEGORY_SYSTEM_CHECK
    _severity = LEVEL_INFO
    _strId = 'rule_smb_widelink'

    def getStatus(self):
        self._extraData = ""
        resp = execWebAPI("SYNO.Core.FileServ.SMB", "get", 1)
        if not resp or not resp["success"]:
            return SZ_ERROR
        if not resp["data"]["enable_samba"]:
            return SZ_SKIP
        if not resp["data"]["enable_widelink"]:
            return SZ_PASS
        self._extraData = "fail"
        return SZ_FAIL

    def getMethod(self):
        self._plat = getSynoInfoValue("unique")[0].split('_')[2]
        if 'rt1900ac' == self._plat:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.NSMUSBStorage.Instance:SYNO.SDS.NSMUSBStorage.FileServices.Main:win',
                    METHOD_LINK_APP_STR: 'router_usbstorage:usb_storage'}
        else:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.FileService.Main:win'}

    def getAction(self):
        if "" != self._extraData:
            action = {
                ACTION_STR_KEY : 'action',
                ACTION_REPLACE_VAR : {}
            }
            action[ACTION_REPLACE_VAR]['%0'] = "_T('network', 'wnds_file_service')"
            action[ACTION_REPLACE_VAR]['%1'] = "_T('common', 'adv_setting')"
            action[ACTION_REPLACE_VAR]['%2'] = "_T('network', 'smb_enable_widelink')"
            return action
        return {}

