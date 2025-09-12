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

mkdir -p $logs_folder
echo "Script started executing at: $(date)" | tee -a $log_file

VALIDATE()
{
    if [ $1 -eq 0 ]
    then 
        echo -e "$G $2 is success $N" 
    else 
        echo -e "$R $2 is failure $N"
        exit 1 
    fi
}

dnf module disable nodejs -y &>> $log_file
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>> $log_file
VALIDATE $? "Enabling Nodejs:20 version"

dnf install nodejs -y &>> $log_file
VALIDATE $? "Installing NodeJs"

mkdir -p /app 
VALIDATE $? "Creating App directory"

id roboshop
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $log_file
    VALIDATE $? "Creating roboshop user"
else 
    echo -e "$G roboshop user is already created $N"
fi 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $log_file
VALIDATE $? "Downloading catalogue code"

rm -rf /app/*
cd /app 
unzip /tmp/catalogue.zip &>> $log_file
VALIDATE $? "Extracting catalogue code files"

npm install &>> $log_file
VALIDATE $? "Installing Nodejs Dependencies"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue.service file"

systemctl daemon-reload &>> $log_file
VALIDATE $? "Reload catalogue service"

systemctl enable catalogue &>> $log_file
systemctl start catalogue &>> $log_file
VALIDATE $? "Start and Enable catalogue"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo.repo file"

dnf install mongodb-mongosh -y &>> $log_file
VALIDATE $? "Installing Mongodb client"

STATUS=$(mongosh --host mongodb.cloudwithmanoj.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $STATUS -lt 0 ]
then 
    mongosh --host mongodb.cloudwithmanoj.online </app/db/master-data.js &>> $log_file
    VALIDATE $? "Loading master data"
else 
    echo -e "$Y Data is already loaded we are skipping $N" 
fi 

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME-START_TIME))
echo "Script completed execution successfully time taken is $TOTAL_TIME seconds" | tee -a $log_file


