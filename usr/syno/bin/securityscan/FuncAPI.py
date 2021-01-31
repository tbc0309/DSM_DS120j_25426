# Copyright (c) 2000-2014 Synology Inc. All rights reserved.
from Define import *
from utils import *
from multiprocessing import Queue
import json
import socket
import ctypes

## ======================== Global variable  ==============================
"""
    {
        'majorversion': '"5"',
        'minorversion': '"0"',
        'buildphase': '"hotfix"',
        'buildnumber': '"4494"',
        'smallfixnumber': '"0"',
        'builddate': '"2014/06/09"'
        'product': 'rs10613xs+'
        'platform': 'bromolow'
     }
"""
gVdict = {}
md5Table = None
## ======================== Sub functions ==============================
def getSysSettings():
    sysSettings = {};
    try:
        if os.path.isfile(SYSTEM_SETTING_FILE):
            with open(SYSTEM_SETTING_FILE) as fp:
                sysSettings = json.loads(fp.read())
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Exception Error: %s" % e)
    finally:
        ## Give the default value
        if not sysSettings.has_key(CONFIG_SCHEDULE):
            sysSettings[CONFIG_SCHEDULE] = {
                CONFIG_ENABLE_SCHEDULE: False,
                CONFIG_SCHEDULE_WEEKDAY: "1",
                CONFIG_SCHEDULE_HOUR: 2,
                CONFIG_SCHEDULE_MINUTE: 0
            }
        if not sysSettings.has_key(CONFIG_DEF_GROUP_KEY):
            sysSettings[CONFIG_DEF_GROUP_KEY] = ''
        if not sysSettings.has_key(CONFIG_UPDATE_KEY):
            sysSettings[CONFIG_UPDATE_KEY] = True
        if not sysSettings.has_key(CONFIG_IS_TESTSITE):
            sysSettings[CONFIG_IS_TESTSITE] = False

    return sysSettings

def compareInt(nInt1, nInt2):
    if (nInt1 > nInt2):
        return CMP_GREATER
    elif (nInt1 < nInt2):
        return CMP_LESS
    else:
        return CMP_EQUAL

def compareVersion(notRangeStyle):
    try:
        global gVdict
        if ({} == gVdict):
            SYSLOG(syslog.LOG_ERR, "gVdict is empty")
            return -1
        versionAndNumber= notRangeStyle.split('-')
        if (1 == len(versionAndNumber)): #'1.0' or '1' are possible values
            majorAndMinorVersion =  versionAndNumber[0].split('.')
            if (2 < len(majorAndMinorVersion)):
                SYSLOG(syslog.LOG_ERR, "must have main and minor, _non_comp_version foramt is wrong:" + notRangeStyle)
                return -1
            else:
                major = majorAndMinorVersion[0]
                vMajor = int(gVdict['majorversion'])
                nMajor = int(major)
                if (1 == len(majorAndMinorVersion)): # '1', only need to compare major
                    return compareInt(vMajor, nMajor)
                elif (2 == len(majorAndMinorVersion)): # '4.3', need to compare major and minor
                    vMinor = int(gVdict['minorversion'])
                    nMinor = int(majorAndMinorVersion[1])
                    majorResult = compareInt(vMajor, nMajor)
                    if (majorResult != 0):
                        return majorResult
                    else: # major is equal
                        return compareInt(vMinor, nMinor)
                else:
                    #impossible here
                    return -1

        else: # '1.0-1234' we have buildnumber, so that compare it directly
            vBuildNumber = int(gVdict['buildnumber'])
            nBuildNumber = int(versionAndNumber[1])
            return compareInt(vBuildNumber, nBuildNumber)
    except Exception as e:
        trace = traceback.format_exc()
        tracelog(trace)
        return -1

def isInVersion(notRangeStyle):
    if (CMP_EQUAL == compareVersion(notRangeStyle)):
        return True
    else:
        return False

def isGreaterOrInVersion(notRangeStyle):
    result = compareVersion(notRangeStyle)
    if (CMP_GREATER == result or CMP_EQUAL == result):
        return True
    else:
        return False

def isLessOrInVersion(notRangeStyle):
    result = compareVersion(notRangeStyle)
    if (CMP_LESS == result or CMP_EQUAL == result):
        return True
    else:
        return False

