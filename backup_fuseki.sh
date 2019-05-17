echo "BACKING UP FUSEKI"

echo `curl -X POST -u admin:$ADMIN_PASSWORD jena:3030/$/backup/sdbm`

if [[ $? -eq 0 ]]; then
  echo "FUSEKI NOW BACKING UP"
else
  echo "UNABLE TO BACK UP FUSEKI" >&2
  exit $?
fi
