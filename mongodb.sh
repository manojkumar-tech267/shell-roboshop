#!/bin/bash 

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m" 

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
directory=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at $(date)" 

if [ $USERID -ne 0 ]
then 
    echo "You are not a root user please run with root user" 
    exit 1 
else 
    echo "You are a root user" 
fi 

VALIDATE() 
{
    if [ $1 -eq 0 ]
    then 
        echo "Installing $2 Success" 
    else 
        echo "Installing $2 Failure" 
        exit 1  
    fi 
}

cp $directory/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo repo" 

dnf install mongodb-org -y 
VALIDATE $? "Installing mongodb" 

systemctl enable mongod 
VALIDATE $? "Enabling mongod"

systemctl start mongod 
VALIDATE $? "Starting mongod"

sed -i "s/127.0.0.1/0.0.0.0/" /etc/mongod.conf
VALIDATE $? "Updating bind IP in mongod.conf"

systemctl restart mongod
VALIDATE $? "Restarting mongod" 






