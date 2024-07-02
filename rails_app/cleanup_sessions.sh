# Used in corresponding cron task, this is a very simple MYQSL query to remove sessions from the database that are more than one month old.

mysql -u $MYSQL_USER --password=$MYSQL_PASSWORD --host=db sdbm -e "delete from sessions where updated_at < DATE_ADD(CURRENT_DATE(), INTERVAL -1 MONTH);"