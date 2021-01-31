from utils import *

__platform = None

def getSynoBuildNumber():
    versionFilePath = '/etc.defaults/VERSION'
    if not os.path.isfile(versionFilePath):
        SYSLOG(syslog.LOG_ERR, "file not exist: " + versionFilePath)
        return None
    else:
        val = execute("get_key_value /etc.defaults/VERSION buildnumber")
        if 0 >= len(val):
            SYSLOG(syslog.LOG_ERR, "len > 0 :" + len(val))
            return None
        else:
            return val[0]

def isRouter():
    if __platform is None:
        __platform = getSynoInfoValue("unique")[0].split('_')[2]
    return 'rt1900ac' == __platform
