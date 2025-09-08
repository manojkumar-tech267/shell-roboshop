#!/bin/bash 
userid=$(id -u)

if [ $userid -ne 0 ]
then 
    echo "You are not a root user please run with root access" | tee -a $Log_File
    exit 1 
else 
    echo "You are root user" | tee -a $Log_File
fi 

Log_Folder="/var/log/roboshop-logs"
mkdir -p $Log_Folder
File_Name=$(echo $0 | cut -d "." -f1)
Log_File=$Log_Folder/$File_Name.log

VALIDATE()
{
    if [ $1 -eq 0 ]
    then 
        echo "$2 is successful!!!" | tee -a $Log_File
    else 
        echo "$2 is failed!!!" | tee -a $Log_File
        exit 1 
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongo.repo"

dnf install mongodb-org -y &>> $Log_File
VALIDATE $? "Installing Mongodb"

systemctl enable mongod
VALIDATE $? "Enabling Mongod"

systemctl start mongod
VALIDATE $? "Starting Mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing Remote connections"

systemctl restart mongod
VALIDATE $? "Restarting Mongodb"