#!/bin/bash 
userid=$(id -u)

if [ $userid -ne 0 ]
then 
    echo "You are not a root user please run with root access"
    exit 1 
else 
    echo "You are root user"
fi 

VALIDATE()
{
    if [ $1 -eq 0 ]
    then 
        echo "$2 is successful!!!"
    else 
        echo "$2 is failed!!!"
        exit 1 
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongo.repo"

dnf install mongodb-org -y 
VALIDATE $? "Installing Mongodb"

systemctl enable mongod
VALIDATE $? "Enabling Mongod"

systemctl start mongod
VALIDATE $? "Starting Mongodb"

sed 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
VALIDATE $? "Allowing Remote connections"

systemctl restart mongod
VALIDATE $? "Restarting Mongodb"