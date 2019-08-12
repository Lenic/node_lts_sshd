FROM node:lts-alpine

RUN apk update && \
    apk add zsh git openssh-server tzdata openrc && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    ssh-keygen -t rsa -P "" -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -t ecdsa -P "" -f /etc/ssh/ssh_host_ecdsa_key && \
    ssh-keygen -t ed25519 -P "" -f /etc/ssh/ssh_host_ed25519_key && \
    echo -e "Port 1022\nPermitRootLogin yes\n" >> /etc/ssh/sshd_config && \
    sh -c "$(wget -qO- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && \
    cp -a /etc/ssh /etc/ssh.cache && \
    rm -rf /var/cache/apk/* && \
    echo "root:admin" | chpasswd

EXPOSE 1022 8080

CMD ["/etc/init.d/sshd", "-D"]
