#!/usr/bin/python
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_COMPANY]
    _category = CATEGORY_SYSTEM_CHECK
    _severity = LEVEL_WARNING
    _strId = 'rule_domain_signing'
    _non_comp_product = ['eds14', 'rt1900ac']

    """ please implement the following functions """
    def getStatus(self):
        self._extraData = ""
        resp = execWebAPI("SYNO.Core.Directory.Domain", "get", 1)
        if not resp or not resp["success"]:
            return SZ_ERROR
        if not resp["data"]["enable_domain"]:
            return SZ_SKIP

        resp = execWebAPI("SYNO.Core.Directory.Domain.Conf", "get", 2)
        if not resp or not resp["success"]:
            return SZ_ERROR
        if resp["data"]["enable_server_signing"]:
            return SZ_PASS
        self._extraData = "fail"
        return SZ_FAIL

    def getMethod(self):
        return {METHOD_ACTION: METHOD_ACTION_LINK,
                METHOD_ACTION_VAL: 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.DirectoryService.Main:domain'}

    def getAction(self):
        if "" != self._extraData:
            action = {
                ACTION_STR_KEY : 'action',
                ACTION_REPLACE_VAR : {}
            }
            action[ACTION_REPLACE_VAR]['%1'] = "_T('domain', 'enable_domain_server_signing')"
            action[ACTION_REPLACE_VAR]['%0'] = "_T('network', 'domain_options')"
            return action
        return {}

