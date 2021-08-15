USER=admxj
REPOSITORY_NAME=web-demo
VERSION=test

IMAGE_NAME=${USER}/${REPOSITORY_NAME}:${VERSION}

cd ..

mvn clean package

cd ./web-demo

docker build -t ${IMAGE_NAME} .

docker run -it --name web-demo-test --rm -p 8080:8080 ${IMAGE_NAME}
