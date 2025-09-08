#!/bin/bash

userid =$(id -u)

if [ $userid -ne 0 ]
then 
    echo "you are not a root user please run with root user access"
    exit 1 
else 
    echo "You are running with root user access"
fi 

log_folder="/var/log/roboshop-logs"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$log_folder/$script_name.log"

mkdir -p $log_folder

VALIDATE()
{
    if [ $1 -eq 0 ]
    then 
        echo "$2 is success"
    else 
        echo "$2 is failure"
        exit 1 
    fi
}

read -s password
dnf install mysql-server -y &>> $log_file
VALIDATE $? "Installing mysql server"

systemctl enable mysqld &>> $log_file
systemctl start mysqld  &>> $log_file
VALIDATE $? "Enable and start mysqld"

mysql_secure_installation --set-root-pass $password
VALIDATE $? "changing the default password"