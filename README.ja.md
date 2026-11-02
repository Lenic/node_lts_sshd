# node_lts_sshd

[English](./README.md) | [简体中文](./README.zh-CN.md) | **日本語**

Alpine Linux edge をベースにしたリモート Node.js 開発環境です。コンテナ内で SSH サーバーが動作しており、SSH でログインすれば zsh、Emacs、tmux、pnpm などのツールを使って開発できます。

## 特徴

- **ベースイメージ**：`alpine:edge`、`aarch64` と `x86_64` に対応
- **タイムゾーン**：`Asia/Tokyo`
- **Node.js**：Alpine リポジトリの `nodejs`。パッケージマネージャーは pnpm（corepack で管理しており、プロジェクトごとにバージョンを切り替え可能）
- **シェル**：zsh + oh-my-zsh（全ユーザーで 1 つを共有し、`/usr/share/oh-my-zsh` にインストール）
- **エディター**：Emacs（`emacs-pgtk-nativecomp`、native-comp 対応）、vim
- **その他のツール**：git、curl、tmux、fzf、ripgrep、rsync、diffutils
- **クリップボード**：OSC 52 でコピー内容をローカルのクリップボードに同期。X11 は不要
- **複数ユーザー**：`add-user.sh` で zsh を使うユーザーをワンステップで作成

## イメージのタグ

タグの形式は `<alpine のバージョン>-<アーキテクチャ>-<日付>` です。例：

| タグ | アーキテクチャ |
|---|---|
| `lenic/node_lts_sshd:edge-aarch64-20261030` | Apple Silicon、ARM サーバー |
| `lenic/node_lts_sshd:edge-x86_64-20261030` | Intel / AMD |

## クイックスタート

