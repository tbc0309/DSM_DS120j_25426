# Copyright (c) 2000-2014 Synology Inc. All rights reserved.
from utils import *
from FuncAPI import *
from multiprocessing import Queue
import json
import socket

def initSysStatus():
    sysItems = {
        'categoryItems': {},
        'sysStatus': SYSTEM_STATUS_RUNNING,
        'sysProgress': 0,
        'sysTotal': 0,
        'sysRunning': 0
    }

    retItems = sysItems['categoryItems']
    for _ in ALL_CATEGORY:
        retItems[_] = SysStatusItems()
        retItems[_]._category = _
        retItems[_] = retItems[_].getHash()

    return sysItems

## ======================== Global variable  ==============================
gMsgQueue = Queue()
gRunningQueue ={ _: Queue() for _ in ALL_CATEGORY}
try:
    with open (DB_LIST_PATH) as fp:
        md5Table = json.loads(fp.read())
        gChecksumTable = md5Table[CHECKSUM_FILE_RULE_KEY]
    cleanPyc()
except Exception as e:
    SYSLOG(syslog.LOG_ERR, "Failed to open %s Error %s" % (DB_LIST_PATH, e))
    exit(1)
gSysItems = initSysStatus()
gItemsDict = dict()
## ======================== Sub functions  ==============================
def recycleOutput(pid, pool):
    import signal
    cmd = {
        "action": "output2File"
    }
    cliSk = domainSocket()
    cliSk.clientConnect()

    ## Kill child process
    pool.terminate()

    cliSk.objSend(cmd)

    with SynoCriticalSection() as cs:
        ## Remove IPC file
        os.unlink(IPC)
        ## Remove the PID file
        os.unlink(MAIN_SCANNER_PIDFILE)

        #FIXME:In 10613xs it need to kill itself or process remain
        os.kill(os.getpid(), signal.SIGKILL)

def sigHandler(sig, frame):
    try:
        exit(0)
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Fail to exit() Error: %s" % e)

def fetchQueue2Dict(MsgQueue):
    global gSysItems
    global gRunningQueue
    global gItemsDict

    while True:
        if MsgQueue.empty():
            break
        try:
            result = MsgQueue.get(block=False)
        except:
            break

        itemSet(gItemsDict, result)
        category = result[RESULT_CATEGORY]
        rItem = ''
        try:
            if not gRunningQueue[category].empty():
                rItem = gRunningQueue[category].get()

                ## Flush the queue
                while not gRunningQueue[category].empty():
                    gRunningQueue[category].get()
        except:
            rItem = ''
            pass
        sysItemsUpdate(gSysItems, result, rItem)

def output2File(sk, MsgQueue, blNotify):
    import shutil

    global gItemsDict

    fetchQueue2Dict(MsgQueue)
    result = {}

    if os.path.isfile(RESULT_FILE):
        try:
            with open(RESULT_FILE) as f:
                result = json.loads(f.read())
        except Exception as e:
            pass

    for itemID in gItemsDict.iterkeys():
        ## If the status is running => skip updating
        if STATUS_RUNNING == gItemsDict[itemID][RESULT_STATUS]:
            continue
        result[itemID] = gItemsDict[itemID]

    with open(RESULT_FILE_TMP, "w") as f:
        f.write(json.dumps(result, sort_keys=True, indent=4))

    shutil.move(RESULT_FILE_TMP, RESULT_FILE)

    ## FIXME directly dump
    ## Re-calculate system status
    rules = scanItemsEnum([ITEMS_ALL])
    currentData = { key: result[key] for key in result.iterkeys() if key in rules}
    items, sysStatus, sysProgress = sysStatusCalculate(currentData, rules)

    ## Update last scan time
    sysSettings = getSysSettings()
    sysSettings[CONFIG_LAST_SCAN_ALL_TIME] = utcTimeGet()
    with open(SYSTEM_SETTING_FILE_TMP, "w") as f:
        f.write(json.dumps(sysSettings, sort_keys=True, indent=4))
    with SynoCriticalSection() as cs:
        shutil.move(SYSTEM_SETTING_FILE_TMP, SYSTEM_SETTING_FILE)

    if blNotify:
        '''
            SYSTEM_STATUS_WARNING would not notify and it is else case
        '''

        sysStatus = []
        for key in result:
            if SZ_FAIL == result[key][RESULT_STATUS] and key in rules:
                sysStatus += [result[key][RESULT_SEVERITY]]

        sysStatus = set(sysStatus)

        if SYSTEM_STATUS_DANGER in sysStatus:
            sendNotify('SecurityScanDanger', {})
        elif SYSTEM_STATUS_RISK in sysStatus:
            sendNotify('SecurityScanAlarm', {})

        if SYSTEM_STATUS_OUT_OF_DATE in sysStatus:
            '''
                if SYSTEM_STATUS_OUT_OF_DATE == sysStatus => [dsm update, package update] at least have one fail
            '''
            dsmUpdateRuleID = 'ruleDB.Update.DSM.check_latest_dsm'
            packageUpdateRuleID = 'ruleDB.Update.Package.check_latest_pkg'
            bldsmUpdateFail = False
            blpkgUpdateFail = False
            pkgUpdateFailNum = 0

            if dsmUpdateRuleID in rules and SZ_FAIL == result[dsmUpdateRuleID][RESULT_STATUS]:
                bldsmUpdateFail = True
            if packageUpdateRuleID in rules and SZ_FAIL == result[packageUpdateRuleID][RESULT_STATUS]:
                blpkgUpdateFail = True
                pkgUpdateFailNum = result[packageUpdateRuleID][RESULT_ACTION][ACTION_EXTRA]["FAIL_PACKAGES_NUM"]

            mailHash = {
                '%NUMBER%':str(pkgUpdateFailNum)
            }
            if bldsmUpdateFail and blpkgUpdateFail:
                sendNotify('SecurityScanDSMPackageOutOfDate', mailHash)
            elif bldsmUpdateFail:
                sendNotify('SecurityScanDSMOutOfDate', {})
            elif blpkgUpdateFail:
                sendNotify('SecurityScanPackageOutOfDate', mailHash)
            else:
                SYSLOG(syslog.LOG_ERR, "Unexpect notify in %s" % SYSTEM_STATUS_OUT_OF_DATE)

