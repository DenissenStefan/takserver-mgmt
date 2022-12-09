#!/bin/bash
# Created by: Stefan
# Created on: 08-12-2022

HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4
BACKTITLE="TAK Server Management Console by S.W. Denissen (github.com/denissenstefan)"
TITLE="TAK Server Management Console"
MENU="Choose one of the following options:"

OPTIONS=(1 "Create users in bulk"
         2 "Option 2"
         3 "Quit Management Console")

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        1)
            echo "Bulk creation of users:"
            source ./BulkUsers.sh
            ;;
        2)
            echo "You chose Option 2"
            ;;
        3)
            echo "Quitting the TAK Server Management Console"
            break
            ;;
esac