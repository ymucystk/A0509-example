#!/bin/bash

# 引数チェック（JSONファイルを指定）
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <json_file>"
    exit 1
fi

JSON_FILE=$1

# jq を使って全 filename の値を取得し、ループで回す
# -r オプションでクォートを除去
jq -r '.. | .filename? // empty' "$JSON_FILE" | while read -r path; do
    
    # "package://" で始まるかチェック
    if [[ "$path" =~ ^package:// ]]; then
        # package:// 以降の文字列を取得 (例: sciurus17_description/meshes/...)
        stripped_path=${path#package://}
        
        # 最初のスラッシュの位置を探してパッケージ名と相対パスに分割
        pkg_name=${stripped_path%%/*}
        relative_path=${stripped_path#*/}
        
        # ros2 pkg prefix でパスを取得
        pkg_prefix=$(ros2 pkg prefix --share "$pkg_name" 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            # 正常にパスが取得できたら結合して出力
            echo "${pkg_prefix}/${relative_path}"
        else
            echo "Error: Package [$pkg_name] not found." >&2
        fi
    else
        # package:// 形式でない場合はそのまま出力（または無視）
        echo "$path"
    fi
done
