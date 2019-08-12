FROM node:lts-alpine

RUN apk update && \
    apk add zsh git openssh && \
    echo -e "Port 22\n" >> /etc/ssh/sshd_config && \
    curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh && \
    cp -a /etc/ssh /etc/ssh.cache && \
    rm -rf /var/cache/apk/*

EXPOSE 22 8080
