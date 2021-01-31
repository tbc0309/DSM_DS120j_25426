#!/usr/bin/python2


import os


FLAG_FILENAME = '/tmp/synosyslog.debug'
FMT_DEBUG = 'file("/tmp/synosyslog.debug.d/{}.log" template("$(format-json --scope all-nv-pairs)\\n"));'


def validate_synolog_conf(synolog_conf):
    return True


def generate_syslog_ng_conf(synolog_conf):
    if not os.path.exists(FLAG_FILENAME):
        return None

    return [
        {
            'type': 'destination',
            'name': 'd_syno_debug_{}'.format(synolog_conf.app_id),
            'content': [
                FMT_DEBUG.format(synolog_conf.app_id)
            ]
        }
    ]
