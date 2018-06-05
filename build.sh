version=`cat VERSION`
echo "Building version: $version"

docker build . -t sdbm:latest -t sdbm:$version