def isVersionMatched(versionExp):
    global gVdict
    if ({} == gVdict):
        SYSLOG(syslog.LOG_ERR, "gVdict is empty")
        return False
    rangeFromTo = versionExp.split('~')
    if (2 < len(rangeFromTo)): # do not allow xxx~xxx~xxx or more ~
        SYSLOG(syslog.LOG_ERR, "too many ~ ,_non_comp_version foramt is wrong:" + str(versionExp))
        return False


    #'1.x' '1.0' '1.0-1234' are possible styles
    if (1 == len(rangeFromTo)):
        return isInVersion(rangeFromTo[0])

    # '1.0-1234~1.0-2345' is possible style
    elif(2 == len(rangeFromTo)): #range style xxxx~xxxx
        if (isGreaterOrInVersion(rangeFromTo[0]) and isLessOrInVersion(rangeFromTo[1])):
            return True
        else:
            return False
    else:
        #impossible here
        return False

def initGVdict():
    global gVdict
    if ({} != gVdict):
        return True

    dsmVersionFile = "/etc.defaults/VERSION"
    """ parsing dsmVersionFile"""
    with open(dsmVersionFile) as fp:
        for line in fp:
            dlist = line.strip().split("=")
            if (2 != len(dlist)):
                SYSLOG(syslog.LOG_ERR, "parsing" + dsmVersionFile + "error")
                return False

            gVdict[dlist[0]] = dlist[1].replace("\"", "")

    unique = execute('get_key_value /etc.defaults/synoinfo.conf unique', blSplit=False)
    gVdict['platform'] = unique.split('_')[1]
    gVdict['product'] = unique.split('_')[2]

    return True

def verCheck(strVersionList):
    """
        ['1', '2', '3', '4.0', '4.1', '4.2', '5.0-4480', '5.0-4480~5.0-4490']
    """
    try:
        initGVdict()
        for _ in strVersionList:
            if (isVersionMatched(_)): # is gVdict in _ ?
                return False

    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Failed to runnable() Error:%s" % e)
        trace = traceback.format_exc()
        tracelog(trace)

    return True

def machineCheck(module):
    global gVdict

    if not hasattr(module, '_non_comp_product'):
        return True

    initGVdict()
    return not gVdict['product'] in module._non_comp_product

def runnable(module):
    return verCheck(module._non_comp_version) and machineCheck(module)

def collectItem(items, leafModuleName, group = ''):
    leafModule = moduleImport(leafModuleName)
    if not leafModule:
        return

    leafModuleObj = leafModule.RuleDictResult()

    if (runnable(leafModuleObj) and
            (not group or group in leafModuleObj._group)):
        items.append(leafModuleName)

def enumItems(group = '', runableCheck = True):
    '''
        empty group indicate to get all items
    '''
    import json

    items = []
    DBHash = []
    if not os.path.exists(SECURITY_DB_PATH) or isUpdating():
        return []

    try:
        if GROUP_CUSTOM == group:
            ## Custom group
            if os.path.isfile(CUSTOM_LIST_FILE):
                with open(CUSTOM_LIST_FILE) as fp:
                    custom_items = fp.read()
                DBHash = [_ for _ in custom_items.split(' ') if _]
                group = ''
        else:
            ## Home or work group
            with open(DB_LIST_PATH) as fp:
                DBHash = json.loads(fp.read())
                DBHash = DBHash[CHECKSUM_FILE_RULE_KEY].keys()

        for _key in DBHash:
            if runableCheck:
                collectItem(items, _key, group)
            else:
                items.append(_key)

    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Fail to enumItems %s" % e)
        return []

    return items

def scanItemsEnum(argRules):
    rules = " ".join(argRules)
    if ITEMS_ALL == rules:
        sysSettings = getSysSettings()
        rules = enumItems(sysSettings[CONFIG_DEF_GROUP_KEY])
        rules = " ".join(rules)
    return rules

def getAllItemsInfo():
    items = {};
    enumDFS(items, DB_NAME, 0, showItem)
    return items

def isMainPyAlive():
    if os.path.isfile(MAIN_SCANNER_PIDFILE):
        with open(MAIN_SCANNER_PIDFILE) as f:
            pid = f.read()
        if pid and os.path.isdir("/proc/%s/" %pid):
            return True
    return False

