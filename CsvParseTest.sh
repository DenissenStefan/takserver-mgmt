#! /bin/bash

while IFS="," read -r Username Group1 Group2
do
   if
      [[ $Username != "" ]] ;
   then
      echo "Username: $Username"
      echo "Group 1: $Group1"
      echo "Group 2: $Group2"
      echo ""
   fi
done < <(tail -n +2 users.csv)