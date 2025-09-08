#!/bin/bash

userid=$(id -u)
directory=$PWD
if [ $userid -ne 0 ]
then 
    echo "you are not a root user please run with root user access"
    exit 1 
else 
    echo "you are running with root user access"
fi 

log_folder="/var/log/roboshop-logs"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$log_folder/$script_name.log"

mkdir -p $log_folder

VALIDATE()
{
    if [ $1 -eq 0 ]
    then 
        echo "$2 success" | tee -a $log_folder
    else 
        echo "$2 failure" | tee -a $log_folder
        exit 1 
    fi
}

dnf module disable nodejs -y &>> $log_folder
VALIDATE $? "Disabling NodeJs"

dnf module enable nodejs:20 -y &>> $log_folder
VALIDATE $? "Enabling NodeJs"

dnf install nodejs -y &>> $log_folder
VALIDATE $? "Installing NodeJs"

mkdir /app 
VALIDATE $? "creating app directory"

id roboshop  &>> $log_folder
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Create roboshop user"
else 
    echo "User is already there we are skipping!!!"
fi 

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>> $log_folder
VALIDATE $? "Downloading user code"

rm -rf /app/*
cd /app 
unzip /tmp/user.zip &>> $log_folder
VALIDATE $? "Extracting user code"

npm install  &>> $log_folder
VALIDATE $? "Downloading NodeJs Dependencies"

cp $directory/user.service /etc/systemd/system/user.service
VALIDATE $? "copying user.service file"

systemctl daemon-reload &>> $log_folder
VALIDATE $? "Reload user service"

systemctl enable user | tee -a $log_folder
systemctl start user | tee -a $log_folder
VALIDATE $? "Start and Enable user"