以下の例では Apple の [`container`](https://github.com/apple/container) コマンドを使います。Docker、OrbStack、Colima を使う場合は `container` を `docker` に置き換えてください（ボリューム関連のコマンドは書き方が少し異なります）。

```sh
# 永続化用のボリュームを作成（最初の 1 回のみ）
container volume create home

# コンテナを起動し、コンテナの 22 番ポートをローカルの 2222 番に割り当てる
container run -d --name dev -p 2222:22 \
  -v home:/home \
  lenic/node_lts_sshd:edge-aarch64-20261030

# root でログイン（初期パスワード：admin）
ssh root@localhost -p 2222
```

> [!WARNING]
> root の初期パスワード `admin` は Dockerfile に書かれています。ログイン後すぐに `passwd` で変更するか、SSH 鍵認証に切り替えてください。特にポートを LAN やインターネットに公開する場合は必須です。

## ユーザーの作成

```sh
/root/add-user.sh [-u uid] <ユーザー名> [フルネーム]

# 例
/root/add-user.sh -u 1000 lenic "Lenic Rayleigh"
```

新しいユーザーは：

- ログインシェルとして zsh を使います
- `/etc/skel` から `.zshrc`（共有の oh-my-zsh を参照）、`.tmux.conf`、`workspace` ディレクトリを受け取ります

`-u` で UID を固定できます。`/home` の永続化ボリュームと組み合わせる場合は、全ユーザーの UID を固定することをおすすめします。詳しくは [FAQ](#ユーザーの-ssh-とコードを残すには) を参照してください。

## イメージのビルド

### ローカルでのビルド

```sh
./build.sh                          # aarch64 をビルド、タグは edge-aarch64-<当日の日付>
ARCH=x86_64 ./build.sh              # x86_64 をビルド
IMAGE=myname/dev ./build.sh         # イメージ名を指定
./build.sh --no-cache               # その他の引数は build コマンドにそのまま渡される
BUILDER=docker ./build.sh           # ビルドツールを指定
```

`build.sh` は Apple `container` を優先し、なければ `docker` を使います。`container` を使う場合は、バックグラウンドサービスを自動で起動します。

### GitHub Actions

`.github/workflows/docker.yml` は x86_64 と aarch64 のネイティブ runner でそれぞれビルドし、Docker Hub にプッシュします。1 回の実行で生成されるのは日付付きのタグ 2 つだけです。

- 現在は手動実行のみです：リポジトリの Actions ページで **Run workflow** をクリックするか、`gh workflow run docker.yml` を実行します
- リポジトリの **Settings → Secrets and variables → Actions** で以下を設定してください：
  - `DOCKERHUB_USERNAME`：Docker Hub のユーザー名
  - `DOCKERHUB_TOKEN`：Docker Hub の Personal access token（Read & Write 権限）
- master へのプッシュ時の自動ビルドや毎週の定期ビルドが必要な場合は、workflow 内の `push` / `schedule` 部分のコメントを外してください

## 使い方

### pnpm

pnpm は corepack で管理されています。プロジェクトの `package.json` でバージョンを宣言すると、そのプロジェクト内で `pnpm` を実行したときに自動でそのバージョンが使われます：

```json
"packageManager": "pnpm@10.x.x"
```

`corepack use pnpm@latest` を実行すると、このフィールドを追加・更新できます。プロジェクト外では、イメージのビルド時にインストールされた最新版が使われます。

### ショートカット

| エイリアス | コマンド |
|---|---|
| `e` | `emacs -nw` |
| `eds [名前]` | `emacs --daemon[=名前]`、Emacs デーモンを起動（名前は省略可） |
| `ec [名前]` | `emacsclient -t [-s 名前]`、ターミナルでデーモンに接続 |
| `tn <名前>` | `tmux new -s <名前>`、セッションを作成 |
| `tt <名前>` | `tmux a -t <名前>`、セッションに接続 |
| `tl` | `tmux ls`、セッションを一覧表示 |

### クリップボード（OSC 52）

以下を設定すると、コンテナ内でコピーした内容がそのままローカルのクリップボードに入ります：

1. **tmux**：イメージの `.tmux.conf` で `set -g set-clipboard on` を設定済みです
2. **Emacs**：`init.el` に以下を追加します
   ```elisp
   (setq xterm-extra-capabilities '(setSelection modifyOtherKeys))       ; ターミナルで直接実行する場合
   (setq xterm-tmux-extra-capabilities '(setSelection modifyOtherKeys))  ; tmux 内で実行する場合
   ```
3. **ローカルのターミナル**：iTerm2 では Settings → General → Selection で *Applications in terminal may access clipboard* を有効にします。Ghostty、WezTerm、kitty はデフォルトで対応しています

貼り付けには、ローカルのターミナルの貼り付けショートカット（⌘V など）を使ってください。

## FAQ

### Docker Hub はまだサーバー側で自動ビルドできますか？

Docker Hub の自動ビルド（Autobuilds）は、2021 年以降は有料プランでのみ利用できます。代替手段：

- ローカルでビルドしてプッシュする（[ローカルでのビルド](#ローカルでのビルド) を参照）
- GitHub Actions でビルドしてプッシュする。公開リポジトリは無料で、ネイティブの arm64 runner も使えます（[GitHub Actions](#github-actions) を参照）

### macOS でコンテナのビルドと実行に使うツールは？

| ツール | 説明 |
|---|---|
| Apple `container` | Apple 公式のオープンソースツールで無料。コンテナごとに独立した軽量 VM で動作。Apple Silicon と macOS 26 以降が必要。`brew install container` でインストール |
| OrbStack | 起動が速くリソース消費が少ない。`docker` コマンドと完全互換。個人利用は無料、商用利用は有料 |
| Colima | 無料のオープンソースで、コマンドラインのみ。`brew install colima docker docker-buildx` でインストール |

このイメージをビルドしてローカルで動かすだけなら Apple `container` で十分です。Docker Compose や Docker API に依存するツールが必要な場合は、OrbStack か Colima を選んでください。

### Apple `container` と `docker` コマンドの違いは？

`container` のサブコマンドは `docker` とおおむね対応していますが、完全な互換ではありません：

```sh
container system start                 # バックグラウンドサービスを起動（初回はカーネルをダウンロード）
container build -t <イメージ> .         # ビルド
container run -d --name dev -p 2222:22 <イメージ>
container ls -a                        # コンテナを一覧表示
container image ls -v                  # イメージを一覧表示（サイズ付き）
container registry login docker.io     # Docker Hub にログイン
container image push <イメージ>         # プッシュ
```

Docker Compose には対応しておらず、Docker API に依存するツール（IDE プラグイン、Testcontainers など）も直接は接続できません。

### なぜ npm で corepack をインストールするのですか？

Alpine の `nodejs` パッケージは `--without-corepack` でビルドされており、リポジトリにも単独の `corepack` パッケージがないため、`npm i -g corepack` が必要です。また、Node.js は 25 以降 corepack を同梱しなくなったため、この方法なら今後も互換性を保てます。

### なぜ Emacs に `emacs-pgtk-nativecomp` を使うのですか？

現在の Alpine の `emacs` パッケージには共通ファイルしか含まれておらず、**`emacs` の実行ファイルがありません**。具体的なバリアントを選ぶ必要があります：

| パッケージ | インストールサイズ | 説明 |
|---|---|---|
| `emacs-nox` | 約 105MB | ターミナル専用、native-comp 非対応 |
| `emacs-pgtk-nativecomp` | 約 297MB | GTK 版、native-comp 対応（このイメージで使用） |
| `emacs-gtk3-nativecomp` | 約 298MB | GTK3 + X11、native-comp 対応 |
| `emacs-x11-nativecomp` | 約 350MB | X11、native-comp 対応 |

`emacs-nox` には native-comp 版がありません。GUI 版をターミナルで使うには `-nw` が必要なため、イメージではエイリアス `e` を `emacs -nw` に設定しています。`-nw` を付けずに `emacs` を直接実行すると、ターミナルモードに切り替わらず `cannot open display` エラーになります。`eds` + `ec` によるデーモン方式は影響を受けません。

イメージサイズを重視する場合は、`emacs-nox` に戻すこともできます。

### イメージを残したままコンテナを停止・削除するには？

```sh
container stop dev      # 通常停止（デフォルトでは 5 秒待っても終了しなければ強制終了）
container rm dev        # 停止済みのコンテナを削除
container rm -f dev     # 実行中のコンテナをそのまま削除
```

これらのコマンドはコンテナにのみ作用し、イメージは削除されません。

### イメージを削除するには？

```sh
container image rm lenic/node_lts_sshd:edge-aarch64-20261030
container image prune       # タグのない dangling イメージを削除
container image prune -a    # どのコンテナにも使われていないイメージをすべて削除
```

実行中のコンテナが使っているイメージを削除するには、先にそのコンテナを削除してください。

### イメージのサイズを確認するには？

```sh
container image ls -v      # FULL SIZE 列
container image inspect <イメージ> | jq '.[0].variants[] | {arch: .platform.architecture, size}'
```

表示されるのは圧縮後のサイズ（転送量）です。展開後の実際の使用量はもっと大きく、たとえば 271.5 MB のイメージは展開後に約 774 MB になります。主に Emacs の native-comp 版とその依存関係（gcc、GTK など）によるものです。

### GitHub Actions はどのタグを生成しますか？

1 回の実行で生成されるのは、日付付きの `edge-x86_64-<日付>` と `edge-aarch64-<日付>` の 2 つだけです。マルチアーキテクチャのタグや日付なしのタグは生成されません。日付は日本時間で計算され、両アーキテクチャで共通です。

### コンテナを削除してもコードが消えないようにするには？

名前付きボリュームまたはバインドマウントを使います：

| | 名前付きボリューム（推奨） | ローカルディレクトリのバインドマウント |
|---|---|---|
| データの保存場所 | `container` が管理する ext4 ディスクイメージ | ローカルのフォルダー |
| 読み書きの性能 | 良い | 遅め。`pnpm install` など小さなファイルを大量に扱う操作で特に顕著 |
| ホストから直接アクセス | できない | できる |

```sh
container volume create home
container run ... -v home:/home ...         # 名前付きボリューム
container run ... -v ~/code:/data ...       # バインドマウント
```

注意点：

- 名前付きボリュームには ext4 の `lost+found` ディレクトリがありますが、正常です
- 新しいボリュームのルートディレクトリは root の所有なので、一般ユーザーが書き込むには先に root で `chown` する必要があります
- デフォルトの最大容量は 512 GiB で、実際に書き込んだ分だけディスクを使います
- `container volume prune` はコンテナから参照されていないボリュームをすべて即座に削除し、データは復元できません

### ユーザーの `.ssh` とコードを残すには？

`/home` 全体を 1 つのボリュームとしてマウントすることをおすすめします。`.ssh`、`workspace`、`.zshrc` などがまとめて保持されます：

```sh
container run ... -v home:/home ...
/root/add-user.sh -u 1000 lenic "Lenic Rayleigh"
```

**`/home/<ユーザー名>` 配下のディレクトリ（`~/.ssh` や `~/workspace` など）に直接ボリュームをマウントしないでください。** マウント時に `/home/<ユーザー名>` が先に作成され、BusyBox の `adduser` はホームディレクトリが既に存在すると `/etc/skel` のコピーをスキップするため、`.zshrc` などの設定がなくなります。さらにマウントしたディレクトリは root の所有になるため、ユーザーは書き込めず、`~/.ssh` の所有者が正しくないため sshd も鍵認証を拒否します。

`/home` ボリュームを使う場合：

- `/etc/passwd` はボリュームに含まれないため、新しいコンテナでは `add-user.sh` を再実行する必要があります。ホームディレクトリのデータには影響しません
- `-u` で UID を固定し、ボリューム上のファイルの所有者と一致させてください
- root の `.ssh` は `-v rootssh:/root/.ssh` で個別にマウントできます。初回マウント後に `chmod 700 /root/.ssh` を実行してください

### イメージを再ビルドしたら SSH で `REMOTE HOST IDENTIFICATION HAS CHANGED` と表示される

SSH のホスト鍵はイメージのビルド時に生成されるため、再ビルドすると変わります。ローカルの古い記録を削除してください：

```sh
ssh-keygen -R "[localhost]:2222"
```

## ライセンス

[MIT](./LICENSE)

---

このドキュメントは [Claude](https://claude.ai) を使用して生成されました。
