FROM ubuntu

MAINTAINER Lenic (Lenic@live.cn)

RUN apt update && \
    apt install -y git net-tools curl zsh openssh-server && \
    mkdir -p /var/run/sshd && \
    echo "Asia/shanghai" > /etc/timezone && \
    sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    cd /opt && \
    wget https://nodejs.org/dist/v10.16.2/node-v10.16.2-linux-x64.tar.xz -O a.tar.xz && \
    tar -xvJf a.tar.xz && \
    rm -rf a.tar.xz && \
    sh -c "$(wget -qO- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && \
    echo "PATH=$PATH:/opt/node-v10.16.2-linux-x64/bin" >> ~/.zshrc && \
    chsh -s $(which zsh) && \
    npm i -g yarn --registry=http://registry.npm.taobao.org && \
    echo "root:admin" | chpasswd

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
