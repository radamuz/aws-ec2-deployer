FROM ubuntu:24.04

RUN apt update -y

RUN apt upgrade -y

RUN apt install -y \
    sudo

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

COPY --chown=ubuntu:ubuntu . /home/ubuntu/infranettone-aws-ec2-deployer

RUN apt install curl unzip ca-certificates -y

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" && \
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

RUN apt update -y

RUN apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

RUN usermod -aG docker ubuntu

USER ubuntu
