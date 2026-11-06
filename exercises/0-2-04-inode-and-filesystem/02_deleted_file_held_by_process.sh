#!/usr/bin/env bash

# ==============================================================================
# 実演：削除済みファイルをプロセスが掴んでいる現象と、/proc からのデータ救出
# ==============================================================================

echo "=== 1. 重要ファイルの作成とプロセスによるオープン ==="
echo "超重要データ: 売上1億円のトランザクションログ" > /tmp/important.log
ls -l /tmp/important.log

# tail -f をバックグラウンドで起動し、ファイルをオープン（FDを掴んだ）状態にする
tail -f /tmp/important.log > /dev/null &
APP_PID=$!
sleep 0.2
echo "  -> プロセス (PID: $APP_PID) がファイルをオープンして待機中"
echo

echo "=== 2. ファイルの誤削除（ディレクトリエントリからの unlink） ==="
rm /tmp/important.log
echo "  rm コマンドを実行しました。ディレクトリの存在を確認します:"
ls -l /tmp/important.log 2>&1
echo "  -> ディレクトリからは完全に消滅（No such file or directory）"
echo

echo "=== 3. /proc/<PID>/fd の観察: カーネル内の (deleted) 状態 ==="
echo "  プロセス (PID: $APP_PID) が開いているFD一覧:"
ls -l /proc/"$APP_PID"/fd
echo "  -> FD 3 が '/tmp/important.log (deleted)' を指している！"
echo "  -> 名札は消えたが、プロセスがFDを掴んでいるためカーネルは実体を破棄していない"
echo

echo "=== 4. 実務の調査コマンド: lsof +L1 による犯人プロセスの特定 ==="
# +L1: リンク数（Links）が 1 未満（=0）なのに開かれ続けているファイルを検出
lsof +L1
echo "  -> ディスク容量を掴んで離さないプロセスを特定！"
echo

echo "=== 5. データの救出: プロセスのFDから直接データを吸い出して復元 ==="
cat /proc/"$APP_PID"/fd/3 > /tmp/restored.log
ls -l /tmp/restored.log
echo "  [復元されたデータの中身]:"
cat /tmp/restored.log
echo

echo "=== 6. クリーンアップ: プロセス終了による真の領域解放 ==="
# プロセスを終了させると、FD参照カウントが 0 になり、カーネルが実体データを完全消滅させる
kill "$APP_PID"
wait "$APP_PID" 2>/dev/null
rm -f /tmp/restored.log
echo "  プロセスを kill しました。これでディスク容量が真に解放されました。"