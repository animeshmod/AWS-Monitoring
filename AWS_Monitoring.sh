#!/bin/sh

# The script creates custom matrix and update it with the value.

while [1]

do 

Date=$(date +%Y%m%d)
Time=$(date +%H%m)
Hostename=$1
Namesfx=$(echo $Hostname | awk -F "." '{print $1}')
Instanceid=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
Azone=$(wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone)
Region=${Azone/%?/}

case $Hostename in
    app1*(dev|qa|prod)-*(e|w).aws.com)
    Log_Dir=/home/app1user/monitoring
    ;;
    app2*(dev|qa|prod)-*(e|w).aws.com)
    Log_Dir=/home/app2user/monitoring
    ;;
    app3*(dev|qa|prod)-*(e|w).aws.com)
    Log_Dir=/home/app3user/monitoring
    ;;
    *)
    echo "Unknown Hostname"
    ;;
esac

exec > ${Log_Dir}/aws_monitoring.log.$Date.$Time 2>&1

set -x

case $Hostname in
    *(dev)-e.aws.com)
    SNSARN=arn:aws:sns:us-east-1:123456789:APP_DEV
    export HTTPS_PROXY=https://devproxyaddress.com:8099
    export HTTP_PROXY=http://devproxyaddress.com:8099
    export no_proxy=127.0.0.1,localhost,169.254.169.254,s3.amazonaws.com,github.com
    ;;
    *(dev)-w.aws.com)
    SNSARN=arn:aws:sns:us-west-2:123456789:APP_DEV
    export HTTPS_PROXY=https://devproxyaddress.com:8099
    export HTTP_PROXY=http://devproxyaddress.com:8099
    export no_proxy=127.0.0.1,localhost,169.254.169.254,s3.us-west2.amazonaws.com,github.com
    ;;
    *(qa)-e.aws.com)
    SNSARN=arn:aws:sns:us-east-1:123456789:APP_QA
    export HTTPS_PROXY=https://qaproxyaddress.com:8099
    export HTTP_PROXY=http://qaproxyaddress.com:8099
    export no_proxy=127.0.0.1,localhost,169.254.169.254,s3.amazonaws.com,github.com
    ;;
    *(qa)-*w.aws.com)
    SNSARN=arn:aws:sns:us-west-2:123456789:APP_QA
    export HTTPS_PROXY=https://qaproxyaddress.com:8099
    export HTTP_PROXY=http://qaproxyaddress.com:8099
    export no_proxy=127.0.0.1,localhost,169.254.169.254,s3.us-west2.amazonaws.com,github.com
    ;;
    *(prod)-e.aws.com)
    SNSARN=arn:aws:sns:us-east-1:123456789:APP_PROD
    SNSARNW=arn:aws:sns:us-west-2:123456789:APP_PROD
    export HTTPS_PROXY=https://prodproxyaddress.com:8099
    export HTTP_PROXY=http://prodproxyaddress.com:8099
    export no_proxy=127.0.0.1,localhost,169.254.169.254,s3.amazonaws.com,github.com
    ;;
    *(prod)-w.aws.com)
    SNSARN=arn:aws:sns:us-west-2:123456789:APP_PROD
    export HTTPS_PROXY=https://prodproxyaddress.com:8099
    export HTTP_PROXY=http://prodproxyaddress.com:8099
    export no_proxy=127.0.0.1,localhost,169.254.169.254,s3.us-west2.amazonaws.com,github.com
    ;;
    *)
    echo "Unknows Hostname"
    ;;
esac

Create_Update_Alarm()
{
    Alartminstanceid=$(aws cloudwatch describe-alarms --alarm-name $ALARMNAME --region $REGION | jq '.MetricAlarms[0].Dimensions[0].Value')
    Alartminstanceid=$(sed -e 's/^"//' -e 's/"$//' <<<"$Alartminstanceid")
    if ["$Alartminstanceid" == "$Instanceid"]; then
        echo "$ALARMNAME alarm is in place"
    else
        echo "$ALARMNAME alarm is not in place"
        echo "Create $ALARMNAME alarm"
        aws cloudwatch put-metric-alarm --alarm-name $ALARMNAME --alarm-description "$ALARMDESCRIPTION" --metric-name $ALARMNAME --namespace Applicationname --statistic Average --period $PERIOD --threshold $THRESHOLD --comparision-operator $COMPOPERATOR --dimensions Name=Instanceid,Value=$Instanceid Name=Hostname,Value=$Hostename Name=Region,Value=$Region --evaluation-periods $DATAPOINT --alarm-actions $ARNVAL --unit $UNIT --datapoints-to-alarm $DATAPOINT --treat-missing-data $TMDVAL --ok-actions $ARUNVAL --region $Region
    fi
}

