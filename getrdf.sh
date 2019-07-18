# Used by corresponding cron task to download RDF data file, and move the zipped file to
# the appropriate place to be publicly available on the rails app

if ! [ -d "public/static/docs" ]; then

	echo "CREATING STATIC/DOCS"
	mkdir public/static/docs

fi

echo "GETTING RDF FROM JENA"
curl -u admin:$ADMIN_PASSWORD jena:3030/sdbm | gzip > /usr/src/app/public/static/docs/output.ttl.gz

echo "DONE"