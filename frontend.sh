#!/bin/bash 

userid=$(id -u)

if [ $userid -ne 0 ]
then 
    echo "You are not a root user please run with root user access"
    exit 1 
else 
    echo "You are a root user you can proceed"
fi 

VALIDATE()
{
    if [ $1 -eq 0 ]
    then 
        echo "$2 is successful"
    else 
        echo "$2 is not successful"
        exit 1 
    fi
}

dnf module disable nginx -y
VALIDATE $? "Disabling Nginx"

dnf module enable nginx:1.24 -y
VALIDATE $? "Enabling Nginx"

dnf install nginx -y
VALIDATE $? "Installing Nginx"

systemctl enable nginx 
systemctl start nginx 
VALIDATE $? "Start and Enable Nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Removing default HTML content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloading frontend code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip
VALIDATE $? "Extracting frontend code"

cp nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx.conf file"

systemctl restart nginx 
VALIDATE $? "Restarting Nginx"