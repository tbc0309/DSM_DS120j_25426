# Copyright (c) 2000-2016 Synology Inc. All rights reserved.

from utils import *
from FuncAPI import *
import urllib
import json

class Dispatcher(object):
    def __init__(self, args, debug=False):
        try:
            ## Entry point from CGI
            if "StartScan" == args.action:
                startTimeSet()
                rules = scanItemsEnum(args.rules)
                self.start(rules, args.notify)
            elif "SysStatusQuery" == args.action:
                self.sysStatus()
            elif "StatusQuery" == args.action:
                rules = scanItemsEnum(args.rules)
                self.status(rules)
            elif "StopScan" == args.action:
                self.stop()
            elif "ConfSave" == args.action:
                self.confSave(args)
            elif "ConfLoad" == args.action:
                self.confLoad()
            elif "CustomListSave" == args.action:
                rules = scanItemsEnum(args.rules)
                self.customListSave(rules)
            elif "ListEnum" == args.action:
                self.listEnum(args)
            elif "DBVersionCheck" == args.action:
                self.update(False)
            elif "DBUpdate" == args.action:
                self.update(True)
            elif "Info" == args.action:
                self.info()
            elif "FixmeAction" == args.action:
                rules = scanItemsEnum(args.rules)
                self.fixmeAction(rules)
            elif "FirstScan" == args.action:
                self.firstScan()
            elif "CurrentTimeGet" == args.action:
                self.currentTimeGet()
            elif "dangerSet" == args.action:
                self.dangerSet()
            else:
                SYSLOG(syslog.LOG_ERR, "Bad request %s" % args.action)
        except Exception as e:
            SYSLOG(syslog.LOG_ERR, "Failed to exec dispatcher() Error: %s" % e)
            if debug:
                raise

    def start(self, rules, blNotify):
        from subprocess import Popen
        from time import sleep

        resp = {}
        sk = domainSocket()
        counter = 0

        try:
            ## Check the main scanner is running or not. if not, wake up
            if not isMainPyAlive():
                if not checksumGen():
                    setErrInfo(resp, 'securityscan', 'framwork_modified_error')
                    resp[RETURN_SUCCESS_KEY] = False
                    sysStatusDangerSet()
                    sys.stdout.write(json.dumps(resp))
                    return

                with open('/dev/null') as null_f:
                    Popen(['python', RULE_RUNNER_PATH], stdout=null_f, stderr=null_f, stdin=null_f)

            sk.clientConnect(maxRetry = 30, timeGap = 0.5, blExcept = False)

            if 1 == blNotify:
                blNotify = True
            else:
                blNotify = False

            cmd = {
                "action": "start",
                "itemIDs": rules,
                "blNotify": blNotify
            }
            sk.objSend(cmd)

            # Wait for ACK
            sk.recv(BUFSIZ)
            sk.close()

            ## check time
            if not checkTime():
                setErrInfo(resp, 'error', 'error_system_time')
                resp[RETURN_SUCCESS_KEY] = False
            else:
                resp[RETURN_SUCCESS_KEY] = True
        except Exception as e:
            resp[RETURN_SUCCESS_KEY] = False
            SYSLOG(syslog.LOG_ERR, 'Failed to scan Error: %s' % e)

        sys.stdout.write(json.dumps(resp))

    def sysStatus(self):
        '''
        resp = {
            'items',
            'lastScanTime',
            'startTime',
            'success',
            'sysStatus',
            'sysProgress'
        }
        '''
        resp = {}
        blDone = False

        cmd = {
            "action": "sysStatus"
        }
        sysItems = {}
        try:
            if isUpdating():
                resp[RETURN_SYSTEM_STATUS] = SYSTEM_STATUS_UPDATING
            else:
                blConnected = False
                sysSettings = {}
                sysSettings = getSysSettings()
                sk = domainSocket()
                if isMainPyAlive():
                    try:
                        sk.clientConnect()
                        sk.objSend(cmd)
                        ## recv json Data
                        obj = sk.objRecv()
                        sysItems = json.loads(obj)
                        sk.close()
                        blConnected = True
                    except Exception as e:
                        blConnected = False

                ## If _RuleRunner is dead or cannot connect to _RuleRunner and then load old data
                if not blConnected:
                    if os.path.exists(START_TIME_TMP):
                        os.unlink(START_TIME_TMP)

                    if sysSettings.has_key(CONFIG_LAST_SCAN_ALL_TIME):
                        resp[RETURN_SYSTEM_LAST_SCAN] = sysSettings[CONFIG_LAST_SCAN_ALL_TIME]
                    else:
                        resp[RETURN_SYSTEM_LAST_SCAN] = ''


                if not sysItems:
                    retItems, sysStatus, sysProgress = sysResultGet(sysSettings)
                    resp[RETURN_SYSTEM_STATUS] = sysStatus
                    resp[RETURN_SYSTEM_PROGRESS] = sysProgress
                    resp[RETURN_JSON_KEY] = retItems
                else:
                    resp[RETURN_SYSTEM_STATUS] = sysItems['sysStatus']
                    resp[RETURN_SYSTEM_PROGRESS] = sysItems['sysProgress']
                    resp[RETURN_JSON_KEY] = sysItems['categoryItems']

            resp[RETURN_START_TIME] = startTimeGet()
            resp[RETURN_SUCCESS_KEY] = True
        except Exception as e:
            SYSLOG(syslog.LOG_ERR, "Failed to sysStatus() Error: %s" % e);
            resp[RETURN_SUCCESS_KEY] = False
            trace = traceback.format_exc()
            tracelog(trace)

        sys.stdout.write(json.dumps(resp, indent=4))

    def status(self, rules):
        data = dict()
        resp = {}
        historyData = {}

        if not isUpdating():
            historyData = itemDataGet(rules)
            resp[RETURN_UPDATING] = False
        else:
            resp[RETURN_UPDATING] = True

        if False == historyData:
            resp[RETURN_SUCCESS_KEY] = False
        else:
            ## set data
            for itemID in rules.split():
                if historyData.has_key(itemID):
                    data[itemID] = historyData[itemID]
                else:
                    itemSet(data, defaultItemGet(itemID))
            resp[RETURN_SUCCESS_KEY] = True

        if data:
            resp[RETURN_JSON_KEY] = data
        else:
            resp[RETURN_JSON_KEY] = ''

        sys.stdout.write(json.dumps(resp))

    def stop(self):
        from time import sleep
        import signal
        import os
        resp = {}

        if isMainPyAlive():
            with open(MAIN_SCANNER_PIDFILE) as f:
                mainPypid = f.read()
                mainPypid = int(mainPypid)

            os.kill(mainPypid, signal.SIGUSR1)

            for counter in range(10):
                if not isMainPyAlive():
                    break
                sleep(1)
            else:
                os.kill(mainPypid, signal.SIGKILL)

        resp[RETURN_SUCCESS_KEY] = True
        sys.stdout.write(json.dumps(resp))

    def confSave(self, args):
        import shutil, os
        resp = {}

        try:
            sysSettings = getSysSettings()
            argGroup = args.argGroup
            updateBeforeScan = args.updateBeforeScan
            checkRunning = False

            if GROUP_HOME == argGroup or GROUP_CUSTOM == argGroup or GROUP_COMPANY == argGroup:
                sysSettings[CONFIG_DEF_GROUP_KEY] = argGroup
                checkRunning = True

            if GROUP_CUSTOM == argGroup and not os.path.exists(CUSTOM_LIST_FILE):
                setErrInfo(resp, 'securityscan', 'securityscan_alert_non_items')
                resp[RETURN_SUCCESS_KEY] = False
            else:
                if 1 == updateBeforeScan:
                    sysSettings[CONFIG_UPDATE_KEY] = True
                    checkRunning = True
                elif 0 == updateBeforeScan:
                    sysSettings[CONFIG_UPDATE_KEY] = False
                    checkRunning = True

                if args.taskId:
                    sysSettings[CONFIG_SCHEDULE][CONFIG_SCHEDULE_TASKID] = args.taskId

                if checkRunning and isMainPyAlive():
                    setErrInfo(resp, 'securityscan', 'securityscan_error_is_scanning')
                    resp[RETURN_SUCCESS_KEY] = False
                else:
                    with open(SYSTEM_SETTING_FILE_TMP, "w") as f:
                        f.write(json.dumps(sysSettings, sort_keys=True, indent=4))
                    with SynoCriticalSection() as cs:
                        shutil.move(SYSTEM_SETTING_FILE_TMP, SYSTEM_SETTING_FILE)

                    resp[RETURN_SUCCESS_KEY] = True
        except Exception as e:
            SYSLOG(syslog.LOG_ERR, "Fail to save config default group:%s updateBeforeScan:%s Error: %s" % (argGroup, updateBeforeScan, e))
            resp[RETURN_SUCCESS_KEY] = False

        sys.stdout.write(json.dumps(resp))

    def confLoad(self):
        resp = {}

        try:
            sysSettings = getSysSettings()
            resp[CONFIG_DEF_GROUP_KEY] = sysSettings[CONFIG_DEF_GROUP_KEY]
            resp[CONFIG_UPDATE_KEY] = sysSettings[CONFIG_UPDATE_KEY]
            if sysSettings[CONFIG_SCHEDULE].has_key(CONFIG_SCHEDULE_TASKID):
                resp[CONFIG_SCHEDULE_TASKID] = sysSettings[CONFIG_SCHEDULE][CONFIG_SCHEDULE_TASKID]
            else:
                resp[CONFIG_SCHEDULE_TASKID] = -1

            resp[RETURN_SUCCESS_KEY] = True
        except:
            SYSLOG(syslog.LOG_ERR, "Fail to load config")
            resp[RETURN_SUCCESS_KEY] = False

        sys.stdout.write(json.dumps(resp))

    def customListSave(self, rules):
        import shutil
        resp = {}

        if not rules:
            setErrInfo(resp, 'securityscan', 'securityscan_alert_non_items')
            resp[RETURN_SUCCESS_KEY] = False
        elif isMainPyAlive():
            setErrInfo(resp, 'securityscan', 'securityscan_error_is_scanning')
            resp[RETURN_SUCCESS_KEY] = False
        else:
            try:
                with open(CUSTOM_LIST_FILE_TMP, "w") as f:
                    f.write(rules)

                shutil.move(CUSTOM_LIST_FILE_TMP, CUSTOM_LIST_FILE)

                ## Re-calculate system status
                ## FIXME: this can be replace with rules directly?
                rules = scanItemsEnum([ITEMS_ALL])
                currentData = itemDataGet(rules)
                sysStatusCalculate(currentData, rules)

                resp[RETURN_SUCCESS_KEY] = True
            except Exception as err:
                SYSLOG(syslog.LOG_ERR, "Fail to save custom list Error: %s" % err)
                resp[RETURN_SUCCESS_KEY] = False

        sys.stdout.write(json.dumps(resp))

    def listEnum(self, args):
        import os
        resp = {}

        if not args.argGroup:
            resp[RETURN_SUCCESS_KEY] = False
            sys.stdout.write(json.dumps(resp))
            return

        try:
            selectedListStore = []
            selectedList = ""
            historyData = {}
            group = args.argGroup

            ## All items
            items = enumItems()
            ## selected items
            selectedList = enumItems(group)

            for item in items:
                data = {}
                if historyData.has_key(item):
                    data = historyData[item]
                else:
                    data = defaultItemGet(item)
                    if not data:
                        continue

                if item in selectedList:
                    data['enabled'] = True
                else:
                    data['enabled'] = False

                selectedListStore.append(data)

            resp[RETURN_JSON_KEY] = selectedListStore
            resp[RETURN_SUCCESS_KEY] = True
        except Exception as e:
            SYSLOG(syslog.LOG_ERR, "Error: %s" % e)
            resp[RETURN_SUCCESS_KEY] = False

        sys.stdout.write(json.dumps(resp))

    def info(self):
        items = enumItems(runableCheck = False)
        for _key in items:
            print 'RuleID: '+ _key

    def update(self, blUpdate):
        '''
            Arguments:
                blUpdate:
                    true -> update
                    false -> check version is latest
        '''
        resp = {}

        resp[RETURN_UPDATING] = False
        resp[RETURN_SUCCESS_KEY] = True
        try:
            latestVer, curVer, needToUpdate = updateCheck()
            resp[RETURN_UPDATING] = isUpdating()
            if 0 == latestVer and 0 == curVer:
                resp[RETURN_SUCCESS_KEY] = False
                setErrInfo(resp, 'securityscan', 'securityscan_error_update')
            else:
                if resp[RETURN_UPDATING] or not needToUpdate:
                    resp[RETURN_CURRENT_VERSION] = curVer
                    resp[RETURN_LATEST_VERSION] = latestVer

                elif needToUpdate and not resp[RETURN_UPDATING]:
                    if (True == blUpdate):
                        with SynoCriticalSection() as cs:
                            with open(MAIN_UPDATE_PIDFILE, "w") as f:
                                f.write("%s" %os.getpid())
                        try:
                            if not updateSecurityDB(latestVer):
                                resp[RETURN_SUCCESS_KEY] = False
                                setErrInfo(resp, 'securityscan', 'securityscan_error_update')
                                SYSLOG(syslog.LOG_ERR, 'Failed to updateSecurityDB() but still running')
                        except Exception as e:
                            SYSLOG(syslog.LOG_ERR, "Failed to updateSecurityDB %s" % e)
                        finally:
                            if os.path.isfile(MAIN_UPDATE_PIDFILE):
                                with SynoCriticalSection() as cs:
                                    os.unlink(MAIN_UPDATE_PIDFILE)

                    resp[RETURN_CURRENT_VERSION] = curVer
                    resp[RETURN_LATEST_VERSION] = latestVer

                else:
                    SYSLOG(syslog.LOG_ERR, "Failed to updateCheck()")

            sys.stdout.write(json.dumps(resp))
        except Exception as e:
            SYSLOG(syslog.LOG_ERR, "Failed to update Error: %s " % e)
            trace = traceback.format_exc()
            tracelog(trace)

            resp[RETURN_SUCCESS_KEY] = False
            sys.stdout.write(json.dumps(resp))

    def fixmeAction(self, rules):
        from subprocess import Popen
        from time import sleep

        resp = {}
        counter = 0

        try:
            rules = filterItemsWithFixmeAction(rules)
            ## There are no fixme items
            if not rules:
                resp[RETURN_SUCCESS_KEY] = True
                sys.stdout.write(json.dumps(resp))
                return

            ## Check the main scanner is running or not. if not, wake up
            if not isMainPyAlive():
                if not checksumGen():
                    setErrInfo(resp, 'securityscan', 'framwork_modified_error')
                    resp[RETURN_SUCCESS_KEY] = False
                    sysStatusDangerSet()
                    sys.stdout.write(json.dumps(resp))
                    return
                with open('/dev/null') as null_f:
                    Popen(['python', RULE_RUNNER_PATH], stdout=null_f, stderr=null_f, stdin=null_f)

            sk = domainSocket()
            sk.clientConnect(maxRetry = 30, timeGap = 0.5, blExcept = False)

            cmd = {
                "action": "fixmeAction",
                "itemIDs": rules
            }
            sk.objSend(cmd)

            # Wait for ACK
            sk.recv(BUFSIZ)
            ## check time
            if not checkTime():
                setErrInfo(resp, 'error', 'error_system_time')
                resp[RETURN_SUCCESS_KEY] = False
            else:
                resp[RETURN_SUCCESS_KEY] = True
            sk.close()
        except Exception as e:
            resp[RETURN_SUCCESS_KEY] = False
            SYSLOG(syslog.LOG_ERR, 'Failed to scan Error: %s' % e)

        sys.stdout.write(json.dumps(resp))

    def firstScan(self):
        resp = {}

        try:
            if os.path.exists(CONFIG_LOGANALYZER_SETTING):
                resp[RETURN_FIRST_LOGANALYZER] = False
            else:
                resp[RETURN_FIRST_LOGANALYZER] = True

            sysSettings = getSysSettings()
            if not sysSettings[CONFIG_DEF_GROUP_KEY]:
                resp[RETURN_FIRST_SCAN] = True
            else:
                resp[RETURN_FIRST_SCAN] = False
                ## Check if system crack
                resp[RETURN_IS_CRACK] = False
                if os.path.exists(SYSTEM_RESULT_FILE):
                    retJson = {}
                    with open(SYSTEM_RESULT_FILE) as fp:
                        data = fp.read()
                    if data:
                        retJson = json.loads(data)
                        if SYSTEM_STATUS_CRACK == retJson[SYSTEM_RESULT_SYSSTATUS]:
                            resp[RETURN_IS_CRACK] = True

            resp[RETURN_SUCCESS_KEY] = True
        except Exception as e:
            SYSLOG(syslog.LOG_ERR, "Fail to firstScan()")
            resp[RETURN_SUCCESS_KEY] = False

        sys.stdout.write(json.dumps(resp))

    def currentTimeGet(self):
        import time
        resp = {
            RETURN_CURTIME: time.time(),
            RETURN_SUCCESS_KEY: True
        }
        sys.stdout.write(json.dumps(resp))

    def dangerSet(self):
        resp = {
            RETURN_SUCCESS_KEY: False
        }
        setErrInfo(resp, 'securityscan', 'framwork_modified_error')
        sysStatusDangerSet()
        sys.stdout.write(json.dumps(resp))

if __name__ == "__main__":
    import argparse
    import os
    import socket
    import sys

    parser = argparse.ArgumentParser(description="Security Scan Tool")
    parser.add_argument("--action", choices=["StartScan", "SysStatusQuery", "StatusQuery", "StopScan", "ConfSave", "ConfLoad",
        "CustomListSave", "ListEnum", "DBUpdate", "DBVersionCheck", "FixmeAction", "Info", "FirstScan", "CurrentTimeGet", "dangerSet"], help="Run action")
    parser.add_argument("--rules", nargs="*", help="Rules items seperated by space")
    parser.add_argument("--argGroup", type=str, help="group")
    parser.add_argument("--updateBeforeScan", type=int, help="update before start")
    parser.add_argument("--taskId", type=int, help="The task id of schedule")
    parser.add_argument("--notify", type=int, help="send notify 1=>yes 0=>no")

    args = parser.parse_args()
    if not args.action:
        parser.print_help()
        exit(0)
    Dispatcher(args)