def isUpdating():
    if os.path.isfile(MAIN_UPDATE_PIDFILE):
        with open(MAIN_UPDATE_PIDFILE) as f:
            pid = f.read()
        if pid and os.path.isdir("/proc/%s/" %pid):
            return True
    return False

def itemSet(data, item):
    if not item or RESULT_ID not in item:
        return

    _id = item[RESULT_ID]
    if _id not in data:
        data[_id] = {}
    data[_id][RESULT_ID] = item[RESULT_ID]
    data[_id][RESULT_METHOD] = item[RESULT_METHOD]
    data[_id][RESULT_STATUS] = item[RESULT_STATUS]
    data[_id][RESULT_ACTION] = item[RESULT_ACTION]
    data[_id][RESULT_SEVERITY] = item[RESULT_SEVERITY]
    data[_id][RESULT_UPDATE_TIME] = item[RESULT_UPDATE_TIME]
    data[_id][RESULT_CATEGORY] = item[RESULT_CATEGORY]
    data[_id][RESULT_STR_ID] = item[RESULT_STR_ID]

def defaultItemGet(itemID):
    item = {}

    try:
        module = moduleImport(itemID)
        if not module:
            return {}

        moduleObj = module.RuleDictResult()
        item[RESULT_ID] = itemID
        item[RESULT_METHOD] = ''
        item[RESULT_STATUS] = SZ_NONE_CHECK
        item[RESULT_ACTION] = ''
        item[RESULT_SEVERITY] = moduleObj._severity
        item[RESULT_UPDATE_TIME] = ''
        item[RESULT_CATEGORY] = moduleObj._category
        item[RESULT_STR_ID] = moduleObj._strId
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Fail to defaultItemGet() Error:%s" % e)
        return {}

    return item

def setErrInfo(resp, sec, key):
    resp[RETURN_ERRORINFO] = {
        'key': key,
        'sec': sec
    }

def sendNotify(key, mailHash):
    mailJson = json.dumps(mailHash)
    mailJson = mailJson.replace('"', '\\"')
    mailJson = '"' + mailJson + '"'

    cmd = SYSTEM_SYSNOTIFY + " " + key + " " + mailJson
    with SynoCriticalSection() as cs:
        execute(cmd)

def updateBadge(risk_count):
    cmd = BADGE_UPDATE_CMD % risk_count
    execute(cmd)

def severityBigger(v1, v2):
    levelScore = {}
    score = len(ALL_LEVEL)

    ## Init score for each level
    for level in ALL_LEVEL:
        levelScore[level] = score
        score = score - 1

    levelScore['safe'] = -1

    if levelScore[v1] > levelScore[v2]:
        return v1
    else:
        return v2

def itemDataGet(rules):
    cmd = {
        "action": "status",
        "itemIDs": rules
    }
    newData = {}

    if isMainPyAlive() and not isUpdating():
        sk = domainSocket()
        try:
            sk.clientConnect()
            sk.objSend(cmd)

            ## recv json Data
            obj = sk.objRecv()
            newData = json.loads(obj)
        except Exception as e:
            newData = {}
        finally:
            try:
                sk.close()
            except Exception as e:
                SYSLOG(syslog.LOG_ERR, "Failed to itemDataGet() Error %s" %e)
                return False

    if not newData:
        if os.path.exists(RESULT_FILE):
            try:
                with open(RESULT_FILE) as f:
                    newData = json.loads(f.read())
            except Exception as e:
                newData = {}

    return newData

def getDBInfoURL():
    '''
        get DB info URL according to setting
    '''
    global gVdict
    try:
        initGVdict()
        vDSMVer = gVdict['majorversion']
        vPlatform = gVdict['platform']

        # modify platform name for url
        if vPlatform == "88f6281" or vPlatform == "88f6282":
            vPlatform = "6281"
        elif vPlatform == "x86":
            vPlatform = "x64"

        # check if is test site
        sysSettings = getSysSettings()
        vDomainName = DB_URL_DOMAIN_NAME
        if (sysSettings[CONFIG_IS_TESTSITE]):
            vDomainName = DB_URL_DOMAIN_NAME_TESTSITE

        # https://xxx/securityscan/v1/7/cedarview
        dbInfoURL = DB_URL % (vDomainName, vDSMVer, vPlatform)
        return dbInfoURL
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Fail to get DB info url %s" % e)
        return ""

