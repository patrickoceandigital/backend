FROM alpine as build

ARG MAVEN_VERSION=3.8.5
ARG USER_HOME_DIR="/root"
ARG BASE_URL=https://dlcdn.apache.org/.${MAVEN_VERSION}/binaries


# Install Java.
RUN apk --update --no-cache add openjdk11 curl

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
 && curl -fsSL -o /tmp/apache-maven.tar.gz https://dlcdn.apache.org/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz \
 && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
 && rm -f /tmp/apache-maven.tar.gz \
 && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
WORKDIR /workspace/app

#COPY mvnw .
#COPY .mvn .mvn
COPY pom.xml .
COPY src src

RUN mvn install -DskipTests
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

FROM openjdk:8-jdk-alpine
VOLUME /tmp
ARG DEPENDENCY=/workspace/app/target/dependency
COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app
ADD   /target/my_crud_backend-0.0.1-SNAPSHOT.jar app.jar
ENTRYPOINT ["java", "-Xmx750m", "-jar","/app.jar"]

