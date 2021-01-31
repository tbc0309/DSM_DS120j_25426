#!/usr/bin/python
from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_SYSTEM_CHECK
    _severity = LEVEL_WARNING
    _strId = 'rule_nfs_wildcard_ip'

    def getStatus(self):
        self._extra_data = []

        resp = execWebAPI("SYNO.Core.FileServ.NFS", "get", 2)
        if not resp or not resp["success"] or not resp["data"]:
            SYSLOG(syslog.LOG_ERR, "Failed to exec webapi")
            return SZ_ERROR
        if not resp["data"]["enable_nfs"]:
            return SZ_SKIP

        sharesResp = execWebAPI("SYNO.Core.Share", "list", 1)
        if not sharesResp or not sharesResp["success"]:
            return SZ_ERROR

        for share in sharesResp["data"]["shares"]:
            shareName = share["name"]
            nfsResp = execWebAPI("SYNO.Core.FileServ.NFS.SharePrivilege", "load", 1, share_name=shareName)
            if not nfsResp or not nfsResp["success"]:
                return SZ_ERROR

            for rule in nfsResp["data"]["rule"]:
                if "*" == rule["client"]:
                    self._extra_data.append(shareName)

        if not self._extra_data:
            return SZ_PASS
        else:
            return SZ_FAIL

    def getMethod(self):
        self._plat = getSynoInfoValue("unique")[0].split('_')[2]
        if 'rt1900ac' == self._plat:
            method = {
                METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: 'SYNO.SDS.NSMUSBStorage.Instance:SYNO.SDS.NSMUSBStorage.Privilege.Main',
                METHOD_LINK_APP_STR: 'router_usbstorage:usb_storage'
            }
        else:
            method = {
                METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.Share.Main'
            }
        return method

    def getAction(self):
        if not self._extra_data: return {}

        action = {
            ACTION_STR_KEY : 'action',
            ACTION_REPLACE_VAR : {
                '%0': ','.join(self._extra_data)
            }
        }
        return action

    def fixmeAction(self):
        return True
