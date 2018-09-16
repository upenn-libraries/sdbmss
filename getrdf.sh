if ! [ -d "public/static/docs" ]; then

	echo "CREATING STATIC/DOCS"
	mkdir public/static/docs

fi

echo "GETTING RDF FROM JENA"
curl -u admin:$ADMIN_PASSWORD jena:3030/sdbm | gzip > /usr/src/app/public/static/docs/output2.ttl.gz

echo "DONE"