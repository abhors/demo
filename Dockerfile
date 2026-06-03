#FROM registry.cn-zhangjiakou.aliyuncs.com/abhors/ibm-semeru-runtimes:open-17-jre
FROM library/ibm-semeru-runtimes:open-17-jre
COPY ./target/*.jar /opt/app.jar
#暴露端口
EXPOSE 8080

#COPY ./cert /opt/cert/

#ENV TZ=PRC
#RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
#启动 如果启动时想要添加额外的配置可以通过docker run -e PARAM="-Dserver.port=8000 -Dspring.profiles.active-prod"
ENV PROFILES="dev"

ENV JVM_OPTS="-Duser.timezone=Asia/Shanghai -Xms512m -Xmx1024m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=512m -Xloggc:gc/gc.log -XX:+PrintGCDateStamps -XX:+PrintGC -XX:+HeapDumpOnOutOfMemoryError -XX:+UseG1GC -XX:NumberOfGCLogFiles=2 -XX:+UseGCLogFileRotation -XX:GCLogFileSize=100m"

# ENTRYPOINT exec java -Dspring.profiles.active=$PROFILES $JVM_OPTS -jar /opt/app.jar
ENTRYPOINT ["sh", "-c", "java -Dspring.profiles.active=$PROFILES $JVM_OPTS -jar /opt/app.jar"]

#ENTRYPOINT ["nohup","java", "-Xms256m", "-Xmx512m", "-XX:MetaspaceSize=128m", "-XX:MaxMetaspaceSize=512m","-Dfile.encoding=utf-8", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar", "$PROFILES_ACTIVE", "> /logs/lotpig-app.log 2>&1 &" ]

