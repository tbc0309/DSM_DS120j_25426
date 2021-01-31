# Copyright (c) 2000-2014 Synology Inc. All rights reserved.
## ======================== Define  ==============================
APP_NAME = "synosecurityscan"          #for synodsinfo.static

ITEMS_ALL                   = "ALL"
RETURN_SUCCESS_KEY          = "success"
RETURN_JSON_KEY             = "items"
RETURN_CURRENT_VERSION      = 'currentVersion'
RETURN_LATEST_VERSION       = 'latestVersion'
RETURN_UPDATING             = 'isUpdating'
RETURN_SYSTEM_STATUS        = 'sysStatus'
RETURN_SYSTEM_PROGRESS      = 'sysProgress'
RETURN_SYSTEM_LAST_SCAN     = 'lastScanTime'
RETURN_FIRST_SCAN           = 'firstScan'
RETURN_FIRST_LOGANALYZER    = 'firstLogAnalyzer'
RETURN_FAIL_ALARM           = 'failAlarm'
RETURN_FAIL_WARNING         = 'failWarning'
RETURN_START_TIME           = 'startTime'
RETURN_MAX_ALARM_SEVERITY   = 'maxAlarmSeverity'
RETURN_ERRORINFO            = 'errinfo'
RETURN_CURTIME              = 'curTime'
RETURN_IS_CRACK             = 'iscrack'

SYNO_SCHEDULE_SUN        = 0x01
SYNO_SCHEDULE_MON        = 0x02
SYNO_SCHEDULE_TUE        = 0x04
SYNO_SCHEDULE_WED        = 0x08
SYNO_SCHEDULE_THU        = 0x10
SYNO_SCHEDULE_FRI        = 0x20
SYNO_SCHEDULE_SAT        = 0x40

## System setting
CONFIG_DEF_GROUP_KEY     = "defaultGroup"
CONFIG_UPDATE_KEY        = "updateBeforeScan"
CONFIG_SCHEDULE          = "schedule"
CONFIG_SCHEDULE_TASKID   = "scheduleTaskId"
CONFIG_IS_TESTSITE       = "is_testsite"

# Old version
CONFIG_ENABLE_SCHEDULE   = "enableSchedule"
CONFIG_SCHEDULE_WEEKDAY  = "weekday"
CONFIG_SCHEDULE_HOUR     = "hour"
CONFIG_SCHEDULE_MINUTE   = "minute"
##

CONFIG_LAST_SCAN_ALL_TIME    = "lastScanTime"

SYNOSECURITY_MAIL_TAG        = "SecurityScanAlarm"
## Binary
SYSTEM_PATH                 = '/usr/syno/bin/securityscan'
SYSTEM_SYSNOTIFY            = "{}/synonotifycustom".format(SYSTEM_PATH)
SYSTEM_SYNODSINFO           = "synodsinfo"

TMP_PATH                    = '/var/services/tmp/'

MAIN_SCANNER_PIDFILE        = "/run/synosecurityscan.pid"
MAIN_UPDATE_PIDFILE         = "/run/synosecurityScanUpdate.pid"
IPC                         = "/run/synosecurityscan.sock"
SYSTEM_SETTING_FILE         = "/usr/syno/etc/securityscanSetting.json"
SYSTEM_SETTING_FILE_TMP     = "{0}/securityscanSettingTmp.json".format(TMP_PATH)
START_TIME_TMP              = "{0}/securityscanStartTime.tmp".format(TMP_PATH)
MAX_IPC_NR                  = 1
POOL_PROCESS_NUM            = 4
BUFSIZ                      = 8196

SOCKET_TIMEOUT              = 20
STOP_TIMEOUT                = 10
MULTIPROCESS_TIMEOUT        = 99999


SOCKET_ACK                  = "ack"
RUNNING_ITEM                = "runningItem"
CMD_FIXME_ACTION            = "fixmeAction"


SECURITY_DB_PREFIX            = "/var/dynlib/securityscan/"
SYSTEM_SYNOSECURITY_SCAN_CMD  = "{0} {1}/SecurityScan.py --action DBUpdate && {0} {1}/SecurityScan.py --action StartScan --rules ALL --notify 1"
SYSTEM_SYNOSECURITY_SCAN_CMD  = SYSTEM_SYNOSECURITY_SCAN_CMD.format('/usr/bin/python2', SYSTEM_PATH)
RULE_RUNNER_PATH            = "{}/_RuleRunner.py".format(SYSTEM_PATH)

