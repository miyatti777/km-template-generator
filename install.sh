#!/bin/bash

# KM Template Generator インストールスクリプト
# 現在の環境に合わせて自動的にパスを設定します

set -e  # エラー時に停止

echo "🚀 KM Template Generator インストールを開始します..."
echo ""

# 現在のスクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 インストール元: $SCRIPT_DIR"

# インストール先の決定（デフォルトは現在のディレクトリ）
if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="$SCRIPT_DIR"
fi
echo "📁 インストール先: $INSTALL_DIR"

# Flow ディレクトリのベースパス決定
if [ -z "$FLOW_BASE_PATH" ]; then
    # デフォルトはインストールディレクトリの親ディレクトリ
    FLOW_BASE_PATH="$(dirname "$INSTALL_DIR")"
fi
echo "📁 Flowディレクトリベース: $FLOW_BASE_PATH"

echo ""
echo "🔧 設定を適用中..."

# Python スクリプトのパス置換
echo "  📝 km_template_generator.py を設定中..."
sed "s|{{FLOW_BASE_PATH}}|$FLOW_BASE_PATH|g" "$SCRIPT_DIR/km_template_generator.py" > "$INSTALL_DIR/km_template_generator.py.tmp"
mv "$INSTALL_DIR/km_template_generator.py.tmp" "$INSTALL_DIR/km_template_generator.py"
chmod +x "$INSTALL_DIR/km_template_generator.py"

# エイリアス設定スクリプトのパス置換
echo "  📝 setup_km_alias.sh を設定中..."
sed "s|{{INSTALL_PATH}}|$INSTALL_DIR|g" "$SCRIPT_DIR/setup_km_alias.sh" > "$INSTALL_DIR/setup_km_alias.sh.tmp"
mv "$INSTALL_DIR/setup_km_alias.sh.tmp" "$INSTALL_DIR/setup_km_alias.sh"
chmod +x "$INSTALL_DIR/setup_km_alias.sh"

# create_km.sh をコピー（パス置換不要）
echo "  📝 create_km.sh をコピー中..."
cp "$SCRIPT_DIR/create_km.sh" "$INSTALL_DIR/create_km.sh"
chmod +x "$INSTALL_DIR/create_km.sh"

echo ""
echo "✅ ファイルのセットアップが完了しました！"
echo ""

# エイリアス設定の確認
echo "🤔 エイリアス設定を行いますか？ (y/n)"
read -r SETUP_ALIAS

if [[ $SETUP_ALIAS =~ ^[Yy]$ ]]; then
    echo ""
    echo "🔧 エイリアスを設定中..."
    "$INSTALL_DIR/setup_km_alias.sh"
    
    echo ""
    echo "🎉 インストール完了！"
    echo ""
    echo "📋 使用方法:"
    echo "1. ターミナルを再起動するか、以下を実行:"
    echo "   source ~/.zshrc"
    echo ""
    echo "2. 以下のコマンドでKMファイルを作成:"
    echo "   create-km"
    echo "   create-km \"カスタムタイトル\""
else
    echo ""
    echo "✅ ファイルのセットアップのみ完了しました！"
    echo ""
    echo "📋 手動でエイリアスを設定する場合:"
    echo "   $INSTALL_DIR/setup_km_alias.sh"
    echo ""
    echo "📋 直接実行する場合:"
    echo "   $INSTALL_DIR/create_km.sh \"タイトル\""
fi

echo ""
echo "📁 設定情報:"
echo "  - インストール先: $INSTALL_DIR"
echo "  - Flowディレクトリ: $FLOW_BASE_PATH/Flow"
echo "  - 作成されるKMファイル: $FLOW_BASE_PATH/Flow/YYYYMM/YYYY-MM-DD/taskN.km"
echo ""
echo "🎯 VS Code Mind Map拡張機能をインストールして、作成されたKMファイルを活用してください！"