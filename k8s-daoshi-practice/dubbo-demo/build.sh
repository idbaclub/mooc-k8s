USER=admxj
REPOSITORY_NAME=dubbo-demo
VERSION=test

IMAGE_NAME=${USER}/${REPOSITORY_NAME}:${VERSION}

cd ..

mvn clean package

cd ./dubbo-demo

docker build -t ${IMAGE_NAME} .

docker run -it --name tomcat-test --rm ${IMAGE_NAME}
