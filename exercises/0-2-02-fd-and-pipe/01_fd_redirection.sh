#!/usr/bin/env bash

echo '--- 自身のプロセスFDが全て端末画面（/dev/pts/...）に向いていることを確認 ---'
ls -l /proc/$$/fd
echo

echo '--- リダイレクトによるFD差し替えの観察 ---'
# 標準出力を一時ファイルにリダイレクトした sleep をバックグラウンドで起動
sleep 5 > /tmp/stdout_test.txt &
sleep 0.1  # プロセスがリダイレクトを完了するのを一瞬待つ
# 直前のバックグラウンドで実行されたプロセスID（$!）を取得
BG_PID=$!
# 1のFDが一時ファイルに差し替わっていることを確認する
ls -l /proc/$BG_PID/fd

# クリーンアップ
kill $BG_PID
rm -f /tmp/stdout_test.txt
echo

echo '--- パイプによるFD直結（pipe:[id]）の観察 ---'
sleep 2 | sleep 2 &
sleep 0.1  # プロセスが立ち上がるのを一瞬待つ

for pid in $(pgrep -f "sleep 2"); do
    echo "PID $pid のFD:"
    ls -l /proc/$pid/fd
done
pkill -f "sleep 2"  # クリーンアップ
echo