case $Hostname in
    app1dev-*(e|w).aws.com)
    ALARMNAME=App1-$Hostname
    ALARMDESCRIPTION="Application1 Status"
    PERIOD=300
    THRESHOLD=1
    COMPOPERATOR="LessThanThreshold"
    DATAPOINT=1
    ARNVAL="$SNSARN"
    UNIT="Count"
    TMDVAL="breaching"
    Create_Update_Alarm

    ALARMNAME=MemUtil-$Hostname
    ALARMDESCRIPTION="Memory Used By Server"
    PERIOD=300
    THRESHOLD=90
    COMPOPERATOR="GreaterThanOrEqualToThreshold"
    DATAPOINT=1
    ARNVAL="$SNSARN"
    UNIT="Percent"
    TMDVAL="breaching"
    Create_Update_Alarm

    ALARMNAME=RootVolUsed-$Hostname
    ALARMDESCRIPTION="Root Volume Percentage  used By Server"
    PERIOD=300
    THRESHOLD=90
    COMPOPERATOR="GreaterThanOrEqualToThreshold"
    DATAPOINT=1
    ARNVAL="$SNSARN"
    UNIT="Percent"
    TMDVAL="breaching"
    Create_Update_Alarm
    ;;

   app1qa-*(e|w).aws.com)
    ALARMNAME=App1-$Hostname
    ALARMDESCRIPTION="Application1 Status"
    PERIOD=300
    THRESHOLD=1
    COMPOPERATOR="LessThanThreshold"
    DATAPOINT=1
    ARNVAL="$SNSARN"
    UNIT="Count"
    TMDVAL="breaching"
    Create_Update_Alarm

    ALARMNAME=MemUtil-$Hostname
    ALARMDESCRIPTION="Memory Used By Server"
    PERIOD=300
    THRESHOLD=90
    COMPOPERATOR="GreaterThanOrEqualToThreshold"
    DATAPOINT=1
    ARNVAL="$SNSARN"
    UNIT="Percent"
    TMDVAL="breaching"
    Create_Update_Alarm

    ALARMNAME=RootVolUsed-$Hostname
    ALARMDESCRIPTION="Root Volume Percentage  used By Server"
    PERIOD=300
    THRESHOLD=90
    COMPOPERATOR="GreaterThanOrEqualToThreshold"
    DATAPOINT=1
    ARNVAL="$SNSARN"
    UNIT="Percent"
    TMDVAL="breaching"
    Create_Update_Alarm
    ;;

   app1prod-*(e|w).aws.com)
    ALARMNAME=App1-$Hostname
    ALARMDESCRIPTION="Application1 Status"
    PERIOD=300
    THRESHOLD=1
    COMPOPERATOR="LessThanThreshold"
    DATAPOINT=1
    ARNVAL="$SNSARN"
    UNIT="Count"
    TMDVAL="breaching"
    Create_Update_Alarm

    ALARMNAME=MemUtil-$Hostname
    ALARMDESCRIPTION="Memory Used By Server"
    PERIOD=300
    THRESHOLD=90
    COMPOPERATOR="GreaterThanOrEqualToThreshold"
    DATAPOINT=1
    ARNVAL="$SNSARN"
    UNIT="Percent"
    TMDVAL="breaching"
    Create_Update_Alarm

    ALARMNAME=RootVolUsed-$Hostname
    ALARMDESCRIPTION="Root Volume Percentage  used By Server"
    PERIOD=300
    THRESHOLD=90
    COMPOPERATOR="GreaterThanOrEqualToThreshold"
    DATAPOINT=1
    ARNVAL="$SNSARN"
    UNIT="Percent"
    TMDVAL="breaching"
    Create_Update_Alarm
    ;;
  *)
  echo "Unknown Hostname"
  ;;
esac

case $Hostname in
    app1(dev|qa|prod)-*(e|w).aws.com)
    cd $Log_Dir
