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

dnf module disable nodejs -y &>> $log_file
VALIDATE $? "Disabling Nodejs"

dnf module enable nodejs:20 -y &>> $log_file
VALIDATE $? "Enabling Nodejs"

dnf install nodejs -y &>> $log_file
VALIDATE $? "Installing Nodejs"

mkdir -p /app 
VALIDATE $? "Creating app directory"

id roboshop &>> $log_file
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $log_file
    VALIDATE $? "Creating roboshop system user"
else 
    echo "User is already there we are skipping" | tee -a $log_file
fi 

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>> $log_file
VALIDATE $? "Downloading user code"

rm -rf /app/*
cd /app 
unzip /tmp/user.zip &>> $log_file
VALIDATE $? "Extracting user files"

npm install &>> $log_file
VALIDATE $? "Installing Nodejs dependencies"

cp $script_dir/user.service /etc/systemd/system/user.service
VALIDATE $? "Copying user.service file"

systemctl daemon-reload &>> $log_file
VALIDATE $? "Reload user service"

systemctl enable user &>> $log_file
systemctl start user &>> $log_file
VALIDATE $? "Start and Enable user"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME-START_TIME))
echo "Script completed execution successfully time taken is $TOTAL_TIME seconds" | tee -a $log_file