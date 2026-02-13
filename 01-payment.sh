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
        echo -e "$2....$G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

###### PAYMENT ######
dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing python"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "add user"
else
    echo -e "User already exist...$Y SKIPPING $N"| tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "Created directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloaded code"

cd /app 
rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "remove old code"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzip the code"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Install dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "Created systemctl services"

systemctl daemon-reload
VALIDATE $? "Service files reloaded"

systemctl enable payment &>>$LOG_FILE
systemctl start payment &>>$LOG_FILE
VALIDATE $? "Start payment"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo "script executed in: $TOTAL_TIME in seconds"