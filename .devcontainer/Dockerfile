FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install common dependencies
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		gnupg \
		lsb-release \
		unzip \
		git \
		sudo \
		less \
		openssh-client \
		bash-completion \
	&& rm -rf /var/lib/apt/lists/*

# Install HashiCorp apt repository and Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
	&& echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends terraform \
	&& rm -rf /var/lib/apt/lists/*

# Create non-root user (vscode) with sudo privileges
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME || true \
	&& useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
	&& usermod -aG sudo $USERNAME \
	&& echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
	&& chmod 0440 /etc/sudoers.d/$USERNAME

# Set workspace folder
WORKDIR /workspace

# Default to non-root user
USER $USERNAME

# By default show terraform version (useful quick check) and drop to a shell
CMD ["bash", "-lc", "terraform -version || bash"]
