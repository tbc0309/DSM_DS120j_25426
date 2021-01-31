#! /usr/bin/env python2
#! coding: utf-8
# Copyright (c) 2000-2016 Synology Inc. All rights reserved.

from utils import *
from datetime import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_USERINFO
    _severity = LEVEL_WARNING
    _strId = 'rule_check_home_acl'

    def getStatus(self):
        with SynoCriticalSection() as cs:
            result = execute('/usr/syno/sbin/synouserdir --check home all')
        if not result or 0 == len(result[0]):
            return SZ_PASS
        else:
            self.ret = result
            return SZ_FAIL

    def getMethod(self):
        method = {
            METHOD_ACTION: METHOD_ACTION_FIXME,
        }
        return method

    def getAction(self):
        action = {
            ACTION_STR_KEY : 'action',
            ACTION_REPLACE_VAR : {'_USERS_': ', '.join(self.ret)},
        }
        return action

    def fixmeAction(self):
        with SynoCriticalSection() as cs:
            result = execute('/usr/syno/sbin/synouserdir --reset home all')
        return True

