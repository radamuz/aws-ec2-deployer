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

USER ubuntu
