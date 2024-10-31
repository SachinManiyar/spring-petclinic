#!/bin/bash

# Step 3: Build with Maven Wrapper
echo "Building with Maven Wrapper..."
# mvn clean package -DskipTests
# mv target/*.jar app.jar
mvn clean package -DskipTests
mv target/*.jar app-${BUILD_NUMBER}.jar

# Step 4: Generate artifact attestation
echo "Generating artifact attestation..."
npx actions-attest-build-provenance --subject-path ./app.jar

# Step 6: Generate SBOM with Syft
echo "Generating SBOM with Syft..."
syft dir:. -o cyclonedx-json > sbom.json

# Step 7: Upload SBOM
echo "Uploading SBOM..."
gh actions upload-artifact --name sbom --path sbom.json

# Step 10: Generate SBOM attestation
echo "Generating SBOM attestation..."
npx actions-attest-sbom --subject-path ./sbom.json --sbom-path ./sbom.json

# Step 11: Verify SBOM attestation
echo "Verifying SBOM attestation..."
gh attestation verify ./sbom.json --owner dheeman2912 --format=json

# Step 12: Build Docker Image using Maven
echo "Building Docker Image..."
./mvnw clean spring-boot:build-image -Dmaven.test.skip=true
