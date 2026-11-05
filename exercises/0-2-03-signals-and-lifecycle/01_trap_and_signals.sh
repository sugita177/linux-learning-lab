#!/usr/bin/env bash

echo "--- SIGTERM（15）による Graceful Shutdown ---"
# サブシェル ( ... ) & を使って、シグナルを待ち受ける子プロセスをバックグラウンドで起動
(
    trap 'echo "  [子プロセス] SIGTERMを受信！クリーンアップして正常終了します"; exit 0' TERM
    while true; do sleep 0.1; done
) &
CHILD_PID=$!
sleep 0.1  # 起動を少し待つ

# 子プロセスにSIGTERMを送信
kill -15 "$CHILD_PID"
# 子プロセスの終了を待つ
wait "$CHILD_PID"
# 終了ステータスの確認
echo $?

echo

echo "--- SIGKILL（9）による強制終了と Exit Code 137 ---"

(
    trap 'echo "  このメッセージは表示されません"' KILL
    while true; do sleep 0.1; done
) &
CHILD_PID=$!
sleep 0.1
# 子プロセスにSIGKILLを送信
kill -9 "$CHILD_PID"
# 子プロセスの終了を待つ
# bashによるプロセス削除のレポートを表示しないようにする
wait "$CHILD_PID" 2>/dev/null
# 終了ステータスの確認
echo $?