FROM alpine

MAINTAINER Lenic (Lenic@live.cn)

RUN apk update && apk upgrade && \
    apk add nodejs npm git vim curl zsh openssh-server emacs && \
    apk add rsync screen tmux the_silver_searcher ripgrep && \
    apk cache --purge && \
    mkdir -p /var/run/sshd && \
    sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    ssh-keygen -y -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    apk -v cache clean && rm -f /var/cache/apk/*

RUN npm i -g yarn && \
    echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf && \
    sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd && \
    echo "root:admin" | chpasswd

RUN sh -c "$(wget -qO- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && \
    echo "export LC_ALL='zh_CN.utf8'" >> ~/.zshrc

# 使用阿里镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

EXPOSE 22

WORKDIR /root/workspace

CMD ["/usr/sbin/sshd", "-D"]
