# 0-2-06. ソケット（Socket）の正体と名前解決の仕組み

この節では、Linuxにおけるネットワーク通信の接続口である **ソケット（Socket）** もファイル（inode）として管理されている原理、およびWebシステムで不可欠な **Linux名前解決（DNS / hosts / nsswitch.conf）** の仕組みをハンズオンで解明しました。

---

## 1. ネットワークも「ただのFD」である（ソケットの正体）

Linuxでは、ネットワーク通信を行う際も通常のファイルと同様に **ファイルディスクリプタ（FD）** が割り当てられます。

```text
/proc/<PID>/fd/3 -> 'socket:[5577]'
```

### 実験で得られた完全な証拠
待受ポート 8080 で起動したプロセス（`nc`）を観察したところ、3つの情報が完全に一致しました：

1. **プロセスのFD一覧 (`/proc/<PID>/fd`)**:
   - `3 -> 'socket:[5577]'`（FD番号 3 に割り当てられたソケットの **inode番号 5577**）
2. **ポート待受コマンド (`ss -tulpn`)**:
   - `users:(("nc", pid=164, fd=3))`（プロセス名、PID、そして **FD番号 3** まで完全に一致）
3. **カーネルのTCPテーブル (`/proc/net/tcp`)**:
   - `00000000:1F90 ... inode: 5577`
   - `1F90` は16進数で **10進数の 8080**。
   - 右端の inode 列に **`5577`** が記録されており、ソケット番号がカーネルの内部inode番号そのものであることが証明された。

---

## 2. Linux名前解決の3連星（nsswitch.conf / hosts / resolv.conf）

Linuxがドメイン名（例: `my-api.internal`）をIPアドレスに変換する際、以下の3つのファイルが連携して動いています。

```text
[ドメイン問い合わせ]
       |
       v
[1. /etc/nsswitch.conf] --- "hosts: files dns" のルールに従う
       |
       +---> [2. /etc/hosts] (files) を最優先でチェック！
       |        -> 定義があれば即座に解決（外部DNSには聞かない）
       v
[3. /etc/resolv.conf] (dns) に記載されたネームサーバーへ問い合わせ
```

| 設定ファイル | 役割 | 実務での使われ方 |
| :--- | :--- | :--- |
| **`/etc/nsswitch.conf`** | 名前解決の優先順位を決める司令塔 | `hosts: files dns`（ローカル優先） |
| **`/etc/hosts`** | ローカルの名前解決辞書（静的マッピング） | 本番切り替え前の先行検証、ローカル開発環境のドメイン偽装 |
| **`/etc/resolv.conf`** | 参照先DNSサーバーのIPとオプション設定 | 参照先DNSの指定、ドメインサフィックス探索 |

---

## 3. Docker と Kubernetes に直結する重要知見

### ① `nameserver 127.0.0.11`（Docker組み込みDNS）
- Dockerコンテナの `/etc/resolv.conf` に必ず記載されている `127.0.0.11` は、**Dockerエンジンが提供する内部DNSサーバー** です。
- `docker compose` で `curl http://db:5432` のように **「コンテナ名」で通信できるのは、この `127.0.0.11` がコンテナ名と内部IPを自動解決しているから** です。

### ② `options ndots`（Kubernetes著名トラブルの正体）
- Dockerコンテナでは `options ndots:0` となっていますが、**KubernetesのPodではデフォルトで `ndots:5`** に設定されています。
- これにより、外部ドメイン（例: `api.stripe.com`）を引く際に、クラスタ内部ドメインのサフィックスを補完した無駄なDNS問い合わせが最大5回発生し、通信遅延を引き起こす **「ndots:5問題」** の発生源となっています。

---

## 4. Dockerコンテナ特有の落とし穴：`Device or resource busy`

コンテナ内で `/etc/hosts` を直接 `sed -i` しようとすると、以下のエラーが発生します：
```text
sed: cannot rename /etc/sedXXXXXX: Device or resource busy
```

- **原因**: Dockerは `/etc/hosts` をホスト側から「bind mount」して固定しているため、`sed -i` が裏で行う `rename()`（ファイル置き換え）がOSから拒否される。
- **実務の安全な回避パターン**:
  ファイル自体を置き換えるのではなく、**一時ファイルからリダイレクト `>` で既存ファイルの中身だけを上書き流し込み** します：
  ```bash
  sed '/pattern/d' /etc/hosts > /tmp/hosts.tmp && cat /tmp/hosts.tmp > /etc/hosts && rm -f /tmp/hosts.tmp
  ```

