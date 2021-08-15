FROM  hub.daoshi.club/kubernetes/openjdk:8-jre-alpine

COPY target/springboot-web-demo-1.0-SNAPSHOT.jar /springboot-web-demo.jar

ENTRYPOINT ["java", "-jar", "/springboot-web-demo.jar"]
