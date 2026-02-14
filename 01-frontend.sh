#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
START_TIME=$(date +%s)
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

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disable nodejs"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "install nodwjs"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "enable nodejs"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "remove default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "download frontend content"

cd /usr/share/nginx/html &>>$LOG_FILE
VALIDATE $? "move to usr/share"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzip code"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "created systemctl services"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restrat nginx"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"