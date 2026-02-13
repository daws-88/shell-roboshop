#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
START_TIME=$(date +%s)
MONGODB_HOST=mongodb.daws88s.fun
SCRIPT_DIR=$PWD
USERID=$(id -u)
LOG_FOLDER="/var/log/shell-script"
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
        echo -e "$2....$G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

###### CATALOGUE ####

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disable nodejs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs 20"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "install nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "add user"
else
    echo -e "User already exist...$Y SKIPPING $N"| tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "create /app"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "download code"

cd /app
VALIDATE $? "move to /app"

rm -rf /app/* $>>$LOG_FILE
VALIDATE $? "remove old code"

unzip /tmp/catalogue.zip &>>LOG_FILE
VALIDATE $? "unzip the code"

npm install &>>$LOG_FILE
VALIDATE $? "install dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "created systemctl service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reload files"

systemctl enable catalogue &>>LOG_FILE
VALIDATE $? "enable catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "copy mongo.repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "install mongodb client"

INDEX=$(mongosh mongodb.daws88s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "load products"
else
    echo -e "products already exist..$Y SKIPPING $N"
fi
systemctl restart catalogue
VALIDATE $? "restart catalogue"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo "script executed in: $TOTAL_TIME in seconds"



