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


def _sysfs_get_usb_bus_path(devpath):
    sysfs_path = '/sys' + devpath
    while sysfs_path:
        if sysfs_path == '/':
            return ''
        if os.path.exists(os.path.join(sysfs_path, SZF_SYSFS_NUM_INTERFACES)):
            return sysfs_path
        sysfs_path = os.path.dirname(sysfs_path)
    return ''


def _sysfs_get_usb_interface_id(devpath):
    # devpath = /devices/pci0000:00/0000:00:1c.0/0000:02:00.0/usb4/4-1/4-1:1.1/usb/lp0
    tmp = devpath.rsplit('.', 1)[1]
    if not tmp:
        return -1, ''
    try:
        interface_id = int(tmp[0])
    except ValueError:
        return -1, ''
    return 0, interface_id


def _sysfs_get_value(sysfs_dir, attribute_file):
    try:
        fp = open(os.path.join(sysfs_dir, attribute_file))
        value = fp.read()
        fp.close()
    except IOError:
        return -1, ''
    return 0, value

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


def check_printer_add(printerid, devpath, bus_dev):

    if 2 >= len(printerid) or 0 == len(devpath) or 0 == len(bus_dev) :
        log_msg('Bad parameter, printerid=[%s] devpath=[%s] bus_dev=[%s]' % (printerid, devpath, bus_dev))
        return -1

    log_msg('add printer=[%s] devpath=[%s] bus_dev=[%s]' % (printerid, devpath, bus_dev))

    devname = os.path.basename(devpath)

    usb_bus_path = _sysfs_get_usb_bus_path(devpath)
    if not usb_bus_path:
        log_msg('cannot get usb bus path, printer=[%s] devpath=[%s]' % (printerid, devpath))
        return -1
    bus_id = os.path.basename(usb_bus_path)

    busnum, devnum = bus_dev.split('.')
    proc_dev = "/proc/bus/usb/%03d/%03d" % (int(busnum), int(devnum))

    ret, interface_id = _sysfs_get_usb_interface_id(devpath)
    if ret < 0:
        log_msg('cannot get interface_id, printer=[%s] devpath=[%s]' % (printerid, devpath))
        return -1

    # open usbdev.conf and get lock
    _file_touch(SZF_USBIP_USB_DEV_CONF)
    fd = open(SZF_USBIP_USB_DEV_CONF)
    if fd < 0:
        log_msg('cannot open file with lock [%s]' % SZF_USBIP_USB_DEV_CONF)
        return -1

    # read config from usbdev.conf
    config = ConfigParser.SafeConfigParser()
    data = StringIO.StringIO('\n'.join(line.strip() for line in fd))
    config.readfp(data)

    # if printer section not exist, create it
    if not config.has_section(printerid):
        config.add_section(printerid)

    # set status
    if not config.has_option(printerid, SZK_USBIP_USB_STATUS):
        config.set(printerid, SZK_USBIP_USB_STATUS, SZV_USBIP_USB_STATUS_PLUG_IN)
    elif config.get(printerid, SZK_USBIP_USB_STATUS) in [SZV_USBIP_USB_STATUS_PLUG_OUT]:
        config.set(printerid, SZK_USBIP_USB_STATUS, SZV_USBIP_USB_STATUS_PLUG_IN)

    # set bus number
    config.set(printerid, SZK_USBIP_USB_BUS_NUMBER, bus_id)

    # set interface_number
    ret, num_interfaces = _sysfs_get_value(usb_bus_path, SZF_SYSFS_NUM_INTERFACES)
    if ret < 0:
        log_msg('fail to get %s' % SZF_SYSFS_NUM_INTERFACES)
        return -1
    config.set(printerid, SZK_USBIP_USB_INTERFACE_NUMBER, num_interfaces.strip())

    # set interface_id
    config.set(printerid, '%s%s' % (SZK_USBIP_USB_INTERFACE_PREFIX, interface_id), devname)

    # set proc_dev
    config.set(printerid, SZK_USBIP_USB_PROC_DEVICE, proc_dev)

    # set producer
    ret, manufacturer = _sysfs_get_value(usb_bus_path, SZF_SYSFS_MANUFACTURER)
    if ret < 0:
        manufacturer = ''
    config.set(printerid, SZK_USBIP_PRINTER_PRODUCER, manufacturer.strip())

    # set product name
    ret, product = _sysfs_get_value(usb_bus_path, SZF_SYSFS_PRODUCT)
    if ret < 0:
        product = ''
    config.set(printerid, SZK_USBIP_PRINTER_PRODUCTNAME, product.strip())

    if _config_file_write(config, SZF_USBIP_USB_DEV_CONF) < 0:
        log_msg('fail to write config to %s' % SZF_USBIP_USB_DEV_CONF)
        return -1

    # close usbdev.conf and release lock
    fd.close()

    return 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--action', required=True, help='udev action')
    parser.add_argument('--devpath', required=True, help='device path of printer')
    parser.add_argument('--printerid', required=True, help='printer section name in usbdev.conf')
    parser.add_argument('--bus_dev', required=True, help='busnum and devnum')
    args = parser.parse_args()

    if args.action == 'add':
        _file_touch(SZF_USBDEV_CONF_LOCK)
        lockfd = _file_lock_open(SZF_USBDEV_CONF_LOCK, fcntl.LOCK_EX | fcntl.LOCK_NB, LOCK_TIMEOUT * 5)
        if lockfd < 0:
            log_msg('cannot lock file for [%s]' % SZF_USBIP_USB_DEV_CONF)
            return -1

        ret = check_printer_add(args.printerid, args.devpath, args.bus_dev)
        lockfd.close()
        return ret

    return 0


if __name__ == '__main__':
    sys.exit(main())

