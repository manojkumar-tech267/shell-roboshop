#!/bin/bash

START_TIME=$(date +%s)
userid=$(id -u)
script_dir=$PWD

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $userid -ne 0 ]
then 
    echo -e "$R You are not a root user please run with root access $N"
    exit 1 
else 
    echo -e "$G you are running with root access $N"
fi 


logs_folder="/var/log/roboshop-logs"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$logs_folder/$script_name.log"

mkdir -p logs_folder
echo "Script started executing at: $(date)" | tee -a $log_file

echo "Please enter root password to setup"
read -s mysql_root_password


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

dnf install mysql-server -y &>> $log_file
VALIDATION $? "Installing mysql server"

systemctl enable mysqld &>> $log_file
systemctl start mysqld  &>> $log_file
VALIDATION $? "Start and Enable mysql"

mysql_secure_installation --set-root-pass $mysql_root_password &>> $log_file
VALIDATION $? "Changing mysql root password"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME-START_TIME))
echo "Script completed execution successfully time taken is $TOTAL_TIME seconds" | tee -a $log_file