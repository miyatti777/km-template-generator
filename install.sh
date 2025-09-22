#!/bin/bash

# =============================================================================
# KM Template Generator インストールスクリプト
# =============================================================================
# 
# 使用方法: ./install.sh
# 
# このスクリプトは以下を実行します：
# 1. Pythonスクリプトをユーザー指定の場所に配置
# 2. KMファイル出力先の設定
# 3. .vscode/tasks.jsonの作成・更新
# 4. VS Code Mind Map拡張機能のインストール促進
#
# =============================================================================

set -e  # エラーが発生したら即座に終了

# 色付きメッセージ用の関数
print_header() {
    echo ""
    echo "🚀 =============================================="
    echo "   $1"
    echo "=============================================="
}

print_info() {
    echo "ℹ️  $1"
}

print_success() {
    echo "✅ $1"
}

print_warning() {
    echo "⚠️  $1"
}

print_error() {
    echo "❌ $1"
}

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"

print_header "KM Template Generator インストール開始"

# =============================================================================
# Step 0: Pythonスクリプトの配置場所を決定
# =============================================================================

print_header "Step 0: Pythonスクリプトの配置場所設定"

# デフォルトのツール配置場所
DEFAULT_TOOL_DIR="$HOME/aipm_v3/Stock/programs/Tools/projects/km-template-generator"

echo "Pythonスクリプト（km_template_generator.py）の配置場所を指定してください。"
echo "デフォルト: $DEFAULT_TOOL_DIR"
echo ""
read -p "配置場所を入力（Enterでデフォルト使用）: " TOOL_INSTALL_DIR

if [ -z "$TOOL_INSTALL_DIR" ]; then
    TOOL_INSTALL_DIR="$DEFAULT_TOOL_DIR"
fi

# ディレクトリを作成
mkdir -p "$TOOL_INSTALL_DIR"
print_info "配置場所: $TOOL_INSTALL_DIR"

# Pythonスクリプトをコピー
cp "$SCRIPT_DIR/km_template_generator.py" "$TOOL_INSTALL_DIR/"
cp "$SCRIPT_DIR/create_km.sh" "$TOOL_INSTALL_DIR/"
chmod +x "$TOOL_INSTALL_DIR/create_km.sh"

# create_km.shのパスを更新
sed -i.bak "s|PYTHON_SCRIPT=\"\$SCRIPT_DIR/km_template_generator.py\"|PYTHON_SCRIPT=\"$TOOL_INSTALL_DIR/km_template_generator.py\"|" "$TOOL_INSTALL_DIR/create_km.sh"
rm "$TOOL_INSTALL_DIR/create_km.sh.bak"

print_success "Pythonスクリプトを配置しました"

# =============================================================================
# Step 0.5: KMファイル出力先の設定
# =============================================================================

print_header "Step 0.5: KMファイル出力先設定"

# デフォルトのFlow出力場所
DEFAULT_FLOW_DIR="$HOME/aipm_v3/Flow"

echo "KMファイルの出力先ディレクトリを指定してください。"
echo "（日付フォルダが自動で作成されます。例: Flow/202509/2025-09-22/）"
echo "デフォルト: $DEFAULT_FLOW_DIR"
echo ""
read -p "出力先を入力（Enterでデフォルト使用）: " KM_OUTPUT_DIR

if [ -z "$KM_OUTPUT_DIR" ]; then
    KM_OUTPUT_DIR="$DEFAULT_FLOW_DIR"
fi

print_info "KMファイル出力先: $KM_OUTPUT_DIR"

# Pythonスクリプト内のパスを更新
if [ "$KM_OUTPUT_DIR" != "$DEFAULT_FLOW_DIR" ]; then
    # デフォルトパスを置換
    sed -i.bak "s|/Users/daisukemiyata/aipm_v3/Flow|$KM_OUTPUT_DIR|g" "$TOOL_INSTALL_DIR/km_template_generator.py"
    rm "$TOOL_INSTALL_DIR/km_template_generator.py.bak"
    print_success "出力先パスを更新しました"