## ======================== Main functions ==============================
def ruleCheck(itemID, module):
    global gChecksumTable

    if not module:
        SYSLOG(syslog.LOG_ERR, "Failed to import %s" % itemID)
        return False

    moduleObj = module.RuleDictResult()
    if gChecksumTable[itemID] != itemChecksumCalc(itemID):
        result = resultSet(moduleObj, itemID, blFail=True)
        gMsgQueue.put(result)
        SYSLOG(syslog.LOG_ERR, "The checksum of file %s != original checksum %s" % (itemID, gChecksumTable[itemID]))
        return False
    return moduleObj

def ruleRun(itemID, blFixme=False):
    from time import sleep

    global gMsgQueue
    global gRunningQueue

    try:
        module = moduleImport(itemID)
        moduleObj = ruleCheck(itemID, module)
        if not moduleObj:
            return

        gRunningQueue[moduleObj._category].put(moduleObj._strId)
        if blFixme:
            if CMD_FIXME_ACTION not in dir(moduleObj):
                SYSLOG(syslog.LOG_ERR, '%s has not implement fixmeAction but called' % itemID);
                return

            result = moduleObj.fixmeAction()
            if  True != result:
                SYSLOG(syslog.LOG_ERR, 'Failed to fix item %s' % itemID)
                return

        result = resultSet(moduleObj, itemID)
        gMsgQueue.put(result)
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Failed to exec rules %s Error: %s" % (itemID, e))
        trace = traceback.format_exc()
        tracelog(trace)
        return

def scanner(itemID):
    ruleRun(itemID)

def fixmeer(itemID):
    ruleRun(itemID, blFixme=True)

def updateCheckItems(items):
    global gSysItems
    global gItemsDict

    h = {}
    if os.path.exists(RESULT_FILE):
        try:
            with open(RESULT_FILE) as f:
                h = json.loads(f.read())
        except Exception as e:
            pass
    if not gItemsDict:
        ## Get total items depend on group
        defTotalItems = scanItemsEnum([ITEMS_ALL])
        gItemsDict = { key: h[key] for key in h if key in defTotalItems}
    ## update
    for itemID in items:
        ## Discard old result, as some rule may be replaced
        gItemsDict[itemID] = {}
        itemData = defaultItemGet(itemID)
        itemData[RESULT_STATUS] = STATUS_RUNNING
        itemSet(gItemsDict, itemData)

        c = itemData[RESULT_CATEGORY]
        gSysItems['sysRunning'] += 1
        gSysItems['categoryItems'][c]['waitNum'] += 1

    for item in gItemsDict:
        c = gItemsDict[item][RESULT_CATEGORY]
        gSysItems['categoryItems'][c]['total'] += 1
        gSysItems['sysTotal'] += 1

