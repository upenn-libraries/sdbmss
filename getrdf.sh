# Used by corresponding cron task to download RDF data file, and move the zipped file to
# the appropriate place to be publicly available on the rails app

if ! [ -d "public/static/docs" ]; then

	echo "CREATING STATIC/DOCS"
	mkdir public/static/docs

fi

dir="/usr/src/app/public/static/docs/output"

echo "GETTING LIST OF TTL EXPORTS"
old_files=${dir}/output*.ttl.gz

echo "Found old files: ${old_files}"

new_file=${dir}/output-$(date +%Y%m%dT%H%M%S-%Z).ttl.gz


echo "GETTING RDF FROM JENA"
curl -u admin:$ADMIN_PASSWORD jena:3030/sdbm | gzip > ${new_file}

# make sure we exited cleanly
if [ "$?" -eq "0" ]; then
  # make sure the file was created
  if [ -f "${new_file}" ]; then
    echo "Created new RDF export: ${new_file}"
  else
    echo "ERROR: File not created: ${new_file}"
    exit 1
  fi
else
  echo "ERROR: Error creating RDF backup: ${new_file}"
  exit 1
fi

# remove any old files
if [ -n  "$old_files" ]; then
  echo "Deleting old files ${old_files}"
  rm $old_files
fi

echo "DONE"