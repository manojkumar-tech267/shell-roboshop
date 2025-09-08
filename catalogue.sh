#!/bin/bash 

userid=$(id -u)

if [ $userid -ne 0 ]
then 
    echo "You are not a root user run with root access"
    exit 1 
else 
    echo "You are already a root user"
fi 

Logs_Folder="/var/log/roboshop-logs"
File_Name=$(echo $0 | cut -d "." -f1)
Log_File=$Logs_Folder/$File_Name.log

VALIDATE()
{
    if [ $? -eq 0 ]
    then 
        echo "$2 is successful"
    else 
        echo "$2 is not successful"
        exit 1
}

dnf module disable nodejs -y
VALIDATE $? "Disabling NodeJs"

dnf module enable nodejs:20 -y
VALIDATE $? "Enabling NodeJs 20 version"

dnf install nodejs -y
VALIDATE $? "Installing NodeJs"

mkdir /app 
VALIDATE $? "Creating App directory"

id roboshop 
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop system user"
else 
    echo "Roboshop user is already there we are skipping"
fi 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Downloading catalogue code"

cd /app 
unzip /tmp/catalogue.zip
VALIDATE $? "Extracting catalogue code"

cd /app
npm install
VALIDATE $? "Installing NodeJs dependencies"

cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service"

systemctl daemon-reload
VALIDATE $? "Reload catalogue"

systemctl enable catalogue 
systemctl start catalogue
VALIDATE $? "Enable and Start Catalogue service"

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo repo file"

dnf install mongodb-mongosh -y
VALIDATE $? "Installing Mongodb client"

Status=$(mongosh --host mongodb.cloudwithmanoj.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $Status -lt 0 ]
then 
    mongosh --host mongodb.cloudwithmanoj.online </app/db/master-data.js
    VALIDATE $? "Loading Master Data in to MongoDb"
else 
    echo "Data is already loaded we are skipping"
fi

