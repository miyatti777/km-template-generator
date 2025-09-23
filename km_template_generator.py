#!/usr/bin/env python3
"""
KM Template Generator - 改善版
KMファイル（Mindmap形式のJSON）の雛形を作成するツール
"""

import json
import os
import sys
import time
import random
import subprocess
import shutil
from datetime import datetime
from pathlib import Path
import re


class KMConfig:
    """設定管理クラス"""
    
    def __init__(self, config_path=None):
        self.config_path = config_path or self._find_config_file()
        self.config = self._load_config()
    
    def _find_config_file(self):
        """設定ファイルを探す"""
        script_dir = Path(__file__).parent
        config_candidates = [
            script_dir / "km_config.json",
            Path.home() / ".km_config.json",
            script_dir / "config.json"
        ]
        
        for config_file in config_candidates:
            if config_file.exists():
                return config_file
        
        # デフォルト設定ファイルを作成
        return self._create_default_config(script_dir / "km_config.json")
    
    def _create_default_config(self, config_path):
        """デフォルト設定ファイルを作成"""
        script_dir = Path(__file__).parent
        default_config = {
            "version": "1.0.0",
            "install_path": str(script_dir),
            "flow_base_path": "/Users/daisukemiyata/aipm_v3/Flow",
            "default_theme": "fresh-blue",
            "auto_open_editor": True,
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
        
        try:
            with open(config_path, 'w', encoding='utf-8') as f:
                json.dump(default_config, f, ensure_ascii=False, indent=4)
            return config_path
        except Exception as e:
            print(f"⚠️  設定ファイルの作成に失敗: {e}")
            return None
    
    def _load_config(self):
        """設定ファイルを読み込む"""
        if not self.config_path or not self.config_path.exists():
            return self._get_fallback_config()
        
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"⚠️  設定ファイルの読み込みに失敗: {e}")
            return self._get_fallback_config()
    
    def _get_fallback_config(self):
        """フォールバック設定"""
        script_dir = Path(__file__).parent
        return {
            "version": "1.0.0",
            "install_path": str(script_dir),
            "flow_base_path": "/Users/daisukemiyata/aipm_v3/Flow",
            "default_theme": "fresh-blue",
            "auto_open_editor": True,
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
    
    def get(self, key, default=None):
        """設定値を取得"""
        keys = key.split('.')
        value = self.config
        
        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default
        
        return value


def generate_unique_id():
    """ユニークなIDを生成"""
    timestamp = int(time.time() * 1000)
    random_part = random.randint(1000, 9999)
    return f"{hex(timestamp)[2:]}{hex(random_part)[2:]}"


def detect_environment():
    """現在の実行環境を検出"""
    # 環境変数をチェック
    if 'CURSOR_SESSION_ID' in os.environ or 'CURSOR_USER_DATA' in os.environ:
        return 'cursor'
    elif 'VSCODE_PID' in os.environ or 'VSCODE_IPC_HOOK' in os.environ:
        return 'vscode'
    elif 'TERM_PROGRAM' in os.environ:
        term_program = os.environ['TERM_PROGRAM'].lower()
        if 'cursor' in term_program:
            return 'cursor'
        elif 'vscode' in term_program:
            return 'vscode'
    
    # プロセス名から推測
    try:
        result = subprocess.run(['ps', 'aux'], capture_output=True, text=True, timeout=5)
        if 'Cursor' in result.stdout:
            return 'cursor'
        elif 'Code' in result.stdout and 'Visual Studio Code' in result.stdout:
            return 'vscode'
    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        pass
    
    return 'unknown'


def check_command_available(command):
    """コマンドが利用可能かチェック"""
    return shutil.which(command) is not None


def open_with_appropriate_editor(file_path, config):
    """環境に応じて適切なエディタでファイルを開く"""
    if not config.get('auto_open_editor', True):
        return False
    
    environment = detect_environment()
    editor_priority = config.get('editor_priority', ['cursor', 'code'])
    
    # 環境に応じた優先順位でエディタを調整
    if environment == 'cursor':
        editors = ['cursor'] + [e for e in editor_priority if e != 'cursor']
        print("🎯 Cursor環境を検出しました")
    elif environment == 'vscode':
        editors = ['code'] + [e for e in editor_priority if e != 'code']
        print("🎯 VS Code環境を検出しました")
    else:
        editors = editor_priority
        print("🔍 環境を自動検出中...")
    
    # 各エディタを順番に試行
    for editor in editors:
        if check_command_available(editor):
            try:
                subprocess.run([editor, str(file_path)], check=False, timeout=10)
                print(f"📝 {editor}でファイルを開きました")
                return True
            except (subprocess.TimeoutExpired, subprocess.SubprocessError) as e:
                print(f"⚠️  {editor}での起動に失敗: {e}")
                continue
    
    # すべて失敗した場合はデフォルトアプリで開く
    try:
        if sys.platform == 'darwin':  # macOS
            subprocess.run(['open', str(file_path)], check=False, timeout=10)
            print("📝 デフォルトアプリでファイルを開きました")
            return True
        elif sys.platform == 'linux':
            subprocess.run(['xdg-open', str(file_path)], check=False, timeout=10)
            print("📝 デフォルトアプリでファイルを開きました")
            return True
        elif sys.platform == 'win32':
            os.startfile(str(file_path))
            print("📝 デフォルトアプリでファイルを開きました")
            return True
    except Exception as e:
        print(f"⚠️  デフォルトアプリでの起動に失敗: {e}")
    
    return False


def create_km_template(title="新しい依頼", output_path=None, config=None):
    """
    KMファイルの雛形を作成
    
    Args:
        title (str): ルートノードのタイトル
        output_path (str): 出力パス（指定しない場合は設定に基づいて決定）
        config (KMConfig): 設定オブジェクト
    
    Returns:
        str: 作成されたファイルのパス
    """
    if config is None:
        config = KMConfig()
    
    # ファイル名安全化関数
    def _sanitize_filename(name):
        # パス区切りや制御文字を安全な文字へ置換
        name = name.strip()
        # 改行やタブを空白へ
        name = re.sub(r"[\r\n\t]+", " ", name)
        # Windows系禁止文字と一般的に問題が出やすい記号をアンダースコアへ
        name = re.sub(r"[\\/:*?\"<>|]", "_", name)
        # 連続する空白は1つに
        name = re.sub(r"\s+", " ", name)
        # 先頭末尾のドットは避ける
        name = name.strip(". ") or "無題"
        return name

    # 出力パスの決定
    if output_path is None:
        today = datetime.now().strftime("%Y-%m-%d")
        year_month = datetime.now().strftime("%Y%m")
        hhmm = datetime.now().strftime("%H%M")
        
        flow_base_path = config.get('flow_base_path')
        if not flow_base_path:
            # フォールバック: スクリプトディレクトリ
            flow_base_path = "/Users/daisukemiyata/aipm_v3/Flow"
        
        # requests サブフォルダへ出力
        flow_dir = Path(flow_base_path) / year_month / today / "requests"
        flow_dir.mkdir(parents=True, exist_ok=True)
        
        # ファイル名の生成: HHMM_{依頼名}.km（重複時は _2, _3 ...）
        safe_title = _sanitize_filename(title)
        base_filename = f"{hhmm}_{safe_title}"
        candidate = flow_dir / f"{base_filename}.km"
        suffix = 2
        while candidate.exists():
            candidate = flow_dir / f"{base_filename}_{suffix}.km"
            suffix += 1
        output_path = candidate
    else:
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # テンプレート構造の取得
    template_structure = config.get('template_structure', {})
    root_prefix = template_structure.get('root_prefix', '依頼：')
    default_children = template_structure.get('default_children', [
        'コンテキスト：',
        '詳細指示',
        '出力形式',
        '補足'
    ])
    
    # KMファイルの雛形構造を動的に生成
    children = []
    
    for i, child_text in enumerate(default_children):
        child_node = {
            "data": {
                "id": generate_unique_id(),
                "created": int(time.time() * 1000),
                "text": child_text
            },
            "children": []
        }
        
        # 詳細指示の場合は子ノードを追加
        if child_text == "詳細指示":
            child_node["children"] = [
                {
                    "data": {
                        "id": generate_unique_id(),
                        "created": int(time.time() * 1000),
                        "text": "具体的な要求1"
                    },
                    "children": []
                },
                {
                    "data": {
                        "id": generate_unique_id(),
                        "created": int(time.time() * 1000),
                        "text": "具体的な要求2"
                    },
                    "children": []
                }
            ]
        # その他のノードにも適切な子ノードを追加
        elif child_text in ["出力形式", "補足"]:
            placeholder_text = {
                "出力形式": "期待する出力の形式を記載",
                "補足": "追加の情報や制約条件"
            }.get(child_text, "詳細を記載してください")
            
            child_node["children"] = [
                {
                    "data": {
                        "id": generate_unique_id(),
                        "created": int(time.time() * 1000),
                        "text": placeholder_text
                    },
                    "children": []
                }
            ]
        
        children.append(child_node)
    
    # KMファイルの雛形構造
    km_template = {
        "root": {
            "data": {
                "id": generate_unique_id(),
                "created": int(time.time() * 1000),
                "text": f"{root_prefix}{title}"
            },
            "children": children
        },
        "template": "filetree",
        "theme": config.get('default_theme', 'fresh-blue'),
        "version": "1.4.43"
    }
    
    # ファイルに書き込み
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(km_template, f, ensure_ascii=False, indent=4)
    except Exception as e:
        raise Exception(f"ファイルの書き込みに失敗しました: {e}")
    
    return str(output_path)


def main():
    """メイン関数"""
    try:
        # 設定読み込み
        config = KMConfig()
        
        # タイトルの取得
        if len(sys.argv) > 1:
            title = " ".join(sys.argv[1:])
        else:
            title = "新しい依頼"
        
        # KMファイル作成
        file_path = create_km_template(title, config=config)
        print(f"✅ KMファイルを作成しました: {file_path}")
        
        # 環境に応じて適切なエディタで開く
        opened = open_with_appropriate_editor(file_path, config)
        if not opened:
            print("💡 ファイルを手動で開いてください")
        
    except KeyboardInterrupt:
        print("\n⚠️  処理が中断されました")
        sys.exit(1)
    except Exception as e:
        print(f"❌ エラーが発生しました: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
