#!/usr/bin/python
#! coding: utf-8
# Copyright (c) 2000-2017 Synology Inc. All rights reserved.

from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = ['6.0', '6.1']
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_USERINFO
    _severity = LEVEL_DANGER
    _strId = 'rule_check_shadow_integrity'

    """ please implement the following functions """
    def getStatus(self):
        ret = self.RunCRoutine("UserCheck")
        self._pass_ = ret["status"] == "success"
        self._vars_ = ret["var"]

        return StrMap[ret["status"]]

    def getMethod(self):
        #TODO: Prevent user contact support
        method = {
            METHOD_ACTION: METHOD_ACTION_LINK,
            METHOD_ACTION_VAL: 'SYNO.SDS.SupportForm.Application:SYNO.SDS.SupportForm.Application',
            METHOD_LINK_APP_STR: 'helptoc:support_center'
        }
        return method

    def getAction(self):
        if self._pass_:
            return {}
        else:
            action = {
                ACTION_STR_KEY : 'action',
                ACTION_REPLACE_VAR : self._vars_
            }
            return action
