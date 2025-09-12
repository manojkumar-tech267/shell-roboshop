#!/bin/bash

userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

logs_folder="/var/log/roboshop-logs"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$logs_folder/$script_name.log"
script_dir=$PWD

mkdir -p $logs_folder
echo "Script started executing at: $(date)" | tee -a $log_file

if [ $userid -ne 0 ]
then 
    echo -e "$R You are not a root user please run with root access $N" | tee -a $log_file
    exit 1 
else 
    echo -e "$G you are running with root access $N" | tee -a $log_file
fi

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


dnf module disable nginx -y &>> $log_file
VALIDATE $? "Disabling Nginx"

dnf module enable nginx:1.24 -y &>> $log_file
VALIDATE $? "Enaling Nginx 1.24"

dnf install nginx -y &>> $log_file
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>> $log_file
systemctl start nginx &>> $log_file
VALIDATE $? "Start and Enable Nginx"

rm -rf /usr/share/nginx/html/* &>> $log_file
VALIDATE $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $log_file
VALIDATE $? "Downloading Frontend code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>> $log_file
VALIDATE $? "Extracting Frontend code"


cp $script_dir/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx.conf file"

systemctl restart nginx &>> $log_file
VALIDATE $? "Restarting Nginx"