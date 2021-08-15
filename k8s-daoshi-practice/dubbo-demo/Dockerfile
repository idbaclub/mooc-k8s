FROM hub.daoshi.club/kubernetes/openjdk:8-jre-alpine

COPY target/Root   /Root 

ENTRYPOINT ["sh", "/Root/bin/start.sh"]
