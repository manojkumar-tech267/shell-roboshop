#!/bin/bash

START_TIME=$(date +%s)
userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

logs_folder="/var/log/roboshop-logs"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$logs_folder/$script_name.log"
script_dir=$PWD

mkdir -p $logs_folder
echo "Script started executing at: $(date)" | tee -a $log_file

if [ $userid -ne 0 ]
then 
    echo -e "$R ERROR:: You are not a root user please run with root access $N" | tee -a $log_file
    exit 1 
else 
    echo -e "$G you are running with root access $N" | tee -a $log_file
fi

VALIDATE()
{
    if [ $1 -eq 0 ]
    then 
        echo -e "$G $2 is success $N" | tee -a $log_file
    else 
        echo -e "$R $2 is failure $N" | tee -a $log_file
        exit 1 
    fi
}

dnf module disable redis -y &>> $log_file
VALIDATE $? "Disabling redis"

dnf module enable redis:7 -y &>> $log_file
VALIDATE $? "Enabling redis"

dnf install redis -y  &>> $log_file
VALIDATE $? "Installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing Remote Connections"

systemctl enable redis &>> $log_file
systemctl start redis &>> $log_file
VALIDATE $? "Start and Enable Redis"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME-START_TIME))
echo "Script completed execution successfully time taken is $TOTAL_TIME seconds" | tee -a $log_file