def queryDBInfo():
    '''
        query DB info from server side
        return
            version: latest version on server side
            checksum_file: gpg file url path for download
            success: True or False
    '''
    import json
    import urllib2
    import ssl

    global gVdict

    try:
        dbURL = getDBInfoURL()
        if not dbURL:
            raise ValueError('DB url is empty')

        try:
            jsonData = urllib2.urlopen(dbURL, timeout=UPDATE_SOCKET_TIMEOUT).read()
            jsonData = json.loads(jsonData)
        except urllib2.URLError as e:
            SYSLOG(syslog.LOG_ERR, "update fail - {}".format(e))
            raise
        except ValueError as e:
            SYSLOG(syslog.LOG_ERR, "update fail 'cause by decode '%s' failure" % jsonData)
            raise

        # {"version":"301","file":"https://xxx/securityscan-db.txz","checksum_file":"https://xxx/securityscan-db.txz.gpg"}
        latestVer = jsonData['version']
        checksum_file = jsonData['checksum_file']
        return latestVer, checksum_file, True

    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Fail to get DB info %s" % e)
        return 0, "", False

def updateCheck():
    '''
        return
            latestVer: latest version on server side
            current version: client version
            Need update:
    '''
    global gVdict
    if ({} != gVdict):
        return True

    latestVer, checksum_file, success = queryDBInfo()

    if success:
        if not os.path.exists(SECURITY_INFO_PATH):
            return latestVer, 0, True

        with open(SECURITY_INFO_PATH) as fp:
            for line in fp:
                dlist = line.strip().split("=")
                if (2 != len(dlist)):
                    SYSLOG(syslog.LOG_ERR, "parsing" + SECURITY_INFO_PATH + "error")
                    return False
                gVdict[dlist[0]] = dlist[1].replace("\"", "")

        curVer = gVdict['version']

        if latestVer > curVer:
            return latestVer, curVer, True
        else:
            return latestVer, curVer, False
    else:
        SYSLOG(syslog.LOG_ERR, "Fail to get version")
        return 0, 0, False

def downloadFile(src, dest):
    from subprocess import call

    ret = 1
    options = []
    options.append("--connect-timeout=%d" % UPDATE_SOCKET_TIMEOUT)
    options.append("--tries=1")

    try:
        with open(os.devnull, 'w') as FNULL:

            useragent = ""
            cmd = "%s --user-agent %s 2> /dev/null" % (SYSTEM_SYNODSINFO, APP_NAME)
            useragent = os.popen(cmd).read().strip()
            optionU = "--user-agent=\"{useragent}\"".format(useragent=useragent)
            ret = call(["wget", src, options[0], options[1], optionU, "-O", dest], stdout=FNULL, stderr=FNULL)
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Failed to downloadFile() Error: %s" % e)
        return 1

    return ret

def targetRemove(path):
    import shutil

    if os.path.isdir(path):
        shutil.rmtree(path)
    if os.path.isfile(path):
        os.unlink(path)

def dirMove(src, dst):
    import shutil

    try:
        targetRemove(dst)
        shutil.move(src, dst)
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Failed to dirMove(%s, %s) Error: %s" % (src, dst, e))

