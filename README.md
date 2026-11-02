# node_lts_sshd

**English** | [简体中文](./README.zh-CN.md) | [日本語](./README.ja.md)

A remote Node.js development environment based on Alpine Linux edge. The container runs an SSH server; log in over SSH to develop with zsh, Emacs, tmux, pnpm and more.

## Features

- **Base image**: `alpine:edge`, supporting `aarch64` and `x86_64`
- **Time zone**: `Asia/Tokyo`
- **Node.js**: `nodejs` from the Alpine repositories, with pnpm as the package manager (managed by corepack, so the version can be switched per project)
- **Shell**: zsh + oh-my-zsh (one copy shared by all users, installed in `/usr/share/oh-my-zsh`)
- **Editors**: Emacs (`emacs-pgtk-nativecomp`, with native-comp) and vim
- **Other tools**: git, curl, tmux, fzf, ripgrep, rsync, diffutils
- **Clipboard**: copied text is synced to the local clipboard via OSC 52, no X11 required
- **Multiple users**: `add-user.sh` creates a zsh-ready user in one step

## Image tags

Tags follow the format `<alpine version>-<arch>-<date>`, for example:

| Tag | Architecture |
|---|---|
| `lenic/node_lts_sshd:edge-aarch64-20261030` | Apple Silicon, ARM servers |
| `lenic/node_lts_sshd:edge-x86_64-20261030` | Intel / AMD |

## Quick start

The examples below use Apple's [`container`](https://github.com/apple/container) command. With Docker, OrbStack or Colima, replace `container` with `docker` (volume commands differ slightly).

```sh
# Create a persistent volume (only once)
container volume create home

# Start the container, mapping container port 22 to local port 2222
container run -d --name dev -p 2222:22 \
  -v home:/home \
  lenic/node_lts_sshd:edge-aarch64-20261030

# Log in as root (default password: admin)
ssh root@localhost -p 2222
```

> [!WARNING]
> The default root password `admin` is set in the Dockerfile. Change it with `passwd` right after logging in, or switch to SSH key authentication, especially if the port is exposed to your LAN or the internet.

## Creating users

```sh
/root/add-user.sh [-u uid] <username> [full name]

# Example
/root/add-user.sh -u 1000 lenic "Lenic Rayleigh"
```

A new user:

- uses zsh as the login shell
- gets `.zshrc` (pointing to the shared oh-my-zsh), `.tmux.conf` and a `workspace` directory from `/etc/skel`

