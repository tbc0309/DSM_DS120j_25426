#!/usr/bin/python2


import os


KEY_SUPPORT_SYNOLOGAND = 'support-synologand'


def validate_synolog_conf(synolog_conf):
    if KEY_SUPPORT_SYNOLOGAND not in synolog_conf.conf:
        return True
    if type(synolog_conf.conf[KEY_SUPPORT_SYNOLOGAND]) is not bool:
        return False
    return True


def generate_syslog_ng_conf(synolog_conf):
    if not synolog_conf.is_key_enabled(KEY_SUPPORT_SYNOLOGAND):
        return None

    return [
        {
            'type': 'rewrite',
            'name': 'r_synologand',
            'content': None
        },
        {
            'type': 'destination',
            'name': 'd_synologand',
            'content': None
        },
    ]
