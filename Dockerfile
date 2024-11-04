# Stage 1: Build the application
FROM maven:3.8.5-openjdk-17 AS build
WORKDIR /app

# Copy the pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the application
COPY src ./src
RUN mvn package -DskipTests

# Stage 2: Create the runtime image
FROM openjdk:17-jdk-slim
WORKDIR /app

# Create a group and user
RUN groupadd -g 3000 mygroup && \
    useradd -u 1000 -g mygroup -m myuser

# Copy the jar file from the build stage
COPY --from=build /app/target/*.jar app.jar

# Change ownership of the app.jar file
RUN chown myuser:mygroup app.jar

# Switch to the new user and group
USER myuser:mygroup

# Expose the application port
EXPOSE 8080

# Command to run the application
CMD ["java", "-jar", "app.jar"]
