FROM hub.daoshi.club/kubernetes/tomcat:8.5.69

RUN rm -rf /usr/local/tomcat/webapps/*
COPY target/web-demo-1.0-SNAPSHOT.war /usr/local/tomcat/webapps/ROOT.war

ENTRYPOINT ["/usr/local/tomcat/bin/catalina.sh", "run"]