def updateSecurityDB(latestVer):
    '''
        return
            True - success
    '''
    import os, pwd
    import shutil
    import tarfile
    import commands

    ret = False

    latestVer, checksum_file, success = queryDBInfo()
    if not success:
        return ret

    try:
        ## make sure that download path exist
        if not os.path.exists(SECURITY_DB_PREFIX):
            with SynoCriticalSection() as cs:
                os.makedirs(SECURITY_DB_PREFIX)
                system_uid = pwd.getpwnam('system').pw_uid
                system_gid = pwd.getpwnam('system').pw_gid
                os.chown(SECURITY_DB_PREFIX, system_uid, system_gid)
        downRet =  downloadFile(checksum_file, DB_DOWNLOAD_SAVE_PATH)
        if 0 != downRet:
            SYSLOG(syslog.LOG_ERR, "Failed to download database from %s" % checksum_file)
            return ret

        ## Check signature
        if os.path.exists(DB_PATH_TAR_TMP):
            os.unlink(DB_PATH_TAR_TMP)
        cmdRet, cmdOutput = commands.getstatusoutput(GPG_DECRYPTION)
        os.unlink(DB_DOWNLOAD_SAVE_PATH)

        if 0 != cmdRet:
            SYSLOG(syslog.LOG_ERR, "The signature of %s is wrong" % DB_DOWNLOAD_SAVE_PATH)
            return ret

        ## untar db to DB_PATH_TMP
        if os.path.exists(DB_PATH_TMP):
            with SynoCriticalSection() as cs:
                shutil.rmtree(DB_PATH_TMP)
        os.makedirs(DB_PATH_TMP)
        cmdRet, cmdOutput = commands.getstatusoutput(DB_EXTRACT_CMD)
        os.unlink(DB_PATH_TAR_TMP)

        if 0 != cmdRet:
            targetRemove(DB_PATH_TMP)
            SYSLOG(syslog.LOG_ERR, "Failed to untar db")
            return ret

        ## assign untar-ed files to owner system:system
        with SynoCriticalSection() as cs:
            cmdRet, cmdOutput = commands.getstatusoutput(DB_EXTRACT_CHOWN_CMD)

        if 0 != cmdRet:
            SYSLOG(syslog.LOG_ERR, "Failed to chown")
            return ret

        ## Backup old rules and strings
        if os.path.exists(SECURITY_DB_PATH):
            dirMove(SECURITY_DB_PATH, DB_PATH_BAK)
        if os.path.exists(SECURITY_UTIL_PATH):
            dirMove(SECURITY_UTIL_PATH, UTIL_PATH_BAK)
        if os.path.exists(STRING_PATH):
            dirMove(STRING_PATH, STRING_PATH_BAK)
        if os.path.exists(SECURITY_INFO_PATH):
            shutil.move(SECURITY_INFO_PATH, SECURITY_INFO_PATH_BAK)

        try:
            ## Move new rule and strings from tmp path to correct path
            newDBPath = '%s/%s' % (DB_PATH_TMP, SECURITY_DB_PATH)
            newUtilPath = '%s/%s' % (DB_PATH_TMP, SECURITY_UTIL_PATH)
            newStrPath = '%s/%s' % (DB_PATH_TMP, STRING_PATH)
            newInfoPath = '%s/%s' % (DB_PATH_TMP, SECURITY_INFO_PATH)

            dirMove(newDBPath, SECURITY_DB_PATH)
            dirMove(newUtilPath, SECURITY_UTIL_PATH)
            dirMove(newStrPath, STRING_PATH)
            shutil.move(newInfoPath, SECURITY_INFO_PATH)

            SYSLOG(syslog.LOG_ERR, "Security Adviser DB have updated to version %s" % latestVer)
            ret = True
        except Exception as e:
            ## Restore when there are any error durring changes new db and strings
            SYSLOG(syslog.LOG_ERR, "Failed to update new database and strings %s" % e)

            dirMove(DB_PATH_BAK, SECURITY_DB_PATH)
            dirMove(UTIL_PATH_BAK, SECURITY_UTIL_PATH)
            dirMove(STRING_PATH_BAK, STRING_PATH)
            shutil.move(SECURITY_INFO_PATH_BAK, SECURITY_INFO_PATH)
        finally:
            ##Remove old rules and bak files
            targetRemove(DB_PATH_BAK)
            targetRemove(UTIL_PATH_BAK)
            targetRemove(STRING_PATH_BAK)
            targetRemove(SECURITY_INFO_PATH_BAK)
            ##Remove extracted files
            targetRemove(DB_PATH_TMP)

        return ret
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Failed to updateSecurityDB() Error: %s" % e)
        return False

def utcTimeGet():
    import time

    try:
        return time.strftime("%s")
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Failed to utcTimeGet() Error: %s" % e)
        return ""

class SysStatusItems(object):
    def __init__(self):
        self._category = ''
        self._progress = 0
        self._failSeverity = 'safe'
        self._runningItem = ''
        self._total = 0
        self._waitNum = 0

        self._fail = dict()
        for _ in ALL_LEVEL:
            self._fail[_] = 0
    def getHash(self):
        _ret = {
            'category': self._category,
            'progress': self._progress,
            'fail': self._fail,
            'failSeverity': self._failSeverity,
            'runningItem': self._runningItem,
            'total': self._total,
            'waitNum': self._waitNum
        }
        return _ret