RESULT_FILE                 = "/var/lib/securityscan/securityscanResult.json"
RESULT_FILE_TMP             = "{0}/securityscanResult.json".format(TMP_PATH)

## Note: Also used in dsm/modules/SystemInfoApp/cgi/SystemInfo.cpp GetSecurityScanStatus()
SYSTEM_RESULT_FILE            = "/var/lib/securityscan/systemResult.json"
SYSTEM_RESULT_FILE_TMP        = "{0}/systemResult.json".format(TMP_PATH)
SYSTEM_RESULT_SYSSTATUS       = "sysStatus"
SYSTEM_RESULT_ITEMS           = "items"

CUSTOM_LIST_FILE            = "/usr/syno/etc/securityscan/customList.json"
CUSTOM_LIST_FILE_TMP        = "{0}/customList_tmp.json".format(TMP_PATH)

DB_NAME                     = "ruleDB"
UTIL_NAME                   = "dbutils"
SECURITY_DB_PATH            = SECURITY_DB_PREFIX + DB_NAME + '/'
SECURITY_UTIL_PATH          = SECURITY_DB_PREFIX + UTIL_NAME + '/'
DB_LIST_PATH                = SECURITY_DB_PATH + 'DBList.json'
DB_LIST_GPG_PATH            = SECURITY_DB_PATH + 'DBList.json.gpg'
DB_LIST_TMP_PATH            = '{0}/DBList.json.tmp'.format(TMP_PATH)
# Demain name and URL for DB info
DB_URL_DOMAIN_NAME     = "dataupdate.synology.com"
DB_URL_DOMAIN_NAME_TESTSITE = "dataupdatetest.synodev.com"
# https://dataupdatetest.synodev.com/securityscan/v1/7/cedarview
DB_URL                 = "https://%s/securityscan/v1/%s/%s"

CHECKSUM_FILE_RULE_KEY      = "rules"
CHECKSUM_FILE_SO_KEY        = "so"
CHECKSUM_FILE_UTIL_KEY      = "dbutils"
DB_SO_PATH                  = SECURITY_DB_PATH + "security_scan.so"

## FIXME change to global URL
UPDATE_SOCKET_TIMEOUT       = 30
DB_PATH_TMP                 = SECURITY_DB_PREFIX + "ruleDB.new"
DB_DOWNLOAD_SAVE_PATH       = SECURITY_DB_PREFIX + "securityscan-db.txz.gpg"
DB_PATH_TAR_TMP             = SECURITY_DB_PREFIX + "securityscan-db.txz"
DB_PATH_BAK                 = SECURITY_DB_PREFIX + "ruleDB.bak"
UTIL_PATH_BAK               = SECURITY_DB_PREFIX + "dbutils.bak"

DB_EXTRACT_CMD              = "tar xhf %s -C %s" % (DB_PATH_TAR_TMP, DB_PATH_TMP)
DB_EXTRACT_CHOWN_CMD        = "chown system:system -R %s" % DB_PATH_TMP

## Notice: it is also related to apparmor "usr.syno.synoman.webman.initdata.cgi B#65464"
STRING_PATH                 = '/var/dynlib/securityscan/texts'
STRING_PATH_BAK             = '/var/dynlib/securityscan/texts.bak'

## INFO
SECURITY_INFO_PATH          = SECURITY_DB_PREFIX + "INFO"
SECURITY_INFO_PATH_BAK      = SECURITY_DB_PREFIX + "INFO.bak"

## Signature
GPG_DECRYPTION              = "gpg --ignore-time-conflict --ignore-valid-from --homedir /usr/syno/securityscan %s" % DB_DOWNLOAD_SAVE_PATH
GPG_DECRYPTION_CHECKSUM     = "gpg --ignore-time-conflict --ignore-valid-from --homedir /usr/syno/securityscan -o %s %s" % (DB_LIST_TMP_PATH, DB_LIST_GPG_PATH)

## ======================== Define  ==============================
CMP_GREATER = 1
CMP_LESS    = 2
CMP_EQUAL   = 0



DEFAULT_NON_COMP_VERSION = '1.0-0~5.0-4490'
#==========================Result column============================#
DEBUG = False

