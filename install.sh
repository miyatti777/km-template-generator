#!/bin/bash

# =============================================================================
# KM Template Generator - 改善版インストールスクリプト
# =============================================================================

set -e  # エラー時に即座に終了

# 色付きメッセージ用の定数
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# =============================================================================
# 環境検出
# =============================================================================

detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos" ;;
        Linux*)     echo "linux" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

get_shell_config_file() {
    local shell_type="$1"
    case "$shell_type" in
        "zsh")  echo "$HOME/.zshrc" ;;
        "bash") echo "$HOME/.bashrc" ;;
        *)      echo "$HOME/.profile" ;;
    esac
}

# =============================================================================
# 依存関係チェック
# =============================================================================

check_dependencies() {
    log_info "依存関係をチェックしています..."
    
    local missing_deps=()
    
    # Python3チェック
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    # Gitチェック（クローン時に必要）
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "以下の依存関係が不足しています: ${missing_deps[*]}"
        log_info "インストール方法:"
        
        local os_type=$(detect_os)
        case "$os_type" in
            "macos")
                log_info "  brew install python3 git"
                ;;
            "linux")
                log_info "  sudo apt-get install python3 git  # Ubuntu/Debian"
                log_info "  sudo yum install python3 git     # CentOS/RHEL"
                ;;
            "windows")
                log_info "  Python: https://www.python.org/downloads/"
                log_info "  Git: https://git-scm.com/download/win"
                ;;
        esac
        
        return 1
    fi
    
    log_success "すべての依存関係が満たされています"
    return 0
}

# =============================================================================
# インストール処理
# =============================================================================

