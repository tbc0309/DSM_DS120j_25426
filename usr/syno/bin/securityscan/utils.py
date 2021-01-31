# Copyright (c) 2000-2014 Synology Inc. All rights reserved.
from Define import *
import os
import inspect
import syslog
import traceback

## ============ privilege api ================
class SynoCriticalSection(object):
    def __enter__(self):
        import pwd, os
        self.old_euid = os.geteuid()
        root_uid = pwd.getpwnam('root').pw_uid
        os.seteuid(root_uid)
    def __exit__(self ,type, value, traceback):
        import pwd, os
        os.seteuid(self.old_euid)

class DictResult(object):
    ## Private variable
    dictPrototype = {
        RESULT_ID: '',
        RESULT_GROUP: '',
        RESULT_CATEGORY: '',
        RESULT_STR_ID: '',
        RESULT_SEVERITY: '',
        RESULT_METHOD: '',
        RESULT_STATUS: '',
        RESULT_ACTION: ''
    }

    ## Class methods
    def __init__(self):
        elements = ['_non_comp_version', '_group', '_category', '_severity', '_strId',
                'getStatus', 'getMethod', 'getAction']
        for _key in elements:
            if _key not in dir(self):
                raise KeyError("The rule must have to implement %s", _key)

    def _statusRetCheck(self, val):
        statusRet = [SZ_PASS, SZ_FAIL, SZ_SKIP, SZ_ERROR]
        if val not in statusRet:
            SYSLOG(syslog.LOG_ERR, "The value of status must in %s" % " ".join(statusRet))
            return False
        return True

    def _methodRetCheck(self, val):
        '''
            val = {
                METHOD_ACTION = ''
                METHOD_ACTION_VAL = '' (Optional)
            }
        '''
        if dict != type(val):
            SYSLOG(syslog.LOG_ERR, "The value of methodSet() must be dict")
            return False
        if not val.has_key(METHOD_ACTION):
            SYSLOG(syslog.LOG_ERR, "The value of methodSet() must have %s" % METHOD_ACTION)
            return False
        return True

    def _actionRetCheck(self, val):
        '''
            val = {
                ACTION_STR_KEY = ''
                ACTION_REPLACE_VAR = {} (Optional)
                ACTION_EXTRA = {} (Optional)
            }
        '''
        ## Allow empty val
        if not val:
            return True

        if dict != type(val):
            SYSLOG(syslog.LOG_ERR, "The value of actionSet() must be dict")
            return False

        if not val.has_key(ACTION_STR_KEY):
            SYSLOG(syslog.LOG_ERR, "The value of actionSet() must have %s" % ACTION_STR_KEY)
            return False

        return True

    def getDict(self):
        status = self.getStatus()
        if not self._statusRetCheck(status):
            raise KeyError("Bad value of status: %s" % status)
        self.dictPrototype[RESULT_STATUS] = status

        ## Only fail need to get action
        if SZ_FAIL == status:
            # self.getAction() and self.getMethod must call after getStatus()
            method = self.getMethod()
            if not self._methodRetCheck(method):
                raise KeyError("Bad value of method")
            self.dictPrototype[RESULT_METHOD] = method

            action = self.getAction()
            if not self._actionRetCheck(action):
                raise KeyError("Bad value of action")
            self.dictPrototype[RESULT_ACTION] = action
        else:
            self.dictPrototype[RESULT_METHOD] = {}
            self.dictPrototype[RESULT_ACTION] = {}

        if (DEBUG):
            print self.dictPrototype
        return self.dictPrototype

    def RunCRoutine(self, func_name, runFixme=False):
        import ctypes
        import json

        lib = ctypes.cdll.LoadLibrary(SECURITY_DB_PATH + "security_scan.so")

        fn = lib["Create%s" %func_name]
        fn.restype = ctypes.c_ulonglong
        obj = fn()

        fn = lib["Fixme%s" %func_name] if runFixme else lib["Run%s" %func_name]
        fn.argtypes = [ctypes.c_ulonglong]
        fn.restype = ctypes.c_char_p
        ret = fn(obj)

        fn = lib["Delete%s" %func_name]
        fn.argtypes = [ctypes.c_ulonglong]
        fn(obj)

        return json.loads(ret)

