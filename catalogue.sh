#!/bin/bash 

userid=$(id -u)
script_dir=$PWD 

logs_folder="/var/log/roboshop-logs"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$logs_folder/$script_name.sh"

mkdir -p logs_folder

if [ $userid -ne 0 ]
then 
    echo "You are not a root user Please run with root access!!!" | tee -a $logs_folder
    exit 1 
else 
    echo "You are running with root user access" | tee -a $logs_folder
fi 

VALIDATE()
{
    if [ $1 -eq 0 ]
    then 
        echo "$2 is success" | tee -a $logs_folder
    else 
        echo "$2 is failed" | tee -a $logs_folder
        exit 1 
    fi
}

dnf module disable nodejs -y &>> $logs_folder
VALIDATE $? "Disabling Nodejs"

dnf module enable nodejs:20 -y &>> $logs_folder
VALIDATE $? "Enabling Nodejs"

dnf install nodejs -y &>> $logs_folder
VALIDATE $? "Installing NodeJs"

mkdir -p /app
VALIDATE $? "Creating App directory"

id roboshop 
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Created roboshop user"
else 
    echo "Roboshop user is already there we are skipping" | tee -a $logs_folder
fi 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>> $logs_folder
VALIDATE $? "Downloading catalogue code"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>> $logs_folder
VALIDATE $? "unzipping catalogue"

npm install &>> $logs_folder
VALIDATE $? "Installing NodeJs dependencies"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue.service file"

systemctl daemon-reload &>> $logs_folder
VALIDATE $? "Reload catalogue service"

systemctl enable catalogue 
systemctl start catalogue
VALIDATE $? "Enable and start catalogue"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo.repo file"

dnf install mongodb-mongosh -y &>> $logs_folder
VALIDATE $? "Installing mongodb client"

status=$(mongosh --host mongodb.cloudwithmanoj.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $status -lt 0 ]
then
    mongosh --host mongodb.cloudwithmanoj.online </app/db/master-data.js
    VALIDATE $? "Loading master data"
else 
    echo "Data is already loaded we are skipping"
fi