## Note: Also used in dsm/modules/SystemInfoApp/js/SystemHealthWidget.js
## System Status
SYSTEM_STATUS_UPDATING      = 'updating'
SYSTEM_STATUS_RUNNING       = 'running'
SYSTEM_STATUS_STOPPING      = 'stopping'
SYSTEM_STATUS_CRACK         = 'crack'
SYSTEM_STATUS_DANGER        = 'danger'
SYSTEM_STATUS_RISK          = 'risk'
SYSTEM_STATUS_WARNING       = 'warning'
SYSTEM_STATUS_SAFE          = 'safe'
SYSTEM_STATUS_FIRST         = 'firstScan'
SYSTEM_STATUS_OUT_OF_DATE   = 'outOfDate'

## Rules owner
RESULT_GROUP                = "group"
RESULT_CATEGORY             = "category"
RESULT_STR_ID               = "strId"        ## key in string system
RESULT_METHOD               = "method"            ## from rule modules
RESULT_STATUS               = "status"        ## from rule modules
RESULT_ACTION               = "action"        ## from rule modules
RESULT_SEVERITY             = "severity"    ## from rule modules
RESULT_CATEGORY             = "category"    ## from rule modules

## Framework
RESULT_ID                   = "id"            ## from rule modules
RESULT_UPDATE_TIME          = "update"
#==================================================================#

## Group
GROUP_HOME                  = "home"
GROUP_COMPANY               = "company"
GROUP_CUSTOM                = "custom"

##Category
CATEGORY_UPDATE             = "update"
CATEGORY_USERINFO           = "userInfo"
CATEGORY_MALWARE            = "malware"
CATEGORY_NETWORK            = "network"
CATEGORY_SECURITY_SETTING   = "securitySetting"
CATEGORY_SYSTEM_CHECK       = "systemCheck"
ALL_CATEGORY                = [CATEGORY_UPDATE, CATEGORY_USERINFO, CATEGORY_MALWARE, CATEGORY_NETWORK, CATEGORY_SECURITY_SETTING, CATEGORY_SYSTEM_CHECK]

STATUS_RUNNING              = "running"
STATUS_NON_SCAN             = "non_scan"
SZ_TOTAL                    = "total"
SZ_PASS                     = "pass"        #checked and pass
SZ_FAIL                     = "fail"        #checked and fail
SZ_SKIP                     = "skip"                #if any pre-condiction not satisfy
SZ_NONE_CHECK               = "nonChecked"  # The item have never checked
SZ_ERROR                    = "error"  #if any 'error' occurs
ALL_STATUS                  = [SZ_PASS, SZ_FAIL, STATUS_RUNNING, SZ_SKIP, SZ_NONE_CHECK, SZ_ERROR]

# Level
LEVEL_DANGER                = "danger"
LEVEL_RISK                  = "risk"
LEVEL_WARNING               = "warning"
LEVEL_OUT_OF_DATE           = "outOfDate"
LEVEL_INFO                  = "info"
## Notice: Have to order in piority
ALL_LEVEL                   = [LEVEL_DANGER, LEVEL_RISK, LEVEL_WARNING, LEVEL_OUT_OF_DATE, LEVEL_INFO]

##Method
METHOD_ACTION                = 'methodAction'
METHOD_ACTION_VAL            = 'methodActionVal'
METHOD_ACTION_LINK           = 'link'
METHOD_LINK_APP_STR          = 'methodLinkOpenAppStr'
METHOD_ACTION_FIXME          = 'fixme'

##Action
ACTION_STR_KEY               = 'actionKey'
ACTION_REPLACE_VAR           = 'actionVar'
ACTION_EXTRA                 = 'actionExtra'

SYNO_PF_TEST_SERVER       = "checkport.synology.com"
SYNO_PF_TEST_SERVER_IP    = None
SYNO_PF_TEST_SERVER_PORT  = 82
IPTABLE                   = "/sbin/iptables"
S01                       = "/usr/syno/bin/syno_iptables_common"
NETSTAT                   = "/bin/netstat"
BUFSIZ                    = 4096

StrMap = {
    "fail": SZ_FAIL,
    "skip": SZ_SKIP,
    "success": SZ_PASS,
    "error": SZ_ERROR,
}

BADGE_UPDATE_CMD            = "/usr/syno/bin/synoappnotify -c SYNO.SDS.SecurityScan.Instance -u %d @administrators"

CONFIG_LOGANALYZER_SETTING = "/usr/syno/etc/loganalyzer/security_advisor.json"