############################# Rule APIs #############################
def tracelog(strTrace):
    log_lines = strTrace.split('\n')
    for line in log_lines:
        if len(line):
            SYSLOG(syslog.LOG_ERR, line)

def SYSLOG(log_type, log_str):
    callerframerecord = inspect.stack()[1]
    frame = callerframerecord[0]
    info = inspect.getframeinfo(frame)
    syslog.syslog(log_type, info.filename+':'+ str(info.lineno) + ':' + info.function+'(): '+ log_str)

def getSynoInfoValue(key):
    confPath = '/etc/synoinfo.conf'
    if not os.path.isfile(confPath):
        SYSLOG(syslog.LOG_ERR, "file not exist: " + confPath )
        return None
    else:
        cmd = '/bin/get_key_value %s %s' % (confPath, key)
        val = execute(cmd)
        if 0 >= len(val):
            SYSLOG(syslog.LOG_ERR, "len > 0 :" + len(val) )
            return None
        else:
            return val

def execute(args, blSplit = True):
    from subprocess import Popen, STDOUT, PIPE
    process = Popen(args, shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    text = process.stdout.read()
    text = text.strip()
    try:
        text = text.decode('utf8')
    except Exception, e:
        result = []
        for line in text.split('\n'):
            try:
                line = line.decode('utf8')
                result.append(line)
            except Exception:
                pass
        return result

    if (blSplit):
        return text.split('\n')
    else:
        return text

def execWebAPI(api, method, version, **kwargs):
    """
    Send web API to localhost by /usr/syno/bin/synowebapi and return response (in Json) as Python dict.
    kwargs are parameters to web API. For example, following creates a share via web API.

    resp = execWebAPI("SYNO.Core.Share", "create", 1,
        name="public",
        shareinfo={
            "name": "public",
            "vol_path": "/volume1",
            "desc": "Public Shared Folder"
        }
    )
    """
    import json
    import subprocess

    cmd = ["/usr/syno/bin/synowebapi", "--exec"]
    cmd.append("api=" + api)
    cmd.append("method=" + method)
    cmd.append("version=" + str(version))
    for key, value in kwargs.items():
        cmd.append(key + "=" + json.dumps(value))

    retVal = None;

    try:
        with SynoCriticalSection() as cs:
            with open("/dev/null", "w") as null_f:
                raw_resp = subprocess.check_output(cmd, stderr=null_f)
            retVal = json.loads(raw_resp)
    except ValueError as e:
        SYSLOG(syslog.LOG_ERR, "Failed to parse web API response (" + str(e) + ")")
    except Exception as e:
        SYSLOG(syslog.LOG_ERR, "Failed to execute web API (" + str(e) + ")")
    return retVal

def checkEnabled(strServiceName):
    synoSevcmd = '/usr/syno/sbin/synoservice --is-enabled %s' % (strServiceName)
    with SynoCriticalSection() as cs:
        ret = execute(synoSevcmd)
    if 0 >= len(ret):
        SYSLOG(syslog.LOG_ERR, "len > 0")
        return None

    if 'enabled' in ret[0]:
        return True
    else:
        return False

class SYNOTestOpenport(object):
    """
    Test Port is routable or not on WAN

    >>> rules = {"rule0": [22, 23], "rule1":[5000, 5001]}
    >>> with SYNOTestOpenport() as test:
    ...     ret = test(rules)
    """
    def __init__(self):
        import os, socket
        global SYNO_PF_TEST_SERVER_IP

        ## Load the netstat status
        cmd = "{netatat} -nap 2>/dev/null".format(netatat=NETSTAT)
        ret = os.popen(cmd).read()
        ret = [_ for _ in ret.split('\n') if _]
        ret = [[_ for _ in line.split() if _] for line in ret]
        self.netstat = ret

        self._NATPortMap = []
        self._fwTransRuleTable = []
        self._bypass = False
        self._forceExit = False

        ip = socket.getaddrinfo(SYNO_PF_TEST_SERVER, SYNO_PF_TEST_SERVER_PORT)
        ip = list(set([_[-1][0] for _ in ip]))
        SYNO_PF_TEST_SERVER_IP = ip
    def __enter__(self):
        """ Enable the NAT mode """
        import os

        cmd = "{S01} load_nat_mod forwarding_test"
        cmd = cmd.format(S01=S01)
        os.popen(cmd).read()
        return self
    def __exit__(self, *arg):
        """ Disable the NAT mode if all NAT rule is removed """
        import os, signal

        self.cleanIpatables()
        cmd = "{S01} unload_nat_mod forwarding_test"
        cmd = cmd.format(S01=S01)
        os.popen(cmd).read()

        ## if get sigTerm which get by pool.terminate() and then kill the process
        if self._forceExit:
            os.kill(os.getpid(), signal.SIGKILL)
    def sigHandler(self, sig, frame):
        import sys
        self._forceExit = True
        sys.exit()
    def __call__(self, rules, precheck=True, bypass=False, fwTrans=True, timeout=10):
        """ Run SYNOTestOpenport logical """
        import signal

        signal.signal(signal.SIGTERM, self.sigHandler)
        blTrans = False
        self._bypass = bypass

        if bypass:
            for ip in SYNO_PF_TEST_SERVER_IP:
                self.allowHost(ip)
        elif fwTrans:
            blTrans = True

        ports = [port for key in rules for port in rules[key]]
        ports = list(set(ports))
        if precheck:
            ports = [_ for _ in ports if self.checkNestsut(_)]

        ## Main logical to check port is exposed on WAN
        ports = self.Listener(ports, timeout, blTrans)

        if bypass:
            for ip in SYNO_PF_TEST_SERVER_IP:
                self.allowHost(ip, False)

        ret = {key: [port for port in rules[key] if port in ports] for key in rules}
        return ret
    def cleanIpatables(self):
        if self._bypass:
            for ip in SYNO_PF_TEST_SERVER_IP:
                self.allowHost(ip, False)
        if self._NATPortMap:
            self.NATRule(self._NATPortMap, False)
        if self._fwTransRuleTable:
            self.fwTransApply(ruleTable = self._fwTransRuleTable, blAdd = False)

    def checkNestsut(self, port, rule=["0.0.0.0", "::[^:]*"]):
        """
        check the port is enable via netstat

        >>> foo = SYNOTestOpenport()
        >>> foo.checkNestsut(22)
        True
        >>> foo.checkNestsut(80)
        True
        >>> foo.checkNestsut(-9999)
        True
        >>> foo.checkNestsut(12345)
        False
        """
        def wrapper(based, port, proto, rule):
            import re

            match = re.compile(r"^{1}:{0}|{2}:{0}$".format(port, *rule))

            ## Get all status on particular protocol
            ret = based
            ret = [_ for _ in ret if _ and _[0] == proto]
            ret = [_ for _ in ret if match.match(_[3])]
            return 0 != len(ret)
        proto = "tcp" if port > 0 else "udp"
        return wrapper(self.netstat, abs(port), proto, rule)
    def Listener(self, ports, timeout, blTrans):
        """
        Listen ports agent

        @port  - check port list
        return - open port list
        """
        def revSkMap(listener, sk, key="src"):
            for _ in listener:
                if _["sk"] == sk:
                    return _[key]
            return None
        import select
        import time

        ## Start Listen - Get the (listened port, socket)
        listener = [self.ListenOnePort(p) for p in ports]
        fds      = [_["sk"] for _ in listener]
        self._NATPortMap = [[_["src"], _["dst"]] for _ in listener]
        if blTrans:
            self._fwTransRuleTable = self.fwTransApply(portMapping = listener, blAdd = True)

        ## Add port forward rule and send command to server
        self.NATRule(self._NATPortMap)

        ports = []
        try:
            self.sendCmd2Server([_["src"] for _ in listener])
            now = time.time()
            while fds and time.time() - now < timeout:
                r, w, e = select.select(fds, [], [], 0)
                for sk in r:
                    src = revSkMap(listener, sk, key="src")
                    if src > 0:    ## TCP
                        cli, addr = sk.accept()
                        cli.close()
                        ports += [src]
                        fds.remove(sk)
                    else:        ## UDP
                        data, addr = sk.recvfrom(BUFSIZ)
                        ports += [src]
                        fds.remove(sk)
        except Exception as e:
            raise
        except KeyboardInterrupt as e:
            print "Exit by Ctrl+C"
        finally:
            return ports
    def ListenOnePort(self, src, portRange=(10000, 20000)):
        """
        Listen and return the {"src": sport, "dst": dport, "sk": socket obj}

        >>> foo = SYNOTestOpenport()
        >>> ret = foo.ListenOnePort(23, portRange=(10000, 20000))
        >>> ret["port"] >= 10000 and ret["port"] <= 20000
        True
        >>> ret["sk"].close()
        """
        import random
        import socket

        if src > 0:
            proto = socket.SOCK_STREAM
        else:
            proto = socket.SOCK_DGRAM

        sk = socket.socket(socket.AF_INET, proto)
        while True:
            port = random.randint(*portRange)
            try:
                sk.bind(("", port))
            except Exception as e:
                continue
            else:
                if src > 0:
                    sk.listen(1)
                break
        if src < 0:
            port = -1*port
        return {"dst": port, "sk": sk, "src": src}
    def NATRule(self, portMap, add=True):
        """ iptable Rule add / del """
        def wrapper(**kwarg):
            """ The exactly iptable rules command """
            import os

            cmd = "{iptables} -t nat {op} PREROUTING " \
                        "-p {protocol} -m {protocol} "\
                        "-s {src} --dport {sport} "\
                        "-j REDIRECT --to-ports {dport}"
            cmd = cmd.format(**kwarg)
            os.popen(cmd).read()

        for ip in SYNO_PF_TEST_SERVER_IP:
            for src, dst in portMap:
                src, dst = int(src), int(dst)
                kw = {}
                kw["iptables"] = IPTABLE
                kw["op"]       = "-A" if add else "-D"
                kw["protocol"] = "tcp" if src > 0 else "udp"
                kw["src"]      = ip
                kw["sport"]    = abs(src)
                kw["dport"]    = abs(dst)

                wrapper(**kw)
    def sendCmd2Server(self, ports):
        """ Send port list to server """
        import socket

        sk = socket.create_connection((SYNO_PF_TEST_SERVER, SYNO_PF_TEST_SERVER_PORT))
        if 1024 < len(",".join([str(_) for _ in ports])):
            raise IOError("Too many ports")
        sk.send(",".join([str(_) for _ in ports]))
        sk.close()
    def allowHost(self, addr, isAdd=True):
        """ Add / Del iptable rule for port check server """
        import os

        kw = {}
        kw["iptables"] = IPTABLE
        kw["op"]       = "-I" if isAdd else "-D"
        kw["src"]      = addr

        cmd = "{iptables} {op} INPUT -s {src} -j ACCEPT"
        cmd = cmd.format(**kw)
        os.popen(cmd).read()
    def fwTransApply(self, portMapping = None, ruleTable = None, blAdd = True):
        def _iptablesApply(ruleTable, blAdd):
            """ The exactly iptable rules command """
            import os
            kw = {
                'op': '-I' if blAdd else '-D'
            }

            ## Due to used INSERT so it need to do reverser for original order
            ruleTable.reverse()
            for r in ruleTable:
                r = r.format(**kw)
                os.popen(r).read()
        def _fwTransListGet(portMapping):
            import re

            rules = execute('iptables-save -t filter')
            dportRe = r"--dport(?:s)? ([\d,:]+) -"
            dregx = re.compile(dportRe)

            rulesApplyList = []
            for r in rules:
                newPortList = []
                oriPorts = dregx.search(r)

                if oriPorts:
                    oriPorts = oriPorts.group(1)
                    onePortList = [int(p) for p in oriPorts.split(',') if ':' not in p]
                    rangePortList = {int(p.split(':')[0]):int(p.split(':')[1]) for p in oriPorts.split(',') if ':' in p}

                    for i in portMapping:
                        p = abs(i['src'])
                        newPort = abs(i['dst'])
                        if p in onePortList:
                            newPortList.append(newPort)
                        else:
                            for pStart in rangePortList.keys():
                                pEnd = rangePortList[pStart]
                                if p >= pStart and p <= pEnd:
                                    newPortList.append(newPort)
                if newPortList:
                    newPortList = [str(port) for port in newPortList]
                    newRule = r.replace(oriPorts, ','.join(newPortList))
                    newRule = IPTABLE + ' ' + '{op}' + newRule[2:]
                    rulesApplyList.append(newRule)

            return rulesApplyList

        if blAdd:
            ruleTable = _fwTransListGet(portMapping)
        if ruleTable:
            _iptablesApply(ruleTable, blAdd)

        return ruleTable