install_km_generator() {
    local install_dir="$1"
    
    log_info "KM Template Generatorをインストールしています..."
    
    # インストールディレクトリの作成
    mkdir -p "$install_dir"
    
    # 現在のスクリプトディレクトリを取得
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # 必要なファイルをコピー（既にクローン済みの場合）
    if [ "$script_dir" != "$install_dir" ]; then
        log_info "ファイルを $install_dir にコピーしています..."
        cp "$script_dir"/*.py "$install_dir/" 2>/dev/null || true
        cp "$script_dir"/*.sh "$install_dir/" 2>/dev/null || true
        cp "$script_dir"/README.md "$install_dir/" 2>/dev/null || true
        cp "$script_dir"/LICENSE "$install_dir/" 2>/dev/null || true
    fi
    
    # 実行権限の設定
    chmod +x "$install_dir"/*.sh "$install_dir"/*.py 2>/dev/null || true
    
    log_success "ファイルのコピーが完了しました"
}

fix_template_variables() {
    local install_dir="$1"
    
    log_info "テンプレート変数を修正しています..."
    
    # km_template_generator.pyの修正
    local python_script="$install_dir/km_template_generator.py"
    if [ -f "$python_script" ]; then
        # FLOW_BASE_PATHの修正
        if grep -q "{{FLOW_BASE_PATH}}" "$python_script"; then
            sed -i.bak "s|{{FLOW_BASE_PATH}}|$install_dir|g" "$python_script"
            rm -f "$python_script.bak"
            log_success "Python スクリプトの変数を修正しました"
        fi
    fi
    
    # エイリアス関連はサポート外（何もしない）
}

setup_alias() { :; }

# =============================================================================
# VS Code Tasks 設定
# =============================================================================

update_vscode_tasks() {
    local install_dir="$1"
    
    log_info "VS Code Tasks を設定します (.vscode/tasks.json)"
    
    # デフォルトのプロジェクトルートを推定（git ルート > 現在の親ディレクトリ > 現在ディレクトリ）
    local default_project_root
    if command -v git >/dev/null 2>&1; then
        default_project_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
    fi
    if [ -z "$default_project_root" ]; then
        default_project_root="$(pwd)"
    fi
    
    echo -n "プロジェクトルート（.vscode を作成する場所）を入力 [Enterで: $default_project_root]: "
    read -r project_root
    if [ -z "$project_root" ]; then
        project_root="$default_project_root"
    fi
    
    local vscode_dir="$project_root/.vscode"
    local tasks_file="$vscode_dir/tasks.json"
    mkdir -p "$vscode_dir"
    
    # 絶対パスの Python スクリプト
    local py_abs="$install_dir/km_template_generator.py"
    
    # 既存をバックアップ
    if [ -f "$tasks_file" ]; then
        cp "$tasks_file" "$tasks_file.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "既存 tasks.json をバックアップしました"
    fi
    
    # Python で安全にマージ
    python3 - "$tasks_file" "$py_abs" << 'PYJSON'
import json, sys, os
tasks_path = sys.argv[1]
py_path = sys.argv[2]

data = {"version": "2.0.0", "tasks": [], "inputs": []}
if os.path.exists(tasks_path):
    try:
        with open(tasks_path, 'r', encoding='utf-8') as f:
            loaded = json.load(f)
            if isinstance(loaded, dict):
                data.update(loaded)
    except Exception:
        pass

data.setdefault("tasks", [])
data.setdefault("inputs", [])

# 既存の同名タスク/入力を削除
data["tasks"] = [t for t in data["tasks"] if t.get("label") != "Create KM Template"]
data["inputs"] = [i for i in data["inputs"] if i.get("id") != "kmTitle"]

task = {
    "label": "Create KM Template",
    "type": "shell",
    "command": "python3",
    "args": [py_path, "${input:kmTitle}"],
    "group": "build",
    "presentation": {"echo": True, "reveal": "always", "focus": False, "panel": "new"},
    "problemMatcher": []
}

inp = {
    "id": "kmTitle",
    "description": "KMファイルのタイトルを入力してください",
    "default": "新しい依頼",
    "type": "promptString"
}

data["tasks"].append(task)
data["inputs"].append(inp)

with open(tasks_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
PYJSON
    
    log_success "VS Code Tasks を更新しました: $tasks_file"
}

# =============================================================================
# 設定ファイル作成
# =============================================================================

create_config_file() {
    local install_dir="$1"
    local project_root="$2"
    local config_file="$install_dir/km_config.json"
    
    log_info "設定ファイルを作成しています..."
    
    cat > "$config_file" << EOF
{
    "version": "1.0.0",
    "install_path": "$install_dir",
    "flow_base_path": "$project_root/Flow",
    "default_theme": "fresh-blue",
    "auto_open_editor": true,
    "editor_priority": ["cursor", "code"],
    "template_structure": {
        "root_prefix": "依頼：",
        "default_children": [
            "コンテキスト：",
            "詳細指示",
            "出力形式",
            "補足"
        ]
    }
}
EOF
    
    log_success "設定ファイルを作成しました: $config_file"
}

# =============================================================================
# テスト実行
# =============================================================================

test_installation() {
    local install_dir="$1"
    
    log_info "インストールをテストしています..."
    
    # Python スクリプトのテスト
    if python3 "$install_dir/km_template_generator.py" "インストールテスト" > /dev/null 2>&1; then
        log_success "Python スクリプトが正常に動作します"
    else
        log_error "Python スクリプトのテストに失敗しました"
        return 1
    fi
    
    # シェルスクリプトのテストは不要（Run Taskのみ）
    
    return 0
}

# =============================================================================
# メイン処理
# =============================================================================

main() {
    echo "🚀 KM Template Generator - 改善版インストーラー"
    echo "=================================================="
    
    # 環境検出
    local os_type=$(detect_os)
    local shell_type=$(detect_shell)
    local config_file=$(get_shell_config_file "$shell_type")
    
    log_info "検出された環境:"
    log_info "  OS: $os_type"
    log_info "  Shell: $shell_type"
    log_info "  設定ファイル: $config_file"
    
    # 依存関係チェック
    if ! check_dependencies; then
        log_error "依存関係の問題により、インストールを中止します"
        exit 1
    fi
    
    # インストールディレクトリの決定
    local default_install_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local install_dir="${1:-$default_install_dir}"
    
    log_info "インストール先: $install_dir"
    
    # インストール実行
    if ! install_km_generator "$install_dir"; then
        log_error "インストールに失敗しました"
        exit 1
    fi
    
    # テンプレート変数の修正
    fix_template_variables "$install_dir"
    
    # エイリアス設定はサポート対象外
    log_info "エイリアス設定はサポート外です（Run Taskのみを公式手段とします）"
    
    # プロジェクトルートの取得（km-template-generatorの親ディレクトリ）
    local project_root
    if command -v git >/dev/null 2>&1; then
        # Gitルートを取得
        local git_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
        if [ -n "$git_root" ] && [ "$(basename "$git_root")" = "km-template-generator" ]; then
            # km-template-generatorリポジトリ内の場合は親ディレクトリを使用
            project_root="$(dirname "$git_root")"
        else
            project_root="$git_root"
        fi
    fi
    if [ -z "$project_root" ]; then
        # Gitが使えない場合は、install_dirの親ディレクトリを使用
        project_root="$(dirname "$install_dir")"
    fi
    
    log_info "プロジェクトルート: $project_root"
    
    # 設定ファイル作成
    create_config_file "$install_dir" "$project_root"
    
    # VS Code Tasks 設定（デフォルト）
    update_vscode_tasks "$install_dir"

    # テスト実行
    if ! test_installation "$install_dir"; then
        log_error "インストールテストに失敗しました"
        exit 1
    fi
    
    # 完了メッセージ
    echo ""
    echo "🎉 インストールが完了しました！"
    echo "================================"
    echo ""
    log_success "使用方法 (VS Code Tasks のみ):"
    echo "  1. VS Code/Cursor を開く"
    echo "  2. Cmd/Ctrl+Shift+P → 'Tasks: Run Task'"
    echo "  3. 'Create KM Template' を選択"
    echo "  4. タイトルを入力して実行"
    echo ""
    echo "  ※ その他の実行方法（エイリアス/直接実行など）は非推奨・サポート対象外です"
    echo ""
    log_info "設定ファイル: $install_dir/km_config.json"
    log_info "ログ: 問題が発生した場合は、上記の設定を確認してください"
    
    # シェル再読み込みの提案
    echo ""
    read -p "今すぐシェル設定を再読み込みしますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        source "$config_file"
        log_success "シェル設定を再読み込みしました"
        
        # 即座にテスト実行
        echo ""
        log_info "create-km コマンドをテストしています..."
        if command -v create-km &> /dev/null; then
            log_success "create-km コマンドが利用可能です！"
        else
            log_warning "create-km コマンドが見つかりません。ターミナルを再起動してください。"
        fi
    fi
}

# スクリプト実行
main "$@"
