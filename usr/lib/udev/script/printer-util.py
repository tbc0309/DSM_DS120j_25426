#!/usr/bin/python
import argparse
import subprocess
import sys
import os
import signal


BIND_DRIVER = '/usr/bin/bind_driver'
LOGGER = '/usr/bin/logger'
LOGGER_TAG = 'udev_printer'
SYNO_DEFAULT_INFO_CONF = '/etc.defaults/synoinfo.conf'
SYNO_GET_KEY_VALUE = '/usr/syno/bin/synogetkeyvalue'
SYNO_USB_DISK = '/usr/syno/bin/synousbdisk'


def syno_get_key_value(conf_file, key):
    return subprocess.check_output([SYNO_GET_KEY_VALUE, conf_file, key]).strip()


def log_msg(msg, priority='err'):
    return subprocess.call([LOGGER, '-p', priority, '-t', LOGGER_TAG, msg])


def get_usb_printer_num():
    support_mfp = syno_get_key_value(SYNO_DEFAULT_INFO_CONF, 'supportMFP')
    if support_mfp.lower() == 'yes':
        usb_printer_num = subprocess.check_output([BIND_DRIVER, '--count']).strip()
        log_msg('%s --count  [%s]' % (BIND_DRIVER, usb_printer_num))
    else:
        usb_printer_num = subprocess.call([SYNO_USB_DISK, '-enumusbprinters']).strip()
        log_msg('%s -enumusbprinters  [%s]' % (SYNO_USB_DISK, usb_printer_num))
    return int(usb_printer_num)


def get_usb_printer_remain_slots():
    max_printers = int(syno_get_key_value(SYNO_DEFAULT_INFO_CONF, 'maxprinters'))
    usb_printer_num = get_usb_printer_num()
    if usb_printer_num < max_printers:
        return max_printers - usb_printer_num
    else:
        return 0

def get_hotplugd_pid():
    try:
        fp = open("/var/run/hotplugd.pid", "r")
        value = fp.read()
        fp.close()
    except IOError:
        return -1, 0
    return 0, int(value)

def prepare_hotplug_event_file(bus_dev):

    busnum, devnum = bus_dev.split('.')
    device = "/proc/bus/usb/%03d/%03d" % (int(busnum), int(devnum))

    hotplug_event_tmp = "/tmp/tmp.hotplug.%s" % os.getenv("SEQNUM")

    fd = open(hotplug_event_tmp, "a")

    fd.write("ACTION=%s\n" % os.getenv("ACTION"))
    fd.write("DEVICE=%s\n" % device)
    fd.write("DEVNAME=%s\n" % os.path.basename(os.getenv("DEVNAME")))
    fd.write("DEVPATH=%s\n" % os.path.basename(os.getenv("DEVPATH")))
    fd.write("SUBSYSTEM=%s\n" % os.getenv("SUBSYSTEM"))
    fd.write("PHYSDEVPATH=%s\n" % os.getenv("PHYSDEVPATH"))
    fd.write("INTERFACE=%s\n" % os.getenv("INTERFACE"))
    fd.close()

    os.rename(hotplug_event_tmp, "/tmp/hotplug.%s" % os.getenv("SEQNUM"))

    ret, hpid = get_hotplugd_pid()
    if ret < 0:
        log_msg('cannot get hotplugd pid')
        return -1

    os.kill(hpid, signal.SIGUSR1)

    return 0

def main():
    parser = argparse.ArgumentParser()
    subparser = parser.add_subparsers(help="sub-command help", dest="subcmd")

    parser_util = subparser.add_parser('util')
    parser_util.add_argument('util', choices=['get-usb-printer-remain-slots'])

    parser_gen = subparser.add_parser('genticket')
    parser_gen.add_argument('--bus_dev', required=True, help='busnum and devnum')

    args = parser.parse_args()

    if args.subcmd == "util" and args.util == 'get-usb-printer-remain-slots':
        print(get_usb_printer_remain_slots())
    elif args.subcmd == "genticket":
        prepare_hotplug_event_file(args.bus_dev)

    return 0

if __name__ == '__main__':
    sys.exit(main())