fi

# =============================================================================
# Step 1: .vscode/tasks.jsonの作成・更新
# =============================================================================

print_header "Step 1: VS Code Tasks設定"

VSCODE_DIR="$PROJECT_ROOT/.vscode"
TASKS_FILE="$VSCODE_DIR/tasks.json"

# .vscodeディレクトリを作成
mkdir -p "$VSCODE_DIR"

# 新しいタスク定義
NEW_TASK_JSON=$(cat <<EOF
    {
      "label": "Create KM Template",
      "type": "shell",
      "command": "python3",
      "args": [
        "$TOOL_INSTALL_DIR/km_template_generator.py",
        "\${input:kmTitle}"
      ],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "new"
      },
      "problemMatcher": []
    }
EOF
)

NEW_INPUT_JSON=$(cat <<EOF
    {
      "id": "kmTitle",
      "description": "KMファイルのタイトルを入力してください",
      "default": "新しい依頼",
      "type": "promptString"
    }
EOF
)

if [ -f "$TASKS_FILE" ]; then
    print_info "既存のtasks.jsonが見つかりました。安全に更新します..."
    
    # 既存ファイルをバックアップ
    cp "$TASKS_FILE" "$TASKS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    print_info "バックアップを作成しました: $TASKS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Pythonスクリプトで安全に更新
    python3 << EOF
import json
import sys

try:
    # 既存のtasks.jsonを読み込み
    with open('$TASKS_FILE', 'r', encoding='utf-8') as f:
        tasks_data = json.load(f)
    
    # tasksセクションが存在しない場合は作成
    if 'tasks' not in tasks_data:
        tasks_data['tasks'] = []
    
    # inputsセクションが存在しない場合は作成
    if 'inputs' not in tasks_data:
        tasks_data['inputs'] = []
    
    # 既存の"Create KM Template"タスクを削除（重複防止）
    tasks_data['tasks'] = [task for task in tasks_data['tasks'] if task.get('label') != 'Create KM Template']
    
    # 既存の"kmTitle"インプットを削除（重複防止）
    tasks_data['inputs'] = [inp for inp in tasks_data['inputs'] if inp.get('id') != 'kmTitle']
    
    # 新しいタスクを追加
    new_task = $NEW_TASK_JSON
    tasks_data['tasks'].append(new_task)
    
    # 新しいインプットを追加
    new_input = $NEW_INPUT_JSON
    tasks_data['inputs'].append(new_input)
    
    # ファイルに書き戻し
    with open('$TASKS_FILE', 'w', encoding='utf-8') as f:
        json.dump(tasks_data, f, indent=2, ensure_ascii=False)
    
    print("✅ tasks.jsonを更新しました")
    
except Exception as e:
    print(f"❌ エラー: {e}")
    sys.exit(1)
EOF
    
else
    print_info "新しいtasks.jsonを作成します..."
    
    # 新しいtasks.jsonを作成
    cat > "$TASKS_FILE" << EOF
{
  "version": "2.0.0",
  "tasks": [
$NEW_TASK_JSON
  ],
  "inputs": [
$NEW_INPUT_JSON
  ]
}
EOF
    
    print_success "新しいtasks.jsonを作成しました"
fi

print_success "VS Code Tasksの設定が完了しました"

# =============================================================================
# Step 2: VS Code Mind Map拡張機能のインストール促進
# =============================================================================

print_header "Step 2: VS Code Mind Map拡張機能"

echo "KMファイルをビジュアルなマインドマップとして表示するために、"
echo "VS Code Mind Map拡張機能のインストールが必要です。"
echo ""
echo "🔗 拡張機能リンク:"
echo "   • Open VSX: https://open-vsx.org/extension/oorzc/mind-map"
echo "   • Cursor Marketplace: http://marketplace.cursorapi.com/items/?itemName=oorzc.mind-map"
echo ""

