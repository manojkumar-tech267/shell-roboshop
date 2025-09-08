#!/bin/bash 

userid=$(id -u)

if [ $userid -ne 0 ]
then 
    echo "you are not a root user please run with root access"
    exit 1 
else 
    echo "you are running with root access"
fi 

directory=$PWD

log_folder="/var/log/roboshop-logs"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$log_folder/$script_name.log"

mkdir -p $log_folder

VALIDATE()
{
    if [ $1 -eq 0 ]
    then 
        echo "$2 is success" | tee -a $log_folder
    else 
        echo "$2 is failure" | tee -a $log_folder
        exit 1 
    fi
}

dnf module disable nodejs -y &>> $log_folder
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y &>> $log_folder
VALIDATE $? "enabling nodejs"

dnf install nodejs -y &>> $log_folder
VALIDATE $? "installing nodejs"

mkdir /app 
VALIDATE $? "Creating app directory"

id roboshop  &>> $log_folder
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop user"
else 
    echo "User roboshop is already there we are skipping"
fi 

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> $log_folder
VALIDATE $? "Downloading cart code"

rm -rf /app/*
cd /app
unzip /tmp/cart.zip &>> $log_folder
VALIDATE $? "Extracting cart"

npm install  &>> $log_folder
VALIDATE $? "installing nodejs dependencies"

cp $directory/cart.service /etc/systemd/system/cart.service
VALIDATE $? "copying cart.service file"

systemctl daemon-reload &>> $log_folder
VALIDATE $? "reload cart service"

systemctl enable cart  &>> $log_folder
systemctl start cart &>> $log_folder
VALIDATE $? "start and enable cart"

