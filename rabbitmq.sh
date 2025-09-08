#!/bin/bash 
userid=$(id -u)
directory=$PWD

if [ $userid -ne 0 ]
then 
    echo "You are not a root user please run with root access"
    exit 1 
else 
    echo "You are running with root user access"
fi 

VALIDATE()
{
    if [ $1 -eq 0 ]
    then 
        echo "$2 is success"
    else 
        echo "$2 is failure"
        exit 1 
}

cp $directory/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo

dnf install rabbitmq-server -y

systemctl enable rabbitmq-server
systemctl start rabbitmq-server

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"