#!/bin/sh
# File: calculate_debt_per_severity_type.sh
# Author: Mohit Dhingra (mohit.dhingra@markit.com)
# Date: 22-04-2018
#
# Note: This script should be run using root user
#
# Description: This script is used for calculating debt for different severity types such as MAJOR, MINOR, CRITICAL, BLOCKER.

usage(){
cat << usg
 ******************************************************
 * This script's purpose is to calculate debt for different severity types issues.
 *
 * Assumptions:
 *  this script needs to be run by root user
 ********************************************************
 Required arguments
  -s SERVER,                        Specify server name

  -k PROJECT/View's key name        Specify the Project's or View's key for which we need to calculate debt for different severity types issues.
                                   

  -t TOKEN                          Provide the token value for a user that should have at least browse access to the Project for which we are calculating debt for  
                                    different severity types.

 optional arguments:

  -h HELP                           Show this help message and exit

  # Example - Calculate debt for different severity types issues for project key devtools-perftest-newjenkins in SonarQube QA
  ./calculate_debt_per_severity_type.sh -s "https://sonar-qa.markit.partners" -k "devtools-perftest-newjenkins" -t "************************"

usg
}

calculate_debt_per_sev_type() {
curl -s -k -o allprojectinfo.xml -u $TOKEN: "$SERVER/api/issues/search?componentKeys=${KEY}&format=xml"
sed 's/,/\n/g' allprojectinfo.xml | grep -E 'debt|severity' | grep -v "INFO" | paste -s -d",\n" > temp.xml

for i in `cat sev.txt`; do
      grep ${i} temp.xml | cut -d ":" -f3 | sed 's/\"//g' > temp_time.xml
          TOTAL_TIME=0

          for time in `cat temp_time.xml`; do

              if echo ${time} | grep -Eq "d.*h.*min" > /dev/null
              then
                   days=`echo ${time} | sed 's/d.*//'`
                   hours=`echo ${time} | sed 's/h.*//' | sed 's/.*d//'`
                   minutes=`echo ${time} | sed 's/.*h//' | sed 's/min.*//'`
           
                   Time_calculated=$[$days*1440 + $hours*60 + $minutes]

              elif echo ${time} | grep -E "d.*h" | grep -vEq "d.*h.*min" > /dev/null
              then
                   days=`echo ${time} | sed 's/d.*//'`
                   hours=`echo ${time} | sed 's/h.*//' | sed 's/.*d//'`
     
                   Time_calculated=$[$days*1440 + $hours*60]   

              elif echo ${time} | grep -E "h.*min" | grep -vEq "d.*h" > /dev/null
              then
                   hours=`echo ${time} | sed 's/h.*//'`
                   minutes=`echo ${time} | sed 's/.*h//' | sed 's/min.*//'`

                   Time_calculated=$[$hours*60 + $minutes]

              elif echo ${time} | grep -E "h" > /dev/null
              then
                   hours=`echo ${time} | sed 's/h.*//'`
                   Time_calculated=$[$hours*60]

              elif echo ${time} | grep -E "min" > /dev/null
              then

                   minutes=`echo ${time} | sed 's/min.*//'`
                   Time_calculated=$minutes
          
              else
              echo "some issue with the time mentioned in the file"
      
              fi

               TOTAL_TIME=$[$TOTAL_TIME + $Time_calculated]

          done
      TOTAL_TIME=$(echo "$TOTAL_TIME/1440" | bc -l)
      echo "Total debt time for $i is $TOTAL_TIME days"
done



}

if [ `whoami` != "root" ]; then
    echo "[ERROR] This script must be run as root user"
    exit 1
fi


while getopts "s:k:t:h" opt; do
  case $opt in
    s)
      SERVER=$OPTARG
      ;;
    k)
      KEY=$OPTARG
      ;;
    t)
      TOKEN=$OPTARG
      ;;
    h)
      usage
      exit 0
      ;;
    *)
      echo 'Incorrect arguments provided'
      usage
      exit 1
      ;;
  esac
done

if [ ! "$SERVER" ]; then
   echo -e 'Server name value required\n'
   exit 1
fi

if [ ! "$KEY" ]; then
   echo -e 'Please provide the key value\n'
   exit 1
fi

if [ ! "$TOKEN" ]; then
   echo -e 'Please provide the Token value\n'
   exit 1
fi

calculate_debt_per_sev_type
