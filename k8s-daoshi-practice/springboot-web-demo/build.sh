USER=admxj
REPOSITORY_NAME=springboot-web-demo
VERSION=test

IMAGE_NAME=${USER}/${REPOSITORY_NAME}:${VERSION}

mvn clean package

docker build -t ${IMAGE_NAME} .

docker run -it --name tomcat-test --rm ${IMAGE_NAME}
