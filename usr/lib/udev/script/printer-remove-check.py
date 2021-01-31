#!/usr/bin/python2
import argparse
import ConfigParser
import fcntl
import os
import StringIO
import subprocess
import sys
import tempfile
import time
import traceback


LOGGER = '/usr/bin/logger'
LOGGER_TAG = 'udev_printer'

LOCK_EX_NB = 0x0006  # LOCK_EX | LOCK_NB
LOCK_USBIDMAP = 0x20000
LOCK_TIMEOUT = 5
LOCK_WAIT_INTERVAL = 0.05

SZF_USBIP_USB_DEV_CONF = '/usr/syno/etc/usbdev.conf'
SZF_USBDEV_CONF_LOCK = '/run/synosdk/lock/lock_usbdev'

SZ_PREFIX_PRINTER = 'lp'

SZK_USBIP_USB_STATUS = 'status'
SZK_USBIP_USB_INTERFACE_PREFIX = 'interface_'
SZK_USBIP_USB_INTERFACE_NUMBER = 'interface_number'
SZK_USBIP_USB_BUS_NUMBER = 'bus number'
SZK_USBIP_USB_PROC_DEVICE = 'proc_dev'
SZK_USBIP_PRINTER_PRODUCER = 'producer'
SZK_USBIP_PRINTER_PRODUCTNAME = 'product name'

SZV_USBIP_USB_STATUS_PLUG_IN = 'plug_in'
SZV_USBIP_USB_STATUS_USBIP_INIT = 'usbip_init'
SZV_USBIP_USB_STATUS_USBIP_HANDLE = 'usbip_handle'
SZV_USBIP_USB_STATUS_PLUG_OUT = 'plug_out'

SZF_SYSFS_NUM_INTERFACES = 'bNumInterfaces'
SZF_SYSFS_MANUFACTURER = 'manufacturer'
SZF_SYSFS_PRODUCT = 'product'
SZF_SYSFS_UEVENT_DEVICE = 'DEVICE'

SZF_SYNOPRINT = '/usr/syno/bin/synoprint'
SZF_MFP_PID_FILE = '/var/run/usbipd.pid'

SIGUSR1 = 10

ERR_SUCCESS = 0x0000
ERR_BAD_PARAMETERS = 0x0D00
ERR_OPEN_FAILED = 0x0900
ERR_SYS_UNKNOWN = 0x8100


def log_msg(msg, priority='err'):
    return subprocess.call([LOGGER, '-p', priority, '-t', LOGGER_TAG, msg])


def _excepthook(type_, value, traceback_):
    pid = os.getpid()
    log_msg('[%s] type: %s' % (pid, type_))
    log_msg('[%s] value: %s' % (pid, value))
    if traceback_:
        for tb in traceback_.format_exc().splitlines():
            log_msg('[%s] traceback: %s' % (pid, tb))


sys.excepthook = _excepthook


def _file_lock_open(filename, lock_option, lock_timeout, *open_args, **open_kwargs):
    count = 0
    fd = open(filename, *open_args, **open_kwargs)
    while True:
        if count > lock_timeout:
            log_msg('time out')
            break

        try:
            fcntl.flock(fd, lock_option)
        except IOError, e:
            print(e)
            time.sleep(LOCK_WAIT_INTERVAL)
            count += LOCK_WAIT_INTERVAL
            continue

        fd_new = open(filename, *open_args, **open_kwargs)
        if os.path.sameopenfile(fd.fileno(), fd_new.fileno()):
            fd_new.close()
            return fd
        else:
            fd.close()
            fd = fd_new
    return -1


def _file_touch(filename):
    fd = open(filename, 'a')
    fd.close()


def _proc_signal_by_pid_file(pid_file, signal):
    if not os.path.exists(pid_file):
        return -1, ERR_BAD_PARAMETERS
    if signal < 0:
        return -1, ERR_BAD_PARAMETERS

    with open(pid_file) as fd:
        str_pid = fd.readline().strip()

    try:
        pid = int(str_pid)
    except ValueError:
        return -1, ERR_OPEN_FAILED

    if pid <= 0:
        return -1, ERR_OPEN_FAILED

    try:
        os.kill(pid, signal)
    except OSError:
        return -1, ERR_SYS_UNKNOWN

    return 0, ERR_SUCCESS


def _proc_alive_by_pid_file(pid_file):
    ret, _ = _proc_signal_by_pid_file(pid_file, 0)
    return ret == 0


