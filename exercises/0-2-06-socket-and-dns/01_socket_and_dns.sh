#!/usr/bin/env bash

# ==============================================================================
# ソケット（Socket）のFD観察と、Linux名前解決（DNS / hosts）の仕組み
# ==============================================================================

echo "=== 1. ソケットの作成とFD（ファイルディスクリプタ）の観察 ==="
nc -l -p 8080 &
SERVER_PID=$!
sleep 0.2

echo "  プロセス (PID: $SERVER_PID) のFD一覧:"
ls -l /proc/"${SERVER_PID}"/fd
echo "  -> FD 3 が 'socket:[inode番号]' に接続されている（ソケットもファイルである証拠）"
echo

echo "  待受ポート（8080）とプロセスの紐付きを確認 (ss -tulpn):"
ss -tulpn | grep 8080
echo "  -> users:((\"nc\", pid=$SERVER_PID, fd=3)) とFD番号まで一致！"

echo "  カーネルのTCPテーブル  "
cat /proc/net/tcp
echo

# サーバーをクリーンアップ
kill "$SERVER_PID"
wait "$SERVER_PID" 2>/dev/null
echo

echo "=== 2. Linux名前解決の優先順位 (/etc/nsswitch.conf) ==="
grep "^hosts:" /etc/nsswitch.conf
echo "  -> 'files (hostsファイル)' を 'dns' より優先して検索するルール"
echo

echo "=== 3. 参照先DNSサーバー (/etc/resolv.conf) ==="
cat /etc/resolv.conf
echo "  -> 127.0.0.11 はDocker組み込みDNS（コンテナ名解決の立役者）"
echo

echo "=== 4. /etc/hosts によるローカル名前解決の実演 ==="
# 一時的にダミードメインを書き込む
echo "127.0.0.1 my-api.internal" >> /etc/hosts

echo "  getent による名前解決テスト:"
getent hosts my-api.internal

# クリーンアップ（追加した行を削除）
# 一時ファイルからリダイレクトで中身を上書き流し込み
sed '/my-api\.internal/d' /etc/hosts > /tmp/hosts.tmp && cat /tmp/hosts.tmp > /etc/hosts && rm -f /tmp/hosts.tmp
echo "  -> hostsファイルを元通りにクリーンアップしました"