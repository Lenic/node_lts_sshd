FROM ubuntu

MAINTAINER Lenic (Lenic@live.cn)

RUN apt update && \
    apt -y upgrade && \
    apt -y install curl dirmngr apt-transport-https lsb-release ca-certificates software-properties-common && \
    curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt install -y nodejs git vim net-tools curl zsh openssh-server && \
    apt install -y language-pack-zh-hans rsync screen tmux && \
    add-apt-repository ppa:kelleyk/emacs && \
    apt update && \
    apt -y upgrade && \
    apt install emacs26-nox && \
    locale-gen zh_CN.UTF-8 && \
    mkdir -p /var/run/sshd && \
    echo "Asia/shanghai" > /etc/timezone && \
    sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config

RUN npm i -g yarn && \
    echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf && \
    chsh -s $(which zsh) && \
    echo "root:admin" | chpasswd

RUN sh -c "$(wget -qO- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && \
    echo "export LC_ALL='zh_CN.utf8'" >> ~/.zshrc

EXPOSE 22

WORKDIR /root/workspace

CMD ["/usr/sbin/sshd", "-D"]
