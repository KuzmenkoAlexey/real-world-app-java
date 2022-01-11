FROM gradle:6.9-jdk8 as build
WORKDIR /usr/app
ENV GRADLE_USER_HOME /usr/app
COPY src/ /usr/app/src/
COPY database/ /usr/app/database/
COPY gradle/ /usr/app/gradle/
COPY build.gradle gradlew /usr/app/
RUN ./gradlew build


FROM openjdk:8
WORKDIR /usr/app
COPY --from=build /usr/app/build/libs/app-0.0.1-SNAPSHOT.jar .
COPY application-prod.properties /usr/app/application.properties
ENTRYPOINT java -jar app-0.0.1-SNAPSHOT.jar