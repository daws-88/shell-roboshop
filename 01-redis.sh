#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
START_TIME=$(date +%s)
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
###### REDIS #####
dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disable redis"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enable redis 7"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Install redis"

sed -i -e 's/127.0.0.1/0.0.0.0./g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>>$LOG_FILE
VALIDATE $? "Aloowing remote connections"

systemctl enable redis &>>$LOG_FILE
systemctl start redis &>>$LOG_FILE
VALIDATE $? "strat redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"