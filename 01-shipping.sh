#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
START_TIME=$(date +%s)
MYSQL_HOST=mysql.daws88s.fun
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

###### SHIPPING ######
dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Install python"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "add user"
else
    echo -e "User already exist...$Y SKIPPING $N"| tee -a $LOG_FILE
fi

mkdir -p /app 
VALIDATE $? "Created directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloaded code"

cd /app
rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Remove old code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzip code"

mvn clean package  &>>$LOG_FILE
VALIDATE $? "Install Dependecies"

mv target/shipping-1.0.jar shipping.jar  &>>$LOG_FILE
VALIDATE $? "Moved to shipping.jar"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service  &>>$LOG_FILE
VALIDATE $? "Created systemctl services"

systemctl daemon-reload
systemctl enable shipping  &>>$LOG_FILE
VALIDATE $? "Enable shipping"

dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "Install mysql client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'  &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping
VALIDATE $? "Restart shipping" 

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"