`-u` pins the UID. When using a persistent `/home` volume, pin the UID for every user; see the [FAQ](#how-do-i-keep-users-ssh-directories-and-code).

## Building the image

### Local build

```sh
./build.sh                          # Build aarch64, tagged edge-aarch64-<today>
ARCH=x86_64 ./build.sh              # Build x86_64
IMAGE=myname/dev ./build.sh         # Use a custom image name
./build.sh --no-cache               # Extra arguments are passed to the build command
BUILDER=docker ./build.sh           # Pick the build tool explicitly
```

`build.sh` prefers Apple `container` and falls back to `docker`. When using `container`, it starts the system services automatically.

### GitHub Actions

`.github/workflows/docker.yml` builds on native x86_64 and aarch64 runners and pushes to Docker Hub, producing only two dated tags per run.

- It is currently triggered manually: click **Run workflow** on the repository's Actions page, or run `gh workflow run docker.yml`
- Configure these in the repository under **Settings → Secrets and variables → Actions**:
  - `DOCKERHUB_USERNAME`: your Docker Hub username
  - `DOCKERHUB_TOKEN`: a Docker Hub personal access token (Read & Write)
- To build automatically on pushes to master or on a weekly schedule, uncomment the `push` / `schedule` sections in the workflow

## Usage

### pnpm

pnpm is managed by corepack. Declare the version in your project's `package.json`, and running `pnpm` inside the project uses that version automatically:

```json
"packageManager": "pnpm@10.x.x"
```

Run `corepack use pnpm@latest` to add or update this field. Outside a project, the latest version installed at image build time is used.

### Shortcuts

| Alias | Command |
|---|---|
| `e` | `emacs -nw` |
| `eds [name]` | `emacs --daemon[=name]`, start an Emacs daemon (optionally named) |
| `ec [name]` | `emacsclient -t [-s name]`, open a terminal frame on the daemon |
| `tn <name>` | `tmux new -s <name>`, create a session |
| `tt <name>` | `tmux a -t <name>`, attach to a session |
| `tl` | `tmux ls`, list sessions |

### Clipboard (OSC 52)

Text copied inside the container can go straight to your local clipboard with the following setup:

1. **tmux**: the image already sets `set -g set-clipboard on` in `.tmux.conf`
2. **Emacs**: add to your `init.el`
   ```elisp
   (setq xterm-extra-capabilities '(setSelection modifyOtherKeys))       ; when running directly in a terminal
   (setq xterm-tmux-extra-capabilities '(setSelection modifyOtherKeys))  ; when running inside tmux
   ```
3. **Local terminal**: in iTerm2, enable *Applications in terminal may access clipboard* under Settings → General → Selection; Ghostty, WezTerm and kitty support it by default

To paste, use your local terminal's paste shortcut (e.g. ⌘V).

## FAQ

### Can Docker Hub still build images on its servers?

Since 2021, Docker Hub Autobuilds are only available with a paid subscription. Alternatives:

- Build locally and push (see [Local build](#local-build))
- Build and push with GitHub Actions, which is free for public repositories and offers native arm64 runners (see [GitHub Actions](#github-actions))

### Which tool should I use on macOS to build and run containers?

| Tool | Notes |
|---|---|
| Apple `container` | Apple's official open-source tool, free. Each container runs in its own lightweight VM. Requires Apple Silicon and macOS 26 or later. Install with `brew install container` |
| OrbStack | Fast startup, low resource usage, fully compatible with the `docker` command. Free for personal use, paid for commercial use |
| Colima | Free and open source, command line only. Install with `brew install colima docker docker-buildx` |

If you only need to build this image and run it locally, Apple `container` is enough. If you need Docker Compose or tools that rely on the Docker API, choose OrbStack or Colima.

### How does Apple `container` differ from `docker`?

`container` subcommands broadly match `docker`, but they are not fully compatible:

```sh
container system start                 # Start the system services (downloads a kernel the first time)
container build -t <image> .           # Build
container run -d --name dev -p 2222:22 <image>
container ls -a                        # List containers
container image ls -v                  # List images (with sizes)
container registry login docker.io     # Log in to Docker Hub
container image push <image>           # Push
```

Docker Compose is not supported, and tools that rely on the Docker API (IDE plugins, Testcontainers, etc.) cannot connect to it directly.

### Why is corepack installed via npm?

Alpine's `nodejs` package is built with `--without-corepack`, and the repositories have no separate `corepack` package, so `npm i -g corepack` is required. Node.js also stopped bundling corepack starting with version 25, so this approach stays compatible.

### Why does the image use `emacs-pgtk-nativecomp`?

Alpine's `emacs` package now contains only common files, **without the `emacs` executable**, so you have to choose a specific variant:

| Package | Installed size | Notes |
|---|---|---|
| `emacs-nox` | ~105MB | Terminal only, no native-comp |
| `emacs-pgtk-nativecomp` | ~297MB | GTK, with native-comp (used by this image) |
| `emacs-gtk3-nativecomp` | ~298MB | GTK3 + X11, with native-comp |
| `emacs-x11-nativecomp` | ~350MB | X11, with native-comp |

There is no native-comp build of `emacs-nox`. The graphical variants need `-nw` to run in a terminal, so the image aliases `e` to `emacs -nw`. Running `emacs` directly without `-nw` fails with `cannot open display` instead of falling back to terminal mode. The `eds` + `ec` daemon workflow is not affected.

If image size matters more to you, switch back to `emacs-nox`.

### How do I stop and remove a container but keep the image?

```sh
container stop dev      # Stop gracefully (killed after 5 seconds by default)
container rm dev        # Remove a stopped container
container rm -f dev     # Remove a running container directly
```

These commands only affect containers, not images.

### How do I delete an image?

```sh
container image rm lenic/node_lts_sshd:edge-aarch64-20261030
container image prune       # Remove dangling images without tags
container image prune -a    # Remove all images not used by any container
```

To delete an image used by a running container, remove the container first.

### How do I check the image size?

```sh
container image ls -v      # FULL SIZE column
container image inspect <image> | jq '.[0].variants[] | {arch: .platform.architecture, size}'
```

The size shown is the compressed size (the amount transferred). The unpacked image takes more space: for example, a 271.5 MB image is about 774 MB unpacked, mostly due to the native-comp build of Emacs and its dependencies (gcc, GTK, etc.).

### Which tags does GitHub Actions produce?

Each run produces only two dated tags: `edge-x86_64-<date>` and `edge-aarch64-<date>`. No multi-arch or undated tags are created. The date is computed in the Japan time zone and shared by both architectures.

### How do I persist code so it survives removing the container?

Use a named volume or a bind mount:

| | Named volume (recommended) | Bind mount of a local directory |
|---|---|---|
| Where data lives | An ext4 disk image managed by `container` | A folder on your machine |
| I/O performance | Good | Slower, especially for many small files such as `pnpm install` |
| Accessible from the host | No | Yes |

```sh
container volume create home
container run ... -v home:/home ...         # Named volume
container run ... -v ~/code:/data ...       # Bind mount
```

Notes:

- A named volume contains an ext4 `lost+found` directory; this is normal
- The root directory of a new volume is owned by root, so root must `chown` it before a regular user can write to it
- The default maximum size is 512 GiB, and disk space is used only as data is written
- `container volume prune` immediately deletes every volume not referenced by a container, and the data cannot be recovered

### How do I keep users' `.ssh` directories and code?

Mount all of `/home` as one volume, so `.ssh`, `workspace`, `.zshrc` and everything else is kept together:

```sh
container run ... -v home:/home ...
/root/add-user.sh -u 1000 lenic "Lenic Rayleigh"
```

**Do not mount a volume directly at a directory under `/home/<username>`** (such as `~/.ssh` or `~/workspace`). Mounting creates `/home/<username>` in advance, and BusyBox `adduser` skips copying `/etc/skel` when the home directory already exists, leaving the user without `.zshrc` and other configs. The mounted directory is also owned by root, so the user cannot write to it, and sshd rejects key-based login because `~/.ssh` has the wrong owner.

When using a `/home` volume:

- Run `add-user.sh` again in each new container, because `/etc/passwd` is not on the volume; home directory data is unaffected
- Use `-u` to pin the UID so it matches the owner of the files on the volume
- Root's `.ssh` can be mounted separately with `-v rootssh:/root/.ssh`; run `chmod 700 /root/.ssh` after the first mount

### SSH shows `REMOTE HOST IDENTIFICATION HAS CHANGED` after rebuilding the image

The SSH host keys are generated when the image is built, so they change after a rebuild. Remove the old entry on your machine:

```sh
ssh-keygen -R "[localhost]:2222"
```

## License

[MIT](./LICENSE)

---

This document was generated with [Claude](https://claude.ai).
