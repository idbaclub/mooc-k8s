USER=admxj
REPOSITORY_NAME=cronjob-demo
VERSION=test

IMAGE_NAME=${USER}/${REPOSITORY_NAME}:${VERSION}

mvn clean package

docker build -t ${IMAGE_NAME} .

docker run -it --name tomcat-test --rm ${IMAGE_NAME}
