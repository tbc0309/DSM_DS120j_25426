#!/usr/bin/python
import os
import re
import sys
import subprocess
import json
import ConfigParser
import StringIO

PACKAGE_PATH = '/var/packages'
RESOURCE_PATH = 'conf/resource'
RESOURCE_OWN_PATH = 'conf/resource.own'
SYNOPKG = '/usr/syno/bin/synopkg'
INFO_PATH = 'INFO'
DUMMY_SECTION = 'dummy section'


def is_package_enabled(package):
    with open(os.devnull, 'w') as FNULL:
        try:
            result = subprocess.check_output([SYNOPKG, 'status', package],
                                             stderr=FNULL)
            return 'package is started' in result
        except subprocess.CalledProcessError:
            return False


def parse_share_from_file(file_name, share_key):
    shares = []
    try:
        with open(file_name) as resource_file_obj:
            resources = json.load(resource_file_obj)
            for share in resources['data-share']['shares']:
                shares.append(share[share_key])
    except (IOError, KeyError):
        return False, shares
    return True, shares


def is_share_in_resource(package, target_share):
    check_resource_own = False
    file_name = '%s/%s/%s' % (PACKAGE_PATH, package, RESOURCE_PATH)
    result, shares = parse_share_from_file(file_name, 'name')
    if not result:
        return False, False

    for share in shares:
        if target_share == share:
            return True, False
        if re.match('{{.*}}', share):
            check_resource_own = True

    return False, check_resource_own


def is_share_in_resource_own(package, target_share):
    file_name = '%s/%s/%s' % (PACKAGE_PATH, package, RESOURCE_OWN_PATH)
    result, shares = parse_share_from_file(file_name, 'target')
    if not result:
        return False

    if target_share in shares:
        return True

    return False


def is_package_using_share(package, target_share):
    result, check_resource_own = is_share_in_resource(package, target_share)

    if not result and check_resource_own:
        result = is_share_in_resource_own(package, target_share)

    return result


def append_section_and_get_cp(file_path):
    try:
        with open(file_path) as file:
            config = StringIO.StringIO()
            config.write('[%s]\n' % DUMMY_SECTION)
            config.write(file.read())
            config.seek(0, os.SEEK_SET)

            cp = ConfigParser.ConfigParser()
            cp.readfp(config)
    except (IOError, ConfigParser.ParsingError):
        return False
    return cp


def get_package_display_name(package):
    info_file = '%s/%s/%s' % (PACKAGE_PATH, package, INFO_PATH)
    info_cp = append_section_and_get_cp(info_file)
    if info_cp:
        try:
            return info_cp.get(DUMMY_SECTION, 'displayname').strip('"')
        except ConfigParser.NoOptionError:
            return package
    return package


if __name__ == "__main__":
    occupied_packages = []
    target_share = sys.argv[1]

    for package in os.walk(PACKAGE_PATH).next()[1]:  # DIRNAMES
        if not is_package_enabled(package):
            continue
        if is_package_using_share(package, target_share):
            occupied_packages.append(get_package_display_name(package))

    if len(occupied_packages) < 1:
        exit(0)
    else:
        print(', '.join(occupied_packages))
        exit(1)
