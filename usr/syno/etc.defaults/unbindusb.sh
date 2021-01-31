#!/bin/sh
UNBIND_FILE="/sys/module/usbcore/drivers/usb:usb/unbind"
USBSTOR_DIR="/sys/module/usb_storage/drivers/usb:usb-storage/"
if [ ! -e ${UNBIND_FILE} -o ! -d ${USBSTOR_DIR} ]; then
  exit
fi

for file in `ls ${USBSTOR_DIR} | grep :`
do
  num=`echo ${file} | cut -d : -f 1`
  echo ${num} > ${UNBIND_FILE}
done