##  Memory utilization monitoring data
    Memused=$(/home/app1user/monitoring/aws-scripts-mon/mon-put-instance-data.pl --mem-util --verify --verbose | head -1 | awk -F ":" '{print $2}' | awk -F " " '{print $1}')
    aws cloudwatch put-metric-data --metric-name MemUtil-$Hostname --value $Memused --unit "Percent" --namespace Applicationname --dimensions Instanceid=$Instanceid,Hostname=$Hostname,Region=$Region --region $Region
##  Disk space utilization
    Diskused=$(/home/app1user/monitoring/aws-scripts-mon/mon-put-instance-data.pl --disk-space-util --disk-path=/ --verify --verbose | head -1 | awk -F ":" '{print $2}' | awk -F " " '{print $1}')
    aws cloudwatch put-metric-data --metric-name RootVolUsed-$Hostname --value $Diskused --unit "Percent" --namespace Applicationname --dimensions Instanceid=$Instanceid,Hostname=$Hostname,Region=$Region --region $Region
##  Application status check
    appstatus=$(ps -ef | grep applicationname | grep -v grep | wc -l)
    aws cloudwatch put-metric-data --metric-name application-$Hostname --value $aapstatus --unit "Count" --namespace Applicationname --dimensions Instanceid=$Instanceid,Hostname=$Hostname,Region=$Region --region $Region
    ;;

    app2(dev|qa|prod)-*(e|w).aws.com)
    cd $Log_Dir
##  Memory utilization monitoring data
    Memused=$(/home/app2user/monitoring/aws-scripts-mon/mon-put-instance-data.pl --mem-util --verify --verbose | head -1 | awk -F ":" '{print $2}' | awk -F " " '{print $1}')
    aws cloudwatch put-metric-data --metric-name MemUtil-$Hostname --value $Memused --unit "Percent" --namespace Applicationname --dimensions Instanceid=$Instanceid,Hostname=$Hostname,Region=$Region --region $Region
##  Disk space utilization
    Diskused=$(/home/app2user/monitoring/aws-scripts-mon/mon-put-instance-data.pl --disk-space-util --disk-path=/ --verify --verbose | head -1 | awk -F ":" '{print $2}' | awk -F " " '{print $1}')
    aws cloudwatch put-metric-data --metric-name RootVolUsed-$Hostname --value $Diskused --unit "Percent" --namespace Applicationname --dimensions Instanceid=$Instanceid,Hostname=$Hostname,Region=$Region --region $Region
##  Application status check
    appstatus=$(ps -ef | grep applicationname | grep -v grep | wc -l)
    aws cloudwatch put-metric-data --metric-name application-$Hostname --value $aapstatus --unit "Count" --namespace Applicationname --dimensions Instanceid=$Instanceid,Hostname=$Hostname,Region=$Region --region $Region
    ;;
   
    app3(dev|qa|prod)-*(e|w).aws.com)
    cd $Log_Dir
##  Memory utilization monitoring data
    Memused=$(/home/app3user/monitoring/aws-scripts-mon/mon-put-instance-data.pl --mem-util --verify --verbose | head -1 | awk -F ":" '{print $2}' | awk -F " " '{print $1}')
    aws cloudwatch put-metric-data --metric-name MemUtil-$Hostname --value $Memused --unit "Percent" --namespace Applicationname --dimensions Instanceid=$Instanceid,Hostname=$Hostname,Region=$Region --region $Region
##  Disk space utilization
    Diskused=$(/home/app2user/monitoring/aws-scripts-mon/mon-put-instance-data.pl --disk-space-util --disk-path=/ --verify --verbose | head -1 | awk -F ":" '{print $2}' | awk -F " " '{print $1}')
    aws cloudwatch put-metric-data --metric-name RootVolUsed-$Hostname --value $Diskused --unit "Percent" --namespace Applicationname --dimensions Instanceid=$Instanceid,Hostname=$Hostname,Region=$Region --region $Region
##  Application status check
    appstatus=$(ps -ef | grep applicationname | grep -v grep | wc -l)
    aws cloudwatch put-metric-data --metric-name application-$Hostname --value $aapstatus --unit "Count" --namespace Applicationname --dimensions Instanceid=$Instanceid,Hostname=$Hostname,Region=$Region --region $Region
    ;;
  *)
  echo "Unknown Hostname"
  ;;
esac

sleep 30m

done

