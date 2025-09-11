#!/bin/bash

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
    echo "$G you are running with root access $N"
fi 

logs_folder="/var/log/roboshop-logs"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$logs_folder/$script_name.log"

mkdir -p logs_folder
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

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo.repo file"

dnf install mongodb-org -y &>> $log_file
VALIDATE $? "Installing mongodb"

systemctl enable mongod &>> $log_file
systemctl start mongod &>> $log_file
VALIDATE $? "Start and Enable Mongodb"

sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf
VALIDATE $? "Allowing Remote Connections"

systemctl restart mongod &>> $log_file
VALIDATE $? "Restarting Mongodb"