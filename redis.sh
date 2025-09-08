#!/bin/bash 

userid=$(id -u)

if [ $userid -ne 0 ]
then 
    echo "You are not a root user please run with root user access"
    exit 1 
else 
    echo "you are running with root user access"
fi 

VALIDATE()
{
    if [ $1 -eq 0 ]
    then 
        echo "$2 is successful"
    else 
        echo "$2 failed"
        exit 1 
    fi
}

dnf module disable redis -y
VALIDATE $? "Disabling redis"

dnf module enable redis:7 -y
VALIDATE $? "Enabling redis"

dnf install redis -y 
VALIDATE $? "Installing Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing Remote Connections"

systemctl enable redis
systemctl start redis 
VALIDATE $? "Start and enable Redis"