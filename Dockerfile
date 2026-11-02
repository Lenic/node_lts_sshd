FROM alpine:edge

LABEL maintainer="Lenic (Lenic@live.cn)"

RUN apk update && apk upgrade && \
    apk add nodejs npm git vim curl zsh openssh emacs-pgtk-nativecomp rsync tmux fzf ripgrep tzdata diffutils xclip && \
    sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    ssh-keygen -A && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo "Asia/Tokyo" > /etc/timezone && \
    apk del tzdata && \
    rm -f /var/cache/apk/*

# Alpine's nodejs package is built without corepack, so install it separately via npm
RUN npm i -g corepack && \
    corepack enable pnpm && \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 corepack install -g pnpm@latest && \
    mkdir -p /etc/zsh && \
    printf '%s\n' \
        'export COREPACK_ENABLE_DOWNLOAD_PROMPT=0' \
        'export PNPM_HOME="$HOME/.local/share/pnpm"' \
        'export PATH="$PNPM_HOME:$PATH"' >> /etc/zsh/zshenv && \
    echo "set -g set-clipboard on" >> /root/.tmux.conf && \
    printf '%s\n' \
        'alias e="emacs -nw"' \
        'ed() { if [ -n "$1" ]; then emacs --daemon="$1"; else emacs --daemon; fi; }' \
        'ec() { if [ -n "$1" ]; then emacsclient -t -s "$1"; else emacsclient -t; fi; }' \
        'alias tn="tmux new -s"' \
        'alias tt="tmux a -t"' \
        'alias tl="tmux ls"' >> /etc/zsh/zshrc && \
    echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf && \
    sed -i -e '/^root:/s|:[^:]*$|:/bin/zsh|' /etc/passwd && \
    echo "root:admin" | chpasswd

# Install oh-my-zsh to a shared directory used by all users; only root updates it
RUN ZSH=/usr/share/oh-my-zsh sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# New users get the zsh and tmux configs and a workspace directory copied from /etc/skel
RUN mkdir -p /etc/skel/workspace && \
    cp -a /root/.zshrc /root/.tmux.conf /etc/skel/

COPY --chmod=755 add-user.sh /root/add-user.sh

# Use the Aliyun mirror
# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

EXPOSE 22

WORKDIR /root/workspace

CMD ["/usr/sbin/sshd", "-D"]
