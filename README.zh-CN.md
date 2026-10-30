# node_lts_sshd

[English](./README.md) | **简体中文** | [日本語](./README.ja.md)

基于 Alpine Linux edge 的远程 Node.js 开发环境。容器内运行 SSH 服务，通过 SSH 登录后即可使用 zsh、Emacs、tmux、pnpm 等工具进行开发。

## 特性

- **基础镜像**：`alpine:edge`，支持 `aarch64` 和 `x86_64`
- **时区**：`Asia/Tokyo`
- **Node.js**：Alpine 仓库提供的 `nodejs`，包管理器为 pnpm（通过 corepack 管理，可按项目切换版本）
- **Shell**：zsh + oh-my-zsh（所有用户共用一份，安装在 `/usr/share/oh-my-zsh`）
- **编辑器**：Emacs（`emacs-pgtk-nativecomp`，支持 native-comp）、vim
- **其它工具**：git、curl、tmux、fzf、ripgrep、rsync、diffutils
- **剪贴板**：通过 OSC 52 将复制内容同步到本机剪贴板，无需 X11
- **多用户**：提供 `add-user.sh` 一键创建使用 zsh 的用户

## 镜像 tag

tag 格式为 `<alpine 版本>-<架构>-<日期>`，例如：

| tag | 架构 |
|---|---|
| `lenic/node_lts_sshd:edge-aarch64-20261030` | Apple Silicon、ARM 服务器 |
| `lenic/node_lts_sshd:edge-x86_64-20261030` | Intel / AMD |

## 快速开始

