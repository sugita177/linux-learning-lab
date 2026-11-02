#!/usr/bin/env bash

echo "--- 変数のスコープ比較 ---"
VAR="original"
echo "VAR is $VAR"

# 1. カレントシェル { ...; }
# - 新しいプロセスを生成せず、現在のプロセス内でそのまま実行される。
# - そのため、変数の変更や新規定義（VAR2）はブロック外（親環境）にもそのまま反映される。
{ VAR="changed_by_current"; echo "VAR is $VAR"; }
{ VAR2="var-2"; echo "VAR2 is $VAR2"; }
echo "VAR is $VAR"
echo "VAR2 is $VAR2"

# 2. サブシェル ( ... )
# - OSレベルでプロセスが複製（fork）され、独立したメモリ空間で実行される。
# - 親の変数はコピーして読み取れるが、サブシェル内での変更は親環境には絶対に反映されない。
(VAR="changed_by_subshell"; echo "VAR is $VAR")
echo "VAR is $VAR"

printf "\n"

echo " --- カレントディレクトリ移動（cd）の副作用比較 ---"
# 実務イディオム：
# ( cd /tmp && ... ) のようにサブシェル内で作業すると、サブシェル終了時に
# 自動的に元のディレクトリに戻るため、元の作業場所を汚さず安全に処理できる。
echo "Outside: $(pwd)"
( cd /tmp && echo "Inside: $(pwd)" )
echo "Outside: $(pwd)"

printf "\n"

echo '--- プロセスIDの正体（$$ vs $BASHPID） ---'
# - $$ は「スクリプト起動時のメインシェルのPID」を保持し続ける。
# - $BASHPID は「現在実行中のプロセス自身の実際のPID」を返す。
# サブシェル内で $BASHPID のみが変化することで、実際に別プロセス（fork）が動いていることが確認できる。
echo "親シェル: PID=$$, BASHPID=$BASHPID"
( echo "サブシェル: PID=$$, BASHPID=$BASHPID" )