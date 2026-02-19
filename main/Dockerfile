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
