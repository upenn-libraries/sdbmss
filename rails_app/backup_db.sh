# Used by corresponding cron task to export and zip .sql file

#_date=$(date +"%m-%d-%y")
_file="/tmp/sdbm.sql.gz"
mysqldump --host=db -u $MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE | gzip > "$_file"