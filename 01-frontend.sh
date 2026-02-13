#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
USERID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
mkdir -p $LOG_FOLDER
echo "Script strated at $(date)" | tee -a $LOG_FILE
if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script as root privelliage"
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ....$R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else 
        echo -e "$2 ....$G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nginx -y
VALIDATE $?

dnf module enable nginx:1.24 -y
VALIDATE $?

dnf install nginx -y
VALIDATE $?

systemctl enable nginx
VALIDATE $? 

rm -rf /usr/share/nginx/html/* 
VALIDATE $?

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $?

cd /usr/share/nginx/html 
VALIDATE $?

unzip /tmp/frontend.zip
VALIDATE $?

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $?

systemctl restart nginx
VALIDATE $? 



