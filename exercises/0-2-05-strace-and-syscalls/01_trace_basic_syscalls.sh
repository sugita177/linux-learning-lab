#!/usr/bin/env bash

# ==============================================================================
# strace によるシステムコールの観察（ユーザー空間からカーネルへの依頼）
# ==============================================================================

# テスト用ファイルの作成
echo "hello syscall" > /tmp/test.txt

echo "=== 1. 正常系：ファイル読み込みと標準出力への書き込み ==="
# openat (ファイルオープン) -> read (FD 3から読み込み) -> write (FD 1へ書き込み) -> close (FD 3を閉じる)
strace -e trace=openat,read,write,close cat /tmp/test.txt
echo

echo "=== 2. 異常系：ファイル未存在エラーと標準エラー出力（FD 2）への書き込み ==="
# openat が -1 ENOENT を返し、エラーメッセージを write(2, ...) に書き込んでいる様子を観察
strace -e trace=openat,read,write,close cat /tmp/missing_config.conf
echo

echo "=== 3. 実務テクニック：失敗したファイルオープン（ENOENT）のみを抽出 ==="
# 設定ファイル探索の失敗を一発で突き止める定番技
strace -e trace=openat cat /tmp/missing_config.conf 2>&1 | grep ENOENT
echo

echo "=== 4. プロセスの変身：execve システムコールの観察 ==="
# Phase 0-2-01 で学んだ exec の正体（プログラムをメモリにロードして置き換える）
strace -e trace=execve ls /tmp > /dev/null

# クリーンアップ
rm -f /tmp/test.txt