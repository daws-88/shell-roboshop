#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
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

###### RABBITMQ ########
cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "Adding mongo.repo"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Install rabbitmq"

systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE  "Enable rabbitmq"

systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Start rabbitmq"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Setting up permissions"

systemctl restart rabbitmq
VALIDATE $? "Restarting rabbitmq"