def _config_file_write(config, conf_file):
    tf_prefix = '%s_' % os.path.basename(conf_file)
    tf_dir = os.path.dirname(conf_file)
    tf = tempfile.NamedTemporaryFile(
        'w', suffix='.XXXXXX', prefix=tf_prefix, dir=tf_dir, delete=False)
    tf_name = tf.name
    try:
        tf.write('\n')
        for sec in config.sections():
            tf.write('[%s]\n' % sec)
            for opt in config.options(sec):
                tf.write('\t%s = %s\n' % (opt, config.get(sec, opt)))
        tf.close()
    except IOError:
        log_msg('fail to write config to [%s]' % tf_name)
        return -1

    try:
        os.rename(tf_name, conf_file)
    except OSError:
        log_msg('fail to rename [%s] to [%s]' % (tf_name, conf_file))
        return -1

    return 0


def _collect_printer_devname(printer_config_tuple_list):
    devname_list = []
    for (key, value) in printer_config_tuple_list:
        if not key.startswith(SZK_USBIP_USB_INTERFACE_PREFIX):
            continue
        if not value.startswith(SZ_PREFIX_PRINTER):
            continue
        devname_list.append(value)
    return devname_list


def check_printer_bus_remove(devpath):

    bus_id = os.path.basename(devpath)

    # open usbdev.conf and get lock
    _file_touch(SZF_USBIP_USB_DEV_CONF)
    fd = open(SZF_USBIP_USB_DEV_CONF)
    if fd < 0:
        log_msg('cannot open file [%s]' % SZF_USBIP_USB_DEV_CONF)
        return -1

    # read config from usbdev.conf
    config = ConfigParser.SafeConfigParser()
    data = StringIO.StringIO('\n'.join(line.strip() for line in fd))
    config.readfp(data)

    remove_printers = []

    # check printer section
    for section in config.sections():
        # check bus id
        try:
            section_bus_id = config.get(section, SZK_USBIP_USB_BUS_NUMBER)
        except ConfigParser.NoOptionError:
            continue

        if section_bus_id != bus_id:
            continue

        printerid = section

        # check status
        if not config.has_option(printerid, SZK_USBIP_USB_STATUS):
            log_msg('cannot get printer status [%s]' % printerid)
            continue
        elif config.get(printerid, SZK_USBIP_USB_STATUS) == '':
            # printer has been removed, clear bus number
            log_msg('printer has been removed [%s]' % printerid)
            continue
        config.set(printerid, SZK_USBIP_USB_STATUS, SZV_USBIP_USB_STATUS_PLUG_OUT)

        # get proc_dev
        try:
            proc_dev = config.get(section, SZK_USBIP_USB_PROC_DEVICE)
        except ConfigParser.NoOptionError:
            log_msg('cannot get printer proc_dev [%s]' % printerid)
            continue

        # collect devname list
        devname_list = _collect_printer_devname(config.items(printerid))
        if not devname_list:
            log_msg('cannot get printer devname [%s]' % printerid)
            continue

        for devname in devname_list:
            remove_printers.append({
                'printerid': printerid,
                'proc_dev': proc_dev,
                'devname': devname,
            })

    # update usbdev.conf
    if _config_file_write(config, SZF_USBIP_USB_DEV_CONF) < 0:
        log_msg('fail to write config to %s' % SZF_USBIP_USB_DEV_CONF)
        return -1

    # close usbdev.conf and release lock
    fd.close()

    if not remove_printers:
        # no printers need to remove, exit
        return 0

    for printer_dict in remove_printers:
        # remove printer from CUPS
        log_msg('remove printer [%s] (%s)' % (printer_dict['printerid'], printer_dict['devname']))
        cmd = '%s --hpdisable %s %s %s >/dev/null 2>&1' % (
            SZF_SYNOPRINT, printer_dict['devname'], printer_dict['proc_dev'], printer_dict['printerid'])
        subprocess.call(cmd, shell=True)

    # notify usbipd
    log_msg('notify usbipd')
    if _proc_alive_by_pid_file(SZF_MFP_PID_FILE):
        _proc_signal_by_pid_file(SZF_MFP_PID_FILE, SIGUSR1)
    else:
        subprocess.call(['/usr/syno/sbin/synoservice', '--start', 'usbipd'])

    return 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--devpath',
            required=True,
            help='device path of usb bus')
    args = parser.parse_args()

    _file_touch(SZF_USBDEV_CONF_LOCK)
    lockfd = _file_lock_open(SZF_USBDEV_CONF_LOCK, fcntl.LOCK_EX | fcntl.LOCK_NB, LOCK_TIMEOUT * 5)
    if lockfd < 0:
        log_msg('cannot lock file for [%s]' % SZF_USBIP_USB_DEV_CONF)
        return -1

    ret = check_printer_bus_remove(args.devpath)
    lockfd.close()
    return ret


if __name__ == '__main__':
    sys.exit(main())

