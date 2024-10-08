FROM alpine

MAINTAINER Lenic (Lenic@live.cn)

RUN apk update && apk upgrade && \
    apk add nodejs npm git vim curl zsh openssh openssh-server emacs rsync tmux fzf ripgrep tzdata diffutils xclip && \
    sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N '' -q && \
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' -q && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk del tzdata && \
    rm -f /var/cache/apk/*

RUN npm i -g yarn && \
    echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf && \
    sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd && \
    echo "root:admin" | chpasswd

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 使用阿里镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

EXPOSE 22

WORKDIR /root/workspace

CMD ["/usr/sbin/sshd", "-D"]
