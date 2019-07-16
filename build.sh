# This is a simple script to create a new docker image for the rails app with a version number coming from the 'VERSION' text file
#
# It's not neccessary, but I found it useful

version=`cat VERSION`
echo "Building version: $version"

docker build . -t sdbm:latest -t sdbm:$version