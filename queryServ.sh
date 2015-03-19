#!/bin/bash
startTime=$(date +%s)
date=$(date +"%m-%d-%Y")
timeNow=$(date +"%T")

dnsserver=your.dns.server
dnsloc=/your/zone/location/

if [[ $1 = '' ]]; then
 echo "usage: queryServ.sh [ip | host | dns | -r (refused) | -t (timed out) | -d (denied)]"
fi

#AIX HMC Command
if [[ $1 = 'hip' ]]; then
 temp=$(ssh khrishmc2 'res=`lssyscfg -r sys -F name`; for i in $res; do lssyscfg -r lpar -m $i -F name; done')
 temp=$(echo $temp | sed 's/EAST//g' | sed 's/WEST//g' | sed 's/TEST//g')
  for i in $temp
  do
   host $i  | awk '/is/ { print $3 }'
  done
fi

#AIX HMC Command
if [[ $1 = 'hhost' ]]; then
 temp=$(ssh khrishmc2 'res=`lssyscfg -r sys -F name`; for i in $res; do lssyscfg -r lpar -m $i -F name; done')
 temp=$(echo $temp | sed 's/EAST//g' | sed 's/WEST//g' | sed 's/TEST//g')
  for i in $temp
  do
   echo $i
  done
fi

#AIX HMC Command
if [[ $1 = 'hall' ]]; then
 temp=$(ssh khrishmc2 'res=`lssyscfg -r sys -F name`; for i in $res; do lssyscfg -r lpar -m $i -F name; done')
 temp=$(echo $temp | sed 's/EAST//g' | sed 's/WEST//g' | sed 's/TEST//g')
  for i in $temp
  do
   echo ""; echo $i; host $i  | awk '/is/ { print $3 }'
  done
fi

#Query Zone Files
if [[ $1 = "dns" ]]; then
 echo "Working... This may take some time."
 rm -rf queryServ.log
 linux=0
 aix=0
 temp=$(ssh $dnsserver "cat $dnsloc | grep -v \"^;\" | awk '/^\s*$/ {next} NR <=12 {next} /@/ {next} { print \$1 }'")
  for i in $temp
  do
   tmp=$(echo "$i \c"; ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=1 $i "uname -a" 2>&1)
   echo $tmp >> queryServ.log
    if [[ $tmp != *"refused"* ]] && [[ $tmp != *"timed"* ]] && [[ $tmp != *"denied"* ]] && [[ $tmp != *"not provided"* ]]; then
     if [[ $tmp == *"Linux"* ]]; then
      linux=$(( $linux + 1 ))
     elif [[ $tmp == *"AIX"* ]]; then
      aix=$(( $aix + 1 ))
     fi
     echo "--$tmp"
    fi
  done
endTime=$(date +%s)
seconds=$(echo "$endTime - $startTime" | bc)
minutes=$(echo "($endTime - $startTime) / 60" | bc)

if [ "$minutes" -le "0" ]; then
echo "Time Taken: $seconds seconds"
else
echo "Time Taken: $minutes minute(s)"
fi

echo "$linux Linux hosts were found."
echo "$aix AIX hosts were found."
fi

#Read Log file and filter
if [[ $1 = '-r' ]]; then
cat queryServ.log | grep "Connection refused" | awk '{print $1}' | sort
fi

if [[ $1 = '-t' ]]; then
cat queryServ.log | grep "timed out" | awk '{print $1}' | sort
fi

if [[ $1 = '-d' ]]; then
cat queryServ.log | grep "Permission denied" | awk '{print $1}' | sort
fi

if [[ $1 = 'aix' ]]; then
cat queryServ.log | grep "AIX" | awk '{print $1}' | sort
fi

if [[ $1 = 'linux' ]]; then
cat queryServ.log | grep "Linux" | awk '{print $1}' | sort
fi