def sysItemsUpdate(sysItems, item, rItem):
    from multiprocessing import Queue

    category = item[RESULT_CATEGORY]
    targetItem = sysItems['categoryItems'][category]
    targetItem['waitNum']  = targetItem['waitNum'] - 1 if (0 < targetItem['waitNum']) else 0
    sysItems['sysRunning'] = sysItems['sysRunning'] -1 if (0 < sysItems['sysRunning']) else 0

    if (0 < targetItem['total']):
        targetItem['progress'] = int(float(targetItem['total'] - targetItem['waitNum'])/float(targetItem['total']) * 100)
    else:
        targetItem['progress'] = 100

    if SZ_FAIL == item[RESULT_STATUS] or SZ_ERROR == item[RESULT_STATUS]:
        level = item[RESULT_SEVERITY]
        targetItem['fail'][level] += 1
        targetItem['failSeverity'] = severityBigger(level, targetItem['failSeverity'])

    if rItem:
        targetItem['runningItem'] = rItem
    elif not targetItem['runningItem']:
        targetItem['runningItem'] = item[RESULT_STR_ID]

    sysTotal = sysItems['sysTotal']
    sysRunning = sysItems['sysRunning']
    sysItems['sysProgress'] = int(float(sysTotal - sysRunning)/float(sysTotal) * 100)

def sysStatusCalculate(currentData, rules):
    '''
        return items, sysStatus, sysProgress
    '''
    retItems = {}
    maxFailLevel = 'safe'

    for _ in ALL_CATEGORY:
        retItems[_] = SysStatusItems()
        retItems[_]._category = _

    if not currentData:
        ## There are no histroy data => first scan
        sysStatus = SYSTEM_STATUS_FIRST
        return {}, sysStatus, 100
    else:
        try:
            ## Fetch all items number and status
            for item in rules.split():
                if item in currentData:
                    resultData = currentData[item]
                else:
                    resultData = defaultItemGet(item)
                if SZ_NONE_CHECK == resultData[RESULT_STATUS]:
                    ## rule never scanned, do not add
                    continue
                retData = retItems[resultData[RESULT_CATEGORY]]
                retData._total += 1

                if SZ_FAIL == resultData[RESULT_STATUS] or SZ_ERROR == resultData[RESULT_STATUS]:
                    level = resultData[RESULT_SEVERITY]
                    retData._fail[level] += 1

            ## Calculate progress & failSeverity & sysStatus
            sysTotal = 0
            sysRunning = 0
            for _category in retItems:
                data = retItems[_category]
                sysTotal += data._total
                sysRunning += data._waitNum
                data._progress = 100

                ## Calculate failSeverity
                data._failSeverity = 'safe'
                for level in ALL_LEVEL:
                    if 0 < data._fail[level]:
                        data._failSeverity = level
                        break
                maxFailLevel = severityBigger(maxFailLevel, data._failSeverity)

                retItems[_category] = data.getHash()
        except Exception as e:
            SYSLOG(syslog.LOG_ERR, "Failed to _sysStatusItemGet() Error: %s" % e)
            trace = traceback.format_exc()
            tracelog(trace)

        ## Calculate system status
        sysProgress = 100
        if LEVEL_DANGER == maxFailLevel:
            sysStatus = SYSTEM_STATUS_DANGER
        elif LEVEL_RISK == maxFailLevel:
            sysStatus = SYSTEM_STATUS_RISK
        elif LEVEL_WARNING == maxFailLevel:
            sysStatus = SYSTEM_STATUS_WARNING
        elif LEVEL_OUT_OF_DATE == maxFailLevel:
            sysStatus = SYSTEM_STATUS_OUT_OF_DATE
        else:
            sysStatus = SYSTEM_STATUS_SAFE

        sysResultSet(retItems, sysStatus)
        return retItems, sysStatus, sysProgress

def sysResultGet(sysSettings):
    '''
        return items, sysStatus, sysProgress
    '''
    import os

    if os.path.exists(SYSTEM_RESULT_FILE):
        retJson = {}
        try:
            with open(SYSTEM_RESULT_FILE) as fp:
                retJson = json.loads(fp.read())

            if sysSettings[CONFIG_DEF_GROUP_KEY] == retJson[CONFIG_DEF_GROUP_KEY]:
                ## make sure all categories exist, in case of category list change
                for _ in ALL_CATEGORY:
                    if not _ in retJson[SYSTEM_RESULT_ITEMS]:
                        emptySysItem = SysStatusItems()
                        emptySysItem._category = _
                        retJson[SYSTEM_RESULT_ITEMS][_] = emptySysItem.getHash()
                return retJson[SYSTEM_RESULT_ITEMS], retJson[SYSTEM_RESULT_SYSSTATUS], 100
        except Exception as e:
            retJson = {}

    rules = scanItemsEnum([ITEMS_ALL])
    currentData = itemDataGet(rules)
    return sysStatusCalculate(currentData, rules)