# 自動インストールを試行（VS Code/Cursor）
if command -v code >/dev/null 2>&1; then
    echo "VS Codeが検出されました。自動インストールを試行します..."
    if code --install-extension oorzc.mind-map >/dev/null 2>&1; then
        print_success "VS Codeに拡張機能をインストールしました"
    else
        print_warning "自動インストールに失敗しました。手動でインストールしてください"
    fi
elif command -v cursor >/dev/null 2>&1; then
    echo "Cursorが検出されました。自動インストールを試行します..."
    if cursor --install-extension oorzc.mind-map >/dev/null 2>&1; then
        print_success "Cursorに拡張機能をインストールしました"
    else
        print_warning "自動インストールに失敗しました。手動でインストールしてください"
    fi
else
    print_warning "VS Code/Cursorが検出されませんでした。手動でインストールしてください"
fi

echo ""
echo "📋 手動インストール手順:"
echo "   1. VS Code/Cursorを開く"
echo "   2. 拡張機能パネル（Ctrl+Shift+X / Cmd+Shift+X）を開く"
echo "   3. 'oorzc.mind-map' を検索"
echo "   4. 'Mind Map' 拡張機能をインストール"

# =============================================================================
# Step 3: エイリアス設定の提案
# =============================================================================

print_header "Step 3: エイリアス設定（オプション）"

echo "より簡単にKMファイルを作成するために、シェルエイリアスを設定できます。"
echo ""
read -p "エイリアス 'create-km' を設定しますか？ (y/N): " SETUP_ALIAS

if [[ "$SETUP_ALIAS" =~ ^[Yy]$ ]]; then
    # エイリアス設定スクリプトを実行
    if [ -f "$SCRIPT_DIR/setup_km_alias.sh" ]; then
        # setup_km_alias.shのパスを更新してから実行
        cp "$SCRIPT_DIR/setup_km_alias.sh" "$TOOL_INSTALL_DIR/"
        sed -i.bak "s|SCRIPT_PATH=\".*\"|SCRIPT_PATH=\"$TOOL_INSTALL_DIR/create_km.sh\"|" "$TOOL_INSTALL_DIR/setup_km_alias.sh"
        rm "$TOOL_INSTALL_DIR/setup_km_alias.sh.bak"
        
        bash "$TOOL_INSTALL_DIR/setup_km_alias.sh"
        print_success "エイリアスを設定しました"
    else
        print_warning "setup_km_alias.shが見つかりません"
    fi
else
    print_info "エイリアス設定をスキップしました"
fi

# =============================================================================
# インストール完了
# =============================================================================

print_header "🎉 インストール完了！"

echo ""
echo "📁 インストール場所:"
echo "   • Pythonスクリプト: $TOOL_INSTALL_DIR"
echo "   • VS Code Tasks: $TASKS_FILE"
echo "   • KMファイル出力先: $KM_OUTPUT_DIR"
echo ""
echo "🚀 使用方法:"
echo ""
echo "【方法1】VS Code Tasks（推奨）"
echo "   1. VS Code/Cursorでプロジェクトを開く"
echo "   2. Ctrl+Shift+P (Cmd+Shift+P) でコマンドパレットを開く"
echo "   3. 'Tasks: Run Task' を選択"
echo "   4. 'Create KM Template' を選択"
echo "   5. タイトルを入力"
echo ""
echo "【方法2】コマンドライン"
echo "   cd $TOOL_INSTALL_DIR"
echo "   ./create_km.sh \"あなたの依頼タイトル\""
echo ""

if [[ "$SETUP_ALIAS" =~ ^[Yy]$ ]]; then
echo "【方法3】エイリアス（新しいターミナルで）"
echo "   create-km \"あなたの依頼タイトル\""
echo ""
fi

echo "📖 詳細な使用方法:"
echo "   README.md をご覧ください"
echo ""
echo "🎯 次のステップ:"
echo "   1. VS Code Mind Map拡張機能がインストールされていることを確認"
echo "   2. KMファイルを作成してテスト"
echo "   3. マインドマップでビジュアル編集"
echo "   4. Export Nodeで構造化テキストを取得"
echo "   5. LLMチャットで活用"
echo ""

print_success "セットアップが完了しました！"
