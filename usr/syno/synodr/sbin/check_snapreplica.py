#!/usr/bin/env python
import subprocess
import json

def share_has_snapshot(shares):
    SHARE_SNAPSHOT_COUNT_ARGUMENTS = ['synosharesnapshot', 'snapcount', 'get']
    for share in shares:
        output = subprocess.Popen(SHARE_SNAPSHOT_COUNT_ARGUMENTS + [share], stdout=subprocess.PIPE).communicate()[0]
        snap_count = int(output.strip())
        if snap_count > 0:
            return True

    return False

def share_has_schedule(shares):
    SHARE_SCHEDULE_GET_ARGUMENTS = ['synosharesnapshot', 'sched', 'get_task_id']
    for share in shares:
        output = subprocess.Popen(SHARE_SCHEDULE_GET_ARGUMENTS + [share], stdout=subprocess.PIPE).communicate()[0]
        sched_id=len(output.strip())
        if sched_id > 0:
            return True
    return False

def check_json_key(data, key):
    return data is not None and key in data

def send_webapi(api, method, ver, params = []):
    argument = ['synowebapi', '--exec', 'api=' + api, 'method=' + method, 'version=' + ver]
    for param in params:
        argument.append(param)
    resp = json.loads(subprocess.Popen(argument, stdout=subprocess.PIPE).communicate()[0])
    if not check_json_key(resp, 'success'):
        return False, None
    elif resp['success'] == False:
        return False, resp['error']
    else:
        return True, resp['data'] if check_json_key(resp, 'data') else None

def list_luns():
    ret, data = send_webapi('SYNO.Core.ISCSI.LUN', 'list', '1')
    if ret == False or not check_json_key(data, 'luns') or type(data['luns']) != type([]):
        return False, []
    return True, data['luns']

def lun_has_schedule():
    list_lun_ret, luns = list_luns()
    if list_lun_ret == False:
        return False

    for lun in luns:
        if not check_json_key(lun, 'lun_id'):
            continue
        lid = int(lun['lun_id'])
        ret, data = send_webapi('SYNO.Core.Storage.iSCSILUN', 'load_sched_snapshot', '1', ['lid=' + str(lid)])
        if ret == False or type(data) != type([]):
            continue

        for sched in data:
            if check_json_key(sched, 'general') and check_json_key(sched['general'], 'tid') and int(sched['general']['tid']) > 0:
                return True

    return False

def lun_has_snapshot():
    ret, data = send_webapi('SYNO.Core.ISCSI.LUN', 'list_snapshot', '1')
    if ret == False or not check_json_key(data, 'count'):
        return False
    snap_count = int(data['count'])
    return snap_count > 0

def main():
    import sys

    ENUM_SHARE_ARGUMENTS = ['synoshare', '--enum', 'LOCAL']
    shares = subprocess.check_output(ENUM_SHARE_ARGUMENTS).split('\n')[2:]
    shares = filter(lambda x: len(x) > 0, shares)

    ret_code = 0 if lun_has_snapshot() or lun_has_schedule() or share_has_snapshot(shares) or share_has_schedule(shares) else -1

    sys.exit(ret_code)

if __name__ == '__main__':
    main()

