#!/usr/bin/env bash

echo "--- 1. Zombie process (ゾンビプロセス) ---"
# 親プロセスをバックグラウンドで起動
(
    # 子を起動して即座に終了させる
    sh -c "exit 0" &
    Z_PID=$!
    # 変身する前に、子プロセスのPIDと親のPIDを表示！
    echo "  [生成時] 親PID: $BASHPID が 子PID: $Z_PID を生成しました（直後に子は終了）"
    # 親は exec で sleep コマンドそのものに変身して待機する（自動の感知を完全無効化！）
    exec sleep 3
) &
PARENT_PID=$!
sleep 0.3  # 子が終了して親が sleep に変身するのを一瞬待つ

echo "  [外側から観察] プロセスツリーと状態を確認:"
# 親(sleep 3)とその下にぶら下がるゾンビをツリー表示
ps -ef --forest | grep -B 1 -A 2 "sleep 3"

# 観察が終わったので親をクリーンアップ（親が終了するとゾンビも消滅します）
kill "$PARENT_PID" 2>/dev/null
wait "$PARENT_PID" 2>/dev/null
echo

echo '--- 2. Orphan process (孤児プロセス) ---'
(
    # 子プロセスを起動（3秒待つ）
    sleep 3 &
    CHILD_PID=$!
    echo "  [孤児化前] 子プロセスのPID: $CHILD_PID, 親のPID: $BASHPID"
    # 親（このサブシェル）は子より先に終了する！
    exit 0
)
sleep 0.1  # 親が終了するのを一瞬待つ

ORPHAN_PID=$(pgrep -f "sleep 3")
echo "  [孤児化後] 子プロセスのPID: $ORPHAN_PID"
ps -o pid,ppid,stat,cmd -p "$ORPHAN_PID"

# 子プロセスのクリーンアップ
pkill -f "sleep 3"