#!/usr/bin/python
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_COMPANY]
    _category = CATEGORY_SYSTEM_CHECK
    _severity = LEVEL_WARNING
    _strId = 'rule_ftp_unix_perm'

    def getStatus(self):
        self._extraData = ""
        resp_ftp = execWebAPI("SYNO.Core.FileServ.FTP", "get", 1)
        if not resp_ftp or not resp_ftp["success"]:
            return SZ_ERROR
        resp_sftp = execWebAPI("SYNO.Core.FileServ.FTP.SFTP", "get", 1)
        if not resp_sftp or not resp_sftp["success"]:
            return SZ_ERROR
        if not resp_ftp["data"]["enable_ftp"] and not resp_ftp["data"]["enable_ftps"] and not resp_sftp["data"]["enable"]:
            return SZ_SKIP

        resp = execWebAPI("SYNO.Core.FileServ.FTP.Security", "get", 1)
        if not resp or not resp["success"]:
            return SZ_ERROR
        if resp["data"]["enable_umask"]:
            return SZ_PASS
        self._extraData = "fail"
        return SZ_FAIL

    def getMethod(self):
        self._plat = getSynoInfoValue("unique")[0].split('_')[2]
        if 'rt1900ac' == self._plat:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                    METHOD_ACTION_VAL: 'SYNO.SDS.NSMUSBStorage.Instance:SYNO.SDS.NSMUSBStorage.FileServices.Main:ftp',
                    METHOD_LINK_APP_STR: 'router_usbstorage:usb_storage'}
        else:
            return {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.FileService.Main:ftp'}

    def getAction(self):
        if "" != self._extraData:
            action = {
                ACTION_STR_KEY : 'action',
                ACTION_REPLACE_VAR : {}
            }
            action[ACTION_REPLACE_VAR]['%0'] = "_T('common', 'adv_setting')"
            action[ACTION_REPLACE_VAR]['%1'] = "_T('common', 'apply_default_umask')"
            return action
        return {}