def sysResultSet(retItems, sysStatus):
    import shutil, tempfile

    sysSettings = getSysSettings()
    with tempfile.NamedTemporaryFile('w', prefix=SYSTEM_RESULT_FILE_TMP, delete=False) as fp:
        resultJson = {
            CONFIG_DEF_GROUP_KEY: sysSettings[CONFIG_DEF_GROUP_KEY],
            SYSTEM_RESULT_SYSSTATUS: sysStatus,
            SYSTEM_RESULT_ITEMS: retItems
        }
        fp.write(json.dumps(resultJson, indent=4))
        fpname = fp.name

    shutil.move(fpname, SYSTEM_RESULT_FILE)

    ## update badge number
    risk_count = 0
    for _category in retItems:
        for _level in ALL_LEVEL:
            risk_count += retItems[_category]["fail"][_level]
            if _level == LEVEL_RISK:
                ## do not count levels < risk
                break
    updateBadge(risk_count)

def resultSet(module, itemID, blFail=False):
    def errorSet(result):
        result[RESULT_STATUS] = SZ_ERROR
        result[RESULT_METHOD] = ''
        result[RESULT_ACTION] = ''

    result = {}
    try:
        if blFail:
            errorSet(result)
        else:
            result = module.getDict()

    except Exception as e:
        result = {}
        errorSet(result)
        SYSLOG(syslog.LOG_ERR, "Failed to check rules %s Error: %s" % (itemID, e))
    finally:
        result[RESULT_ID] = itemID
        result[RESULT_GROUP] = module._group
        result[RESULT_CATEGORY] = module._category
        result[RESULT_STR_ID] = module._strId
        result[RESULT_SEVERITY] = module._severity
        result[RESULT_UPDATE_TIME] = utcTimeGet()

    return result

def checksumCalc(filePath, block_size=2**20):
    import hashlib
    with open(filePath) as fp:
        data = fp.read()
    h = hashlib.md5()
    h.update(data)
    return h.hexdigest()

def itemChecksumCalc(itemID, block_size=2**20):
    f = '%s/%s.py' % (SECURITY_DB_PREFIX, itemID.replace('.', '/'))
    return checksumCalc(f, block_size)

def moduleImport(module):
    import imp, os
    global md5Table
    if (md5Table is None):
        try:
            with open (DB_LIST_PATH) as fp:
                md5Table = json.loads(fp.read())
        except Exception as e:
            SYSLOG(syslog.LOG_ERR, "Failed to open %s Error %s" % (DB_LIST_PATH, e))
            return False
    try:
        modulePath = '%s/%s.py' %(SECURITY_DB_PREFIX, module.replace('.','/'))
        if (not os.path.isfile(modulePath)) or (md5Table[CHECKSUM_FILE_RULE_KEY][module] != checksumCalc(modulePath)):
            SYSLOG(syslog.LOG_ERR, "The checksum of file %s != original checksum %s" % (module, md5Table[CHECKSUM_FILE_RULE_KEY][module]))
            sysStatusDangerSet()
            return False
        moduleObj = imp.load_source('RuleDictResult', modulePath)
        return moduleObj
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Failed to import module %s" % e)
        return False

def filterItemsWithFixmeAction(items):
    resultItems = []
    for i in items.split():
        module = moduleImport(i)
        if not module:
            continue
        moduleObj = module.RuleDictResult()
        if CMD_FIXME_ACTION in dir(moduleObj):
            resultItems.append(i)

    return " ".join(resultItems)

def startTimeSet():
    ## FIXME: need lock to access file
    if os.path.exists(START_TIME_TMP):
        return

    with open(START_TIME_TMP, "w") as f:
        f.write(utcTimeGet())

def startTimeGet():
    if os.path.exists(START_TIME_TMP):
        with open(START_TIME_TMP) as f:
            return f.read()
    else:
        return ''

