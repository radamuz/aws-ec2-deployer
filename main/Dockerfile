FROM ubuntu:24.04

ARG DOCKER_GID=999
ARG AWSCLI_ARCH=arm64

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      sudo \
      openssh-client \
      curl \
      unzip \
      jq \
      time \
      openssl \
      postgresql-client \
      ca-certificates \
      gnupg && \
    rm -rf /var/lib/apt/lists/*

RUN if getent group ubuntu >/dev/null; then \
        groupmod -g 1000 ubuntu; \
    else \
        groupadd -g 1000 ubuntu; \
    fi && \
    if id -u ubuntu >/dev/null 2>&1; then \
        usermod -u 1000 -g 1000 -s /bin/bash ubuntu; \
    else \
        useradd -m -u 1000 -g 1000 -s /bin/bash ubuntu; \
    fi

ENV HOSTNAME=ubuntu

RUN printf "\n# Ubuntu-like colored prompt\nexport PS1='\\[\\e[01;32m\\]\\u@ubuntu\\[\\e[00m\\]:\\[\\e[01;34m\\]\\w\\[\\e[00m\\]\\$ '\n" >> /home/ubuntu/.bashrc && \
    chown ubuntu:ubuntu /home/ubuntu/.bashrc

WORKDIR /home/ubuntu/infranettone-aws-ec2-deployer

RUN case "$AWSCLI_ARCH" in \
      arm64) AWSCLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" ;; \
      amd64) AWSCLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" ;; \
      *) echo "AWSCLI_ARCH inválido: $AWSCLI_ARCH (usa arm64 o amd64)" >&2; exit 1 ;; \
    esac && \
    curl "$AWSCLI_URL" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install && \
    rm -rf awscliv2.zip ./aws

RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc

RUN tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

RUN if getent group docker >/dev/null; then \
        CURRENT_DOCKER_GID="$(getent group docker | cut -d: -f3)"; \
        if [ "$CURRENT_DOCKER_GID" != "$DOCKER_GID" ]; then \
            groupmod -g "$DOCKER_GID" docker; \
        fi; \
    else \
        groupadd -g "$DOCKER_GID" docker; \
    fi && \
    usermod -aG docker ubuntu

COPY --chown=ubuntu:ubuntu . /home/ubuntu/infranettone-aws-ec2-deployer

USER ubuntu

CMD ["tail", "-f", "/dev/null"]
