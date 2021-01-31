#!/usr/bin/python
from utils import *

class RuleDictResult(DictResult):
    _non_comp_version = [DEFAULT_NON_COMP_VERSION]
    _group = [GROUP_HOME, GROUP_COMPANY]
    _category = CATEGORY_NETWORK
    _severity = LEVEL_WARNING
    _strId = 'rule_lan_export'

    def getFirewallServiceNameList(self, strServiceName):
        synoSevcmd = '/usr/syno/sbin/synoservice --show-config %s' % (strServiceName)
        ret = execute(synoSevcmd)
        for config in ret:
            if (0 <= config.find('Required firewall section:')):
                sectionList = config.split(':')
                if (2 != len(sectionList)):
                    SYSLOG(syslog.LOG_ERR, "parsing error")
                    return None

                # sectionList[1] == "[cifs, ...]"
                rawFwSectionName = sectionList[1].strip()

                if (rawFwSectionName[0] != '['):
                    SYSLOG(syslog.LOG_ERR, "parsing error")
                    return None

                if (rawFwSectionName[-1] != ']'):
                    SYSLOG(syslog.LOG_ERR, "parsing error")
                    return None

                strFwSectionList = rawFwSectionName[1:-1]
                fwServieList = strFwSectionList.split(",")
                return fwServieList

        # not found
        return None

    def getFirewallServicePorts(self, strFwServiceName):
        synoSevcmd = '/usr/syno/bin/synofirewall --service %s | tail -n 1 | awk -F" " \'{print $2 " " $3}\'' % (strFwServiceName)
        strRawPorts = execute(synoSevcmd)[0]

        if (0 >= len(strRawPorts)):
            SYSLOG(syslog.LOG_ERR, "parsing error")
            return None

        #strRawPorts == "137,138,139,445 (tcp)"
        strTcpPorts = ""
        strUdpPorts = ""
        strAllPorts = ""
        if 'tcp' in strRawPorts:
            strTcpPorts = strRawPorts.split(' ')[0].strip()
        elif 'udp' in strRawPorts:
            strUdpPorts = strRawPorts.split(' ')[0].strip()
        else:
            strAllPorts = strRawPorts.split(' ')[0].strip()
        return {'tcp': strTcpPorts, 'udp': strUdpPorts, 'all': strAllPorts}

    def appendPort(self, listPorts ,strPort, protocol):
        if ('tcp' == protocol):
            listPorts.append(strPort)
        elif ('udp' == protocol):
            listPorts.append('-'+strPort)
        elif ('all' == protocol):
            listPorts.append(strPort)
            listPorts.append('-'+strPort)

    def toPortList(self, strPorts, protocol): #strPorts allow "123, 124-127, 255"
        if (None == strPorts or "" == strPorts):
            return []
        listPorts = strPorts.split(',')
        eListPorts = []
        for port in listPorts:
            if (-1 != port.find('-')):
                listBgEndportNum = port.split('-')
                for i in range(listBgEndportNum[0], listBgEndportNum[1]):
                    self.appendPort(eListPorts, i, protocol)
            else:
                self.appendPort(eListPorts, port, protocol)

        return eListPorts

    def getStatus(self):
        self.extra = []
        SZ_NAME = 'name'
        SZ_ENABLED = 'enabled'
        SZ_PORTS = 'ports'
        SZ_EXPOSED = 'exposed'
        lanServices = [
            #SZ_ENABLED: True/False/None
            #SZ_EXPOSED: [], expose port in this list

            {SZ_NAME:'samba',     SZ_ENABLED:None, SZ_PORTS: [],  SZ_EXPOSED: []},
            {SZ_NAME:'atalk',     SZ_ENABLED:None, SZ_PORTS: [],  SZ_EXPOSED: []},
            {SZ_NAME:'nfsd',      SZ_ENABLED:None, SZ_PORTS: [],  SZ_EXPOSED: []},
            {SZ_NAME:'bonjour',   SZ_ENABLED:None, SZ_PORTS: [],  SZ_EXPOSED: []},
            {SZ_NAME:'ssh-shell', SZ_ENABLED:None, SZ_PORTS: [],  SZ_EXPOSED: []}]

        #  synofirewall --service
        for service in lanServices:
            enableRet = checkEnabled(service[SZ_NAME])
            service[SZ_ENABLED] = enableRet;
            if (True == enableRet):
                fwServiceNameList = self.getFirewallServiceNameList(service[SZ_NAME])
                if (None == fwServiceNameList):
                    return SZ_SKIP
                allFwServicePorts = []
                for fwService in fwServiceNameList:
                    try:
                        dictFwServicePorts = self.getFirewallServicePorts(fwService)
                        tcpPortList = self.toPortList(dictFwServicePorts['tcp'], 'tcp')
                        udpPortList = self.toPortList(dictFwServicePorts['udp'], 'udp')
                        allPortList = self.toPortList(dictFwServicePorts['all'], 'all')
                        portList = tcpPortList + udpPortList + allPortList
                        allFwServicePorts += portList
                    except Exception as e:
                        SYSLOG(syslog.LOG_ERR, 'Error: %s' % e)
                        trace = traceback.format_exc()
                        tracelog(trace)
                service[SZ_PORTS] = allFwServicePorts

        allDisabled = True
        for service in lanServices:
            if (True == service[SZ_ENABLED]):
                allDisabled = False

        if (True == allDisabled):
            return SZ_SKIP
        else:
            rules = {item[SZ_NAME]: [int(strPort) for strPort in item[SZ_PORTS]] for item in lanServices}

            try:
                with SYNOTestOpenport() as test:
                    retRules = test(rules, precheck=False, timeout=30)
            except Exception as e:
                SYSLOG(syslog.LOG_ERR, 'Error: %s' % e)
                trace = traceback.format_exc()
                tracelog(trace)
                retRules = {}


            for key in retRules:
                if 0 != len(retRules[key]):
                    self.extra.append(key)

            if (0 < len(self.extra)):
                return SZ_FAIL
            else:
                return SZ_PASS

    def getMethod(self):
        self._plat = getSynoInfoValue("unique")[0].split('_')[2]
        if 'rt1900ac' == self._plat:
            methodVal = 'SYNO.SDS.NSMHome.Instance:SYNO.SDS.NSMHome.Security.Main'
        else:
            methodVal = 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.PublicAccess.Main:portforwardingtab'
            resp = execWebAPI("SYNO.Core.PortForwarding.RouterConf", "get", 1)
            if resp and resp["success"]:
                if not resp["data"]["router_brand"] and not resp["data"]["router_model"] and not resp["data"]["router_version"]:
                    methodVal = 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.Security.Main'

        method = {METHOD_ACTION: METHOD_ACTION_LINK, METHOD_ACTION_VAL: methodVal}
        return method

    def getAction(self):
        if not self.extra:
            return {}

        replaceStrMapping = {
            'samba': "_T('helptoc', 'winmacnfs_win')",
            'atalk': "_T('helptoc', 'winmacnfs_mac')",
            'nfsd': "_T('helptoc', 'winmacnfs_nfs')",
            'bonjour': "_T('firewall', 'firewall_service_desc_bonjour')",
            'ssh-shell': "_T('firewall', 'firewall_service_opt_ssh')"
        }
        replaceStr = [replaceStrMapping[i] for i in self.extra]
        return {
            ACTION_STR_KEY: 'action',
            ACTION_REPLACE_VAR: {
                '%0': ', '.join(replaceStr)
            }
        }
