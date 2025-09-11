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

mkdir -p logs_folder
echo "Script started executing at: $(date)" | tee -a $log_file

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

dnf module disable nodejs -y &>> $log_file
VALIDATE $? "Disabling Nodejs"

dnf module enable nodejs:20 -y &>> $log_file
VALIDATE $? "Enabling Nodejs"

dnf install nodejs -y &>> $log_file
VALIDATE $? "Installing Nodejs"

mkdir -p /app 
VALIDATE $? "Creating app directory"

id roboshop &>> $log_file
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop user"
else 
    echo -e "$Y User is already there we are skipping $N" | tee -a $log_file
fi 

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> $log_file
VALIDATE $? "Downloading cart code"

rm -rf /app/*
cd /app 
unzip /tmp/cart.zip &>> $log_file
VALIDATE $? "unzipping cart files"

npm install &>> $log_file
VALIDATE $? "Installing Nodejs dependencies"

cp $script_dir/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copying cart.service file"

systemctl daemon-reload &>> $log_file
VALIDATE $? "Reloading cart service"

systemctl enable cart &>> $log_file
systemctl start cart &>> $log_file
VALIDATE $? "Start and enable cart"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME-START_TIME))
echo "Script completed execution successfully time taken is $TOTAL_TIME seconds" | tee -a $log_file