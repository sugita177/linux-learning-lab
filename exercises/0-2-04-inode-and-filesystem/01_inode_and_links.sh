#!/usr/bin/env bash

# 1. 前回のゴミを掃除してテスト環境を用意
rm -rf /tmp/inode_test
mkdir -p /tmp/inode_test && cd /tmp/inode_test
echo "hello linux" > original.txt

echo "=== 1. 初期のinode番号 ==="
ls -i original.txt

# 2. ハードリンクとシンボリックリンクを作成
ln original.txt hardlink.txt
ln -s original.txt symlink.txt

echo
echo "=== 2. リンク作成後の比較（inode番号とリンク数） ==="
ls -li

# 3. 元ファイル（名札）を1つ剥がす（unlink）
rm original.txt

echo
echo "=== 3. original.txt 削除後の状態 ==="
ls -li
echo -n "hardlink の中身: " && cat hardlink.txt
echo -n "symlink の中身: "  && cat symlink.txt 2>&1

# 4. クリーンアップ
cd /tmp && rm -rf /tmp/inode_test