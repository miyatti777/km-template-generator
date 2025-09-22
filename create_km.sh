#!/bin/bash

# KMファイル雛形作成スクリプト
# 使用方法: ./create_km.sh [タイトル]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/km_template_generator.py"

# タイトルの取得
if [ $# -eq 0 ]; then
    echo "KMファイルのタイトルを入力してください:"
    read -r TITLE
    if [ -z "$TITLE" ]; then
        TITLE="新しい依頼"
    fi
else
    TITLE="$*"
fi

# Pythonスクリプトの実行
echo "🚀 KMファイルを作成中..."
python3 "$PYTHON_SCRIPT" "$TITLE"

echo ""
echo "✨ 完了！作成されたファイルを確認してください。"