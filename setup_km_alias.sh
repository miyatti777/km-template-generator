#!/bin/bash

# KMファイル作成コマンドのエイリアス設定スクリプト

SCRIPT_PATH="/Users/daisukemiyata/test_km_gen2/km-template-generator/create_km.sh"

echo "🔧 KMファイル作成コマンドのエイリアスを設定します..."

# .zshrcにエイリアスを追加
if [ -f ~/.zshrc ]; then
    if ! grep -q "alias create-km" ~/.zshrc; then
        echo "" >> ~/.zshrc
        echo "# KMファイル作成コマンド" >> ~/.zshrc
        echo "alias create-km='$SCRIPT_PATH'" >> ~/.zshrc
        echo "✅ ~/.zshrcにエイリアスを追加しました"
    else
        echo "⚠️  エイリアスは既に設定されています"
    fi
fi

# .bashrcにエイリアスを追加
if [ -f ~/.bashrc ]; then
    if ! grep -q "alias create-km" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# KMファイル作成コマンド" >> ~/.bashrc
        echo "alias create-km='$SCRIPT_PATH'" >> ~/.bashrc
        echo "✅ ~/.bashrcにエイリアスを追加しました"
    else
        echo "⚠️  エイリアスは既に設定されています"
    fi
fi

echo ""
echo "🎉 設定完了！"
echo ""
echo "使用方法:"
echo "1. ターミナルを再起動するか、以下を実行:"
echo "   source ~/.zshrc"
echo ""
echo "2. 以下のコマンドでKMファイルを作成:"
echo "   create-km"
echo "   create-km \"カスタムタイトル\""
echo ""
echo "3. Cursor内蔵ターミナルからも実行可能:"
echo "   Ctrl+\` でターミナルを開いて create-km を実行"
