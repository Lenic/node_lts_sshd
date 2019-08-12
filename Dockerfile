FROM node:lts-alpine

RUN apk update && \
    apk add zsh git openssh openrc && \
    echo -e "Port 22\nPermitRootLogin yes\n" >> /etc/ssh/sshd_config && \
    sh -c "$(wget -qO- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && \
    cp -a /etc/ssh /etc/ssh.cache && \
    rm -rf /var/cache/apk/*

EXPOSE 22 8080

CMD ["/etc/init.d/sshd", "start"]
