#!/bin/bash

# Install Syft
echo "Installing Syft..."
curl -sSL https://github.com/anchore/syft/releases/download/v0.66.0/syft_0.66.0_linux_amd64.tar.gz | tar xz -C /usr/local/bin syft

# Install Trivy
echo "Installing Trivy..."
apt-get install -y wget
wget https://github.com/aquasecurity/trivy/releases/download/v0.19.2/trivy_0.19.2_Linux-64bit.deb
dpkg -i trivy_0.19.2_Linux-64bit.deb
echo "Trivy installed at: $(which trivy)"
trivy --version  # Verify installation

# Install GitHub CLI and jq
echo "Installing GitHub CLI and jq..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
apt-get update
apt-get install -y gh jq

# Install Cosign
echo "Installing Cosign..."
curl -sSL -o /usr/local/bin/cosign https://github.com/sigstore/cosign/releases/download/v2.2.3/cosign-linux-amd64
chmod +x /usr/local/bin/cosign

echo "All tools installed successfully."
