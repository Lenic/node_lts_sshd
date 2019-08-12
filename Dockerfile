FROM ubuntu

MAINTAINER Lenic (Lenic@live.cn)

RUN apt update && \
    apt install -y git vim net-tools curl zsh openssh-server && \
    mkdir -p /var/run/sshd && \
    echo "Asia/shanghai" > /etc/timezone && \
    sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    cd /opt && \
    wget https://nodejs.org/dist/v10.16.2/node-v10.16.2-linux-x64.tar.xz -O a.tar.xz && \
    tar -xJf a.tar.xz && \
    rm -rf a.tar.xz && \
    echo "PATH=$PATH:/opt/node-v10.16.2-linux-x64/bin" >> ~/.bashrc

RUN PATH=$PATH:/opt/node-v10.16.2-linux-x64/bin && \
    npm i -g yarn --registry=http://registry.npm.taobao.org && \
    echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf && \
    chsh -s $(which zsh) && \
    echo "root:admin" | chpasswd

RUN sh -c "$(wget -qO- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
