#!/usr/bin/env bash

# 自身のプロセスIDの表示
echo "--- 自身のプロセスID ---"
echo $$
printf "\n"

# 親プロセス（呼び出し元）のプロセスIDの表示
echo "--- 親プロセスのプロセスID ---"
echo $PPID
printf "\n"

# プロセスツリーの表示
echo "--- プロセスツリー ---"
ps -ef --forest
printf "\n"

# プロセスの表示
echo "--- プロセス一覧 ---"
ps aux
printf "\n"