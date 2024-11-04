# Create a user and group at the beginning
FROM maven:3.8.5-openjdk-17 AS build

# Create a group and user with specific IDs
RUN groupadd -g 3000 mygroup && \
    useradd -u 1000 -g mygroup -m myuser

# Switch to the new user
USER myuser

# Set the working directory
WORKDIR /app

# Copy the pom.xml and download dependencies
COPY --chown=myuser:mygroup pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the application
COPY --chown=myuser:mygroup src ./src
RUN mvn package -DskipTests

# Stage 2: Create the runtime image
FROM openjdk:17-jdk-slim

# Create the same non-root user in the runtime image
RUN groupadd -g 3000 mygroup && \
    useradd -u 1000 -g mygroup -m myuser

# Set the working directory
WORKDIR /app

# Copy the jar file from the build stage, maintaining ownership
COPY --from=build --chown=myuser:mygroup /app/target/*.jar app.jar

# Switch to the non-root user
USER myuser:mygroup

# Expose the application port
EXPOSE 8080

# Command to run the application
CMD ["java", "-jar", "app.jar"]