以下示例使用 Apple 的 [`container`](https://github.com/apple/container) 命令；使用 Docker、OrbStack、Colima 时，把 `container` 换成 `docker` 即可（卷相关命令写法略有差异）。

```sh
# 创建持久化卷（只需一次）
container volume create home

# 启动容器，把容器的 22 端口映射到本机 2222
container run -d --name dev -p 2222:22 \
  -v home:/home \
  lenic/node_lts_sshd:edge-aarch64-20261030

# 以 root 登录（默认密码 admin）
ssh root@localhost -p 2222
```

> [!WARNING]
> root 默认密码 `admin` 写在 Dockerfile 中。登录后请立即用 `passwd` 修改，或改用 SSH 密钥登录，尤其是端口暴露到局域网或公网时。

## 创建用户

```sh
/root/add-user.sh [-u uid] <用户名> [全名]

# 示例
/root/add-user.sh -u 1000 lenic "Lenic Rayleigh"
```

新用户会：

- 以 zsh 作为登录 shell
- 从 `/etc/skel` 获得 `.zshrc`（指向共享的 oh-my-zsh）、`.tmux.conf` 和 `workspace` 目录

`-u` 用于固定 UID。配合 `/home` 持久化卷使用时，建议每个用户都固定 UID，见 [FAQ](#如何保留用户的-ssh-和代码)。

## 构建镜像

### 本地构建

```sh
./build.sh                          # 构建 aarch64，tag 为 edge-aarch64-<当天日期>
ARCH=x86_64 ./build.sh              # 构建 x86_64
IMAGE=myname/dev ./build.sh         # 自定义镜像名
./build.sh --no-cache               # 其它参数会原样传给 build 命令
BUILDER=docker ./build.sh           # 指定构建工具
```

`build.sh` 优先使用 Apple `container`，其次 `docker`。使用 `container` 时会自动启动其后台服务。

### GitHub Actions

`.github/workflows/docker.yml` 会在 x86_64 和 aarch64 的原生 runner 上分别构建，并推送到 Docker Hub，每次只生成两个带日期的 tag。

- 目前只能手动触发：在仓库的 Actions 页面点击 **Run workflow**，或运行 `gh workflow run docker.yml`
- 需要在仓库 **Settings → Secrets and variables → Actions** 中配置：
  - `DOCKERHUB_USERNAME`：Docker Hub 用户名
  - `DOCKERHUB_TOKEN`：Docker Hub 的 Personal access token（Read & Write 权限）
- 如需推送到 master 时自动构建或每周定时构建，取消 workflow 中 `push` / `schedule` 部分的注释即可

## 使用说明

### pnpm

pnpm 由 corepack 管理。在项目的 `package.json` 中声明版本，进入项目目录后运行 `pnpm` 会自动使用对应版本：

```json
"packageManager": "pnpm@10.x.x"
```

运行 `corepack use pnpm@latest` 可写入或更新该字段。不在项目中时使用镜像构建时安装的最新版。

### 快捷命令

| 别名 | 命令 |
|---|---|
| `e` / `emacs` | `emacs -nw` |
| `tn <名称>` | `tmux new -s <名称>`，新建会话 |
| `tt <名称>` | `tmux a -t <名称>`，连接会话 |
| `tl` | `tmux ls`，列出会话 |

### 剪贴板（OSC 52）

在容器中复制的内容可以直接进入本机剪贴板，需要以下配置：

1. **tmux**：镜像已在 `.tmux.conf` 中设置 `set -g set-clipboard on`
2. **Emacs**：在 `init.el` 中添加
   ```elisp
   (setq xterm-extra-capabilities '(setSelection modifyOtherKeys))       ; 直接在终端中运行时
   (setq xterm-tmux-extra-capabilities '(setSelection modifyOtherKeys))  ; 在 tmux 中运行时
   ```
3. **本机终端**：iTerm2 需在 Settings → General → Selection 中勾选 *Applications in terminal may access clipboard*；Ghostty、WezTerm、kitty 默认支持

粘贴请直接使用本机终端的粘贴快捷键（如 ⌘V）。

## FAQ

### Docker Hub 还能在服务器上自动构建吗？

Docker Hub 自 2021 年起只有付费订阅才能使用自动构建（Autobuilds）。替代方案：

- 本地构建后推送（见 [本地构建](#本地构建)）
- 使用 GitHub Actions 构建并推送，公开仓库免费，且提供原生 arm64 runner（见 [GitHub Actions](#github-actions)）

### macOS 上用什么工具构建和运行容器？

| 工具 | 说明 |
|---|---|
| Apple `container` | Apple 官方开源工具，免费。每个容器运行在独立的轻量虚拟机中。需 Apple Silicon 和 macOS 26 及以上。`brew install container` 安装 |
| OrbStack | 启动快、资源占用低，与 `docker` 命令完全兼容。个人使用免费，商业用途需付费 |
| Colima | 免费开源，纯命令行。`brew install colima docker docker-buildx` 安装 |

只需要构建本镜像并在本机运行时，Apple `container` 完全够用；需要 Docker Compose 或依赖 Docker API 的工具时，选择 OrbStack 或 Colima。

### Apple `container` 和 `docker` 命令有什么不同？

`container` 的子命令与 `docker` 大体对应，但并非完全兼容：

```sh
container system start                 # 启动后台服务（首次会下载内核）
container build -t <镜像> .             # 构建
container run -d --name dev -p 2222:22 <镜像>
container ls -a                        # 列出容器
container image ls -v                  # 列出镜像（含大小）
container registry login docker.io     # 登录 Docker Hub
container image push <镜像>             # 推送
```

不支持 Docker Compose，依赖 Docker API 的工具（IDE 插件、Testcontainers 等）也无法直接对接。

### 为什么要通过 npm 安装 corepack？

Alpine 的 `nodejs` 包编译时使用了 `--without-corepack`，仓库中也没有单独的 `corepack` 包，因此需要 `npm i -g corepack`。另外，Node.js 从 25 起官方也不再内置 corepack，这种方式可以保持兼容。

### 为什么 Emacs 用的是 `emacs-pgtk-nativecomp`？

Alpine 现在的 `emacs` 包只包含公共文件，**没有 `emacs` 可执行程序**，需要选择具体的变体：

| 包 | 安装大小 | 说明 |
|---|---|---|
| `emacs-nox` | 约 105MB | 纯终端版，不支持 native-comp |
| `emacs-pgtk-nativecomp` | 约 297MB | GTK 版，支持 native-comp（本镜像使用） |
| `emacs-gtk3-nativecomp` | 约 298MB | GTK3 + X11，支持 native-comp |
| `emacs-x11-nativecomp` | 约 350MB | X11，支持 native-comp |

`emacs-nox` 没有 native-comp 版本。图形版在终端中需要加 `-nw` 启动，镜像已设置别名 `e` 和 `emacs` 为 `emacs -nw`。不加 `-nw` 时会报 `cannot open display` 而不会自动退回终端模式。

如果更看重镜像体积，可以换回 `emacs-nox`。

### 如何停止并删除容器，但保留镜像？

```sh
container stop dev      # 正常停止（默认等待 5 秒后强制结束）
container rm dev        # 删除已停止的容器
container rm -f dev     # 直接删除运行中的容器
```

这些命令只作用于容器，不会删除镜像。

### 如何删除镜像？

```sh
container image rm lenic/node_lts_sshd:edge-aarch64-20261030
container image prune       # 删除没有 tag 的悬空镜像
container image prune -a    # 删除所有未被容器使用的镜像
```

被运行中容器使用的镜像需要先删除容器。

### 如何查看镜像大小？

```sh
container image ls -v      # FULL SIZE 列
container image inspect <镜像> | jq '.[0].variants[] | {arch: .platform.architecture, size}'
```

显示的是压缩后的大小（传输量）。解压后实际占用的空间更大，例如 271.5 MB 的镜像解压后约 774 MB，主要来自 Emacs native-comp 版及其依赖（gcc、GTK 等）。

### GitHub Actions 会生成哪些 tag？

每次构建只生成两个带日期的 tag：`edge-x86_64-<日期>` 和 `edge-aarch64-<日期>`，不生成多架构 tag 或不带日期的 tag。日期按日本时区计算，两个架构共用同一个日期。

### 如何持久化代码，避免删除容器后丢失？

使用命名卷或绑定挂载：

| | 命名卷（推荐） | 绑定挂载本机目录 |
|---|---|---|
| 数据位置 | `container` 管理的 ext4 磁盘镜像 | 本机文件夹 |
| 读写性能 | 好 | 较慢，`pnpm install` 等大量小文件操作尤其明显 |
| 本机能否直接访问 | 不能 | 能 |

```sh
container volume create home
container run ... -v home:/home ...         # 命名卷
container run ... -v ~/code:/data ...       # 绑定挂载
```

注意：

- 命名卷中会有 ext4 的 `lost+found` 目录，属于正常现象
- 新卷的根目录归 root 所有，普通用户需要先由 root 执行 `chown`
- 默认最大容量 512 GiB，按实际使用量占用磁盘
- `container volume prune` 会立即删除所有未被容器引用的卷，数据无法恢复

### 如何保留用户的 `.ssh` 和代码？

推荐将整个 `/home` 挂载为一个卷，`.ssh`、`workspace`、`.zshrc` 等都会一并保留：

```sh
container run ... -v home:/home ...
/root/add-user.sh -u 1000 lenic "Lenic Rayleigh"
```

**不要将卷直接挂载到 `/home/<用户名>` 下的某个目录**（如 `~/.ssh`、`~/workspace`）。挂载时会提前创建 `/home/<用户名>`，BusyBox 的 `adduser` 发现家目录已存在就会跳过 `/etc/skel` 的复制，导致缺少 `.zshrc` 等配置；同时挂载目录归 root 所有，用户无法写入，sshd 也会因 `~/.ssh` 归属不正确而拒绝密钥登录。

使用 `/home` 卷时：

- 换新容器后仍需重新运行 `add-user.sh`，因为 `/etc/passwd` 不在卷中；家目录数据不受影响
- 请使用 `-u` 固定 UID，确保与卷中文件的归属一致
- root 的 `.ssh` 可单独挂载：`-v rootssh:/root/.ssh`，首次挂载后需执行 `chmod 700 /root/.ssh`

### 重新构建镜像后 SSH 提示 `REMOTE HOST IDENTIFICATION HAS CHANGED`？

SSH 主机密钥是在构建镜像时生成的，重新构建后会改变。删除本机的旧记录即可：

```sh
ssh-keygen -R "[localhost]:2222"
```

## 许可证

[MIT](./LICENSE)

---

本文档使用 [Claude](https://claude.ai) 生成。
