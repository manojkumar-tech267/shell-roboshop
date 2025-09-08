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

read -s MYSQL_ROOT_PASSWORD
dnf install maven -y

mkdir /app 

id roboshop 
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop user"
else 
    echo "User roboshop is already there we are skipping"
fi 

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip

rm -rf /app/*
cd /app
unzip /tmp/shipping.zip

mvn clean package 
mv target/shipping-1.0.jar shipping.jar

cp $directory/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload

systemctl enable shipping 
systemctl start shipping

dnf install mysql -y 

mysql -h mysql.cloudwithmanoj.online -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities'

if [ $? -ne 0 ]
then 
    mysql -h mysql.cloudwithmanoj.online -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h mysql.cloudwithmanoj.online -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h mysql.cloudwithmanoj.online -uroot -pRoboShop@1 < /app/db/master-data.sql
    VALIDATE $? "Loading data in to mysql"
else 
    echo "Data is already loaded in to mysql"

systemctl restart shipping
