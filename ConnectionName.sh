#!/bin/bash
# Created by: Stefan
# Created on: 09-12-2022

DIALOG=${DIALOG=dialog}
ConnectionName="/opt/tak/certs/ConnectionName.txt"

$DIALOG --backtitle "$BACKTITLE" \
        --title "$TITLE - Connection name" --clear \
        --inputbox "Please enter the IP or DNS name you want to use to connect to your TAK Server:" 16 51 2> $ConnectionName

retval=$?

case $retval in
  0)
    echo "Connection name is set as `cat $ConnectionName`"
    ;;
  1)
    echo "Cancel pressed."
    ;;
  255)
    if test -s $ConnectionName ; then
      cat $ConnectionName
    else
      echo "ESC pressed."
    fi
    ;;
esac

clear

./ManagementConsole.sh
