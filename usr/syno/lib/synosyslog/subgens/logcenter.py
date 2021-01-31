#!/usr/bin/python2


import os
import subprocess
import StringIO
import ConfigParser


KEY_LOG_CENTER = 'log-center'
KEY_FACILITY = 'facility'


def validate_synolog_conf(synolog_conf):
    if KEY_LOG_CENTER not in synolog_conf.conf:
        return True
    log_center_conf = synolog_conf.conf[KEY_LOG_CENTER]

    if type(log_center_conf) is not dict:
        return False

    if KEY_FACILITY not in log_center_conf:
        return False
    facility = log_center_conf[KEY_FACILITY]

    if type(facility) is not unicode:
        return False
    if len(facility) == 0:
        return False

    return True


def generate_syslog_ng_conf(synolog_conf):
    if not synolog_conf.is_key_enabled(KEY_LOG_CENTER):
        return None

    gen_classes = [Notify, Remote, Archive]

    confs = []

    for gen_class in gen_classes:
        try:
            gen_obj = gen_class(synolog_conf)
            confs.extend(gen_obj.gen())
        except LogCenterError:
            continue

    return confs


class LogCenterError(Exception):
    pass


class Setting(object):
    def __init__(self, path, sectionless=False):
        try:
            if not sectionless:
                self._setting = self._load_normal(path)
            else:
                self._setting = self._load_sectionless(path)
        except IOError:
            raise LogCenterError()

    def get(self, *args):
        if len(args) == 2:
            section = args[0]
            key = args[1]
            return self._get_normal(section, key)
        if len(args) == 1:
            key = args[0]
            return self._get_sectionless(key)
        raise Exception('never here')

    def has(self, *args):
        if len(args) == 2:
            section = args[0]
            key = args[1]
            return self._has_normal(section, key)
        if len(args) == 1:
            key = args[0]
            return self._has_sectionless(key)
        raise Exception('never here')

    def _load_normal(self, path):
        setting = ConfigParser.ConfigParser()
        with open(path) as f:
            setting.readfp(f)
        return setting

    def _load_sectionless(self, path):
        setting = ConfigParser.ConfigParser()
        io = StringIO.StringIO()

        with open(path) as f:
            io.write('[{}]\n'.format(Setting.DUMMY_SECTION))
            io.write(f.read())
            io.seek(0, os.SEEK_SET)

        setting.readfp(io)

        return setting

    def _get_normal(self, section, key):
        value = self._setting.get(section, key)
        value = value.strip('"')
        return value

    def _get_sectionless(self, key):
        return self._get_normal(Setting.DUMMY_SECTION, key)

    def _has_normal(self, section, key):
        return self._setting.has_option(section, key)

    def _has_sectionless(self, key):
        return self._has_normal(Setting.DUMMY_SECTION, key)

    DUMMY_SECTION = 'dummy_section'


class Base(object):
    def __init__(self, synolog_conf):
        self.app_id = synolog_conf.app_id
        self.facility = synolog_conf.conf[KEY_LOG_CENTER][KEY_FACILITY]

    def gen(self):
        raise Exception('not implemented')


class Upstart(object):
    @staticmethod
    def is_job_up(job_name):
        output = Upstart._run_command(['/sbin/initctl', 'status', job_name])
        job_up = 'start/running' in output or 'start/post-start' in output
        if not job_up:
            print 'INFO: upstart job "{}" is not up: {}'.format(job_name, output)
        return job_up

    @staticmethod
    def _run_command(command):
        popen = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = popen.communicate()
        return out.strip() + err.strip()


class Notify(Base):
    def gen(self):
        confs = []

        if not Upstart.is_job_up('syslog-notify'):
            return confs

        setting = Setting(Notify.SETTING_PATH)

        # no need to check setting.get('eps', 'notify_enable') for overview log count chart
        conf = self._gen_eps_conf()
        confs.append(conf)

        if setting.get('pri', 'notify_enable') == '1':
            conf = self._gen_pri_conf()
            confs.append(conf)

        for pat_idx in ('1', '2', '3'):
            section = 'pat_{}'.format(pat_idx)
            if setting.get(section, 'notify_enable') == '1' and setting.get(section, 'notify_pat') != '':
                conf = self._gen_pat_conf(pat_idx)
                confs.append(conf)

        return confs

    def _gen_eps_conf(self):
        return [
            {
                'type': 'destination',
                'name': 'd_syno_dest_arch',
                'content': None
            },
        ]

    def _gen_pri_conf(self):
        return [
            {
                'type': 'filter',
                'name': 'f_syno_severity',
                'content': None
            },
            {
                'type': 'destination',
                'name': 'd_syno_severity_notification',
                'content': None
            },
        ]

    def _gen_pat_conf(self, pat_idx):
        return [
            {
                'type': 'filter',
                'name': 'f_syno_keyword_{}'.format(pat_idx),
                'content': None
            },
            {
                'type': 'destination',
                'name': 'd_syno_keyword_notification_{}'.format(pat_idx),
                'content': None
            },
        ]

    SETTING_PATH = '/etc/synosyslog/notify.conf'


class Remote(Base):
    def gen(self):
        if not Upstart.is_job_up('pkg-LogCenter-client'):
            return []

        rewrite_args = {
            'facility': self.facility,
        }

        return [
            [
                {
                    'type': 'filter',
                    'name': 'f_syno_client_sev',
                    'content': None
                },
                {
                    'type': 'rewrite',
                    'name': 'r_remote_{}'.format(self.app_id),
                    'content': [
                        Remote.FMT_REWRITE.format(**rewrite_args)
                    ]
                },
                {
                    'type': 'filter',
                    'name': 'f_syno_client_fac',
                    'content': None
                },
                {
                    'type': 'destination',
                    'name': 'd_syno_internet',
                    'content': None
                },
            ]
        ]

    FMT_REWRITE = 'set("{facility}", value("PROGRAM"));'


class Archive(Base):
    def gen(self):
        if not Upstart.is_job_up('pkg-LogCenter-localarchive'):
            return []

        return [
            [
                {
                    'type': 'destination',
                    'name': 'd_syno_local_arch_db',
                    'content': None
                },
            ]
        ]