def ControlCenter(pool, cmdQueue, ipc):
    from multiprocessing import Queue, Pool

    global gMsgQueue
    global gSysItems
    global gItemsDict
    blNotify = False

    ## items status dict

    while True:
        cli = ipc.accept()
        obj = cli.objRecv()
        cmd = json.loads(obj)

        if "start"== cmd["action"]:
            blNotify = cmd['blNotify']

            updateCheckItems(cmd["itemIDs"].split(" "))
            cmdObj = {}
            cmdObj['action'] = 'start'
            cmdObj['itemIDs'] = cmd['itemIDs']
            cmdQueue.put(cmdObj)    ## One command from one-click
            ## send ACK when cmd put into queue
            cli.send(SOCKET_ACK)

        elif "sysStatus" == cmd["action"]:
            fetchQueue2Dict(gMsgQueue)
            cli.objSend(gSysItems)

        elif "status" == cmd["action"]:
            fetchQueue2Dict(gMsgQueue)
            cli.objSend(gItemsDict)

        elif "output2File" == cmd["action"]:
            output2File(cli, gMsgQueue, blNotify)
            break

        elif "fixmeAction"== cmd["action"]:
            updateCheckItems(cmd["itemIDs"].split(" "))
            cmdObj = {}
            cmdObj['action'] = CMD_FIXME_ACTION
            cmdObj['itemIDs'] = cmd['itemIDs']
            cmdQueue.put(cmdObj)    ## One command from one-click
            ## send ACK when cmd put into queue
            cli.send(SOCKET_ACK)

        cli.close()

def RuleDispatcher(pool, cmdQueue, ipc):
    import time
    from multiprocessing import Queue, Pool
    import signal
    import atexit

    ## Wait for first query at most 150 * 0.1 secs
    tryMax = 150

    signal.signal(signal.SIGUSR1, sigHandler)
    ## Register exit handler
    atexit.register(recycleOutput, pid, pool)
    ipc.close()

    while cmdQueue.empty() and 0 < tryMax:
        tryMax -= 1
        time.sleep(0.1)

    cmdObj = {}
    while not cmdQueue.empty():
        cmdObj = cmdQueue.get(block=False)

        ## Finish condition
        if not cmdObj:
            break

        action = cmdObj['action']
        itemIDs = cmdObj['itemIDs'].strip()

        ## Process all inquiry
        ## FIXME:Only when adding get(MULTIPROCESS_TIMEOUT), parent process can get signal
        if 'start' == action:
            pool.map_async(scanner, itemIDs.split(" ")).get(MULTIPROCESS_TIMEOUT)
        elif CMD_FIXME_ACTION == action:
            pool.map_async(fixmeer, itemIDs.split(" ")).get(MULTIPROCESS_TIMEOUT)

    exit(1)


def MainLoop(ipc):
    """ Main Loop for wakeup """
    import os
    from multiprocessing import Queue, Pool

    global gMsgQueue

    ## Inquiry-Result message Queue
    pool = Pool(POOL_PROCESS_NUM)

    ## Parent-Child message Queue
    cmdQueue = Queue()

    pid = os.fork()
    if 0 == pid:    ## Child, receive the IPC command, always exit by kill
        ControlCenter(pool, cmdQueue, ipc)
    elif 0 < pid:    ## Parent, call pool.map
        RuleDispatcher(pool, cmdQueue, ipc)

def wakeup(sk):
    """ The main process. Handle all scan rules and handle by the Pool"""
    ## Create the PID file
    ## FIXME Should using file lock to avoid R.C.
    with SynoCriticalSection() as cs:
        with open(MAIN_SCANNER_PIDFILE, "w") as f:
            f.write("%s" %os.getpid())

    ## Main Loop
    try:
        MainLoop(sk)
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Capture exception Error: %s" % e)
        trace = traceback.format_exc()
        tracelog(trace)
    except KeyboardInterrupt as e:
        SYSLOG(syslog.LOG_ERR, "Exit by Ctrl-C")

if __name__ == "__main__":
    '''
        Please do NOT directly run this script
    '''
    import os, pwd
    try:
        with SynoCriticalSection() as cs:
            ## Clear the IPC file
            if os.path.exists(IPC):
                os.unlink(IPC)
            mainSock = domainSocket()
            mainSock.serverBind()
            system_uid = pwd.getpwnam('system').pw_uid
            system_gid = pwd.getpwnam('system').pw_gid
            os.chown(IPC, system_uid, system_gid)

        pid = os.fork()
        if 0 == pid:    ## Child PID
            wakeup(mainSock)
            exit(0)
        elif 0 < pid:    ## Parent PID
            mainSock.close()
        elif -1 == pid:
            SYSLOG(syslog.LOG_ERR, "Failed to wakeup()")
            exit(1)
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Failed to call _RuleRunner.py" % e)