def checkTime():
    import os, time

    try:
        mTime = os.stat(DB_LIST_GPG_PATH).st_mtime
        if time.time() < mTime:
            SYSLOG(syslog.LOG_ERR, "System time %f < gpg list %s time %f" % (time.time(), DB_LIST_GPG_PATH, mTime))
            return False
        return True
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Failed to checkTime: %s" % e)
        return False


def checksumGen():
    import os, shutil, commands

    global md5Table

    with SynoCriticalSection():
        if os.path.exists(DB_LIST_TMP_PATH): os.unlink(DB_LIST_TMP_PATH)
    cmdRet, cmdOutput = commands.getstatusoutput(GPG_DECRYPTION_CHECKSUM)

    if 0 != cmdRet:
        SYSLOG(syslog.LOG_ERR, "The signature of %s is wrong" % GPG_DECRYPTION_CHECKSUM)
        SYSLOG(syslog.LOG_ERR, cmdOutput.replace('\n',';'))
        sysStatusDangerSet()
        return False

    with SynoCriticalSection():
        shutil.move(DB_LIST_TMP_PATH, DB_LIST_PATH)

    ## force verify checksum
    enumItems()
    with open (DB_LIST_PATH) as fp:
        md5Table = json.loads(fp.read())
        # Check .so checksum
        if md5Table[CHECKSUM_FILE_SO_KEY] != checksumCalc(DB_SO_PATH):
            SYSLOG(syslog.LOG_ERR, "The checksum of %s is incorrect" % DB_SO_PATH)
            return False
        if CHECKSUM_FILE_UTIL_KEY in md5Table:
            utilTable = md5Table[CHECKSUM_FILE_UTIL_KEY]
            for utilModule in utilTable:
                filePath = utilModule.replace('.', '/') + '.py'
                utilFilePath = SECURITY_DB_PREFIX + filePath
                if utilTable[utilModule] != checksumCalc(utilFilePath):
                    SYSLOG(syslog.LOG_ERR, "The checksum of %s is incorrect" % utilFilePath)
                    return False
    return True

def cleanPyc():
    import os

    removePycList = []
    for dirName, dirNames, fileNames in os.walk(SECURITY_DB_PATH):
        for fName in fileNames:
            if fName.endswith('.pyc'):
                removePycList.append(os.path.join(dirName, fName))
    for f in removePycList: os.unlink(f)

def sysStatusDangerSet():
    sysSettings = getSysSettings()
    retItems, sysStatus, sysProgress = sysResultGet(sysSettings)
    sysResultSet(retItems, SYSTEM_STATUS_CRACK)
    sendNotify('SecurityScanDanger', {})

class domainSocket(object):
    import socket

    def __init__(self, sock = None, addr = None):
        self._sk = sock
        self._addr = addr

    def serverBind(self, ipcPath = IPC, maxConnection = MAX_IPC_NR):
        self._sk = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self._sk.bind(ipcPath)
        self._sk.listen(maxConnection)

    def accept(self):
        cliSk, addr = self._sk.accept()
        return domainSocket(cliSk, addr)

    def clientConnect(self, ipcPath = IPC, timeOut = SOCKET_TIMEOUT, maxRetry = 10, timeGap = 0.5, blExcept = True):
        import time

        blConnected = False
        self._sk = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self._sk.settimeout(timeOut)

        for i in range(maxRetry):
            try:
                self._sk.connect(ipcPath)
                blConnected = True
                break
            except Exception as e:
                if 111 == e.errno and blExcept:
                    raise
                else:
                    time.sleep(timeGap)
                    continue
        if not blConnected:
            SYSLOG(syslog.LOG_ERR, "Failed to connect to %s" % IPC)
            raise

    def objSend(self, obj):
        self._sk.send("%s" %str(len(json.dumps(obj))))
        self._sk.recv(BUFSIZ)
        self._sk.send("%s" %json.dumps(obj))

    def objRecv(self):
        recvLen = int(self._sk.recv(BUFSIZ))
        self._sk.send(SOCKET_ACK)
        objJson = ""
        while True:
            tmp = self._sk.recv(BUFSIZ)
            objJson += tmp
            if recvLen <= len(objJson):
                break
        return objJson

    def send(self, msg):
        self._sk.send(msg)

    def recv(self, size):
        return self._sk.recv(size)

    def close(self):
        self._sk.close()

if __name__ == '__main__':
    raise SystemError("You should NOT directly run this script")

