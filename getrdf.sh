if ! [ -d "public/static/docs" ]; then

	echo "CREATING STATIC/DOCS"
	mkdir public/static/docs

fi

echo "GETTING RDF FROM JENA"
curl jena:3030/sdbm | gzip > /usr/src/app/public/static/docs/output.ttl.gz

echo "DONE"