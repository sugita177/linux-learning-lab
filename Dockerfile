FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

#パッケージのインストール
#上の行から、基本ツール、プロセス・リソース調査、OS原理・解析、ネットワーク調査、テキスト・データ処理
# 最後の行のrmは、不要なキャッシュの削除をしてイメージサイズを抑える
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl git vim less \
    procps htop lsof \
    strace \
    iproute2 dnsutils netcat-openbsd \
    jq ripgrep file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["bash"]