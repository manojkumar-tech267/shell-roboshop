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

echo "Please enter mysql root password to setup"
read -s mysql_root_password

VALIDATE()
{
    if [ $1 -eq 0 ]
    then 
        echo -e "$G $2 is success $N" | tee -a $log_file
    else 
        echo -e "$R $2 is failure $N" | tee -a $log_file
        exit 1 
    fi
}

dnf install maven -y &>> $log_file 
VALIDATE $? "Installing maven"

mkdir -p /app 
VALIDATE $? "creating app directory"

id roboshop &>> $log_file
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $log_file
    VALIDATE $? "Creating roboshop user" 
else 
    echo "User is already created we are skipping"
fi 

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $log_file
VALIDATE $? "Downloading shipping code"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip &>> $log_file
VALIDATE $? "Extracting shipping files"

mvn clean package &>> $log_file 
VALIDATE $? "Installing Java dependencies"

mv target/shipping-1.0.jar shipping.jar &>> $log_file
VALIDATE $? "Renaming to shipping.jar"

cp $script_dir/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying shipping.service file"

systemctl daemon-reload &>> $log_file
VALIDATE $? "Reloading shipping service"

systemctl enable shipping &>> $log_file
systemctl start shipping &>> $log_file
VALIDATE $? "Start and Enable shipping"

dnf install mysql -y &>> $log_file
VALIDATE $? "Installing mysql"

mysql -h mysql.cloudwithmanoj.online -u root -p$mysql_root_password -e 'use cities' &>> $log_file
if [ $? -ne 0 ]
then 
    mysql -h mysql.cloudwithmanoj.online -uroot -p$mysql_root_password < /app/db/schema.sql &>> $log_file
    mysql -h mysql.cloudwithmanoj.online -uroot -p$mysql_root_password < /app/db/app-user.sql &>> $log_file
    mysql -h mysql.cloudwithmanoj.online -uroot -p$mysql_root_password < /app/db/master-data.sql &>> $log_file
else
    echo "Data is already loaded we are skipping"
fi 

systemctl restart shipping &>> $log_file
VALIDATE $? "Restarting shipping"