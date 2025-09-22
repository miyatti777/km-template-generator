#!/usr/bin/env python3
"""
KM Template Generator
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
        result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
        if 'Cursor' in result.stdout:
            return 'cursor'
        elif 'Code' in result.stdout and 'Visual Studio Code' in result.stdout:
            return 'vscode'
    except:
        pass
    
    return 'unknown'


def check_command_available(command):
    """コマンドが利用可能かチェック"""
    return shutil.which(command) is not None


def open_with_appropriate_editor(file_path):
    """環境に応じて適切なエディタでファイルを開く"""
    environment = detect_environment()
    
    # 環境に応じた優先順位でエディタを試行
    if environment == 'cursor':
        editors = ['cursor', 'code']
        print("🎯 Cursor環境を検出しました")
    elif environment == 'vscode':
        editors = ['code', 'cursor']
        print("🎯 VS Code環境を検出しました")
    else:
        editors = ['cursor', 'code']
        print("🔍 環境を自動検出中...")
    
    # 各エディタを順番に試行
    for editor in editors:
        if check_command_available(editor):
            try:
                subprocess.run([editor, file_path], check=False)
                print(f"📝 {editor}でファイルを開きました")
                return True
            except Exception as e:
                print(f"⚠️  {editor}での起動に失敗: {e}")
                continue
    
    # すべて失敗した場合はデフォルトアプリで開く
    try:
        if sys.platform == 'darwin':  # macOS
            subprocess.run(['open', file_path], check=False)
            print("📝 デフォルトアプリでファイルを開きました")
            return True
        elif sys.platform == 'linux':
            subprocess.run(['xdg-open', file_path], check=False)
            print("📝 デフォルトアプリでファイルを開きました")
            return True
        elif sys.platform == 'win32':
            os.startfile(file_path)
            print("📝 デフォルトアプリでファイルを開きました")
            return True
    except Exception as e:
        print(f"⚠️  デフォルトアプリでの起動に失敗: {e}")
    
    return False


def create_km_template(title="新しい依頼", output_path=None):
    """
    KMファイルの雛形を作成
    
    Args:
        title (str): ルートノードのタイトル
        output_path (str): 出力パス（指定しない場合は今日のFlowフォルダ）
    
    Returns:
        str: 作成されたファイルのパス
    """
    
    # 出力パスの決定
    if output_path is None:
        today = datetime.now().strftime("%Y-%m-%d")
        year_month = datetime.now().strftime("%Y%m")
        flow_dir = Path(f"{{FLOW_BASE_PATH}}/Flow/{year_month}/{today}")
        flow_dir.mkdir(parents=True, exist_ok=True)
        
        # ファイル名の生成（重複回避）
        base_name = "task"
        counter = 1
        while (flow_dir / f"{base_name}{counter}.km").exists():
            counter += 1
        
        output_path = flow_dir / f"{base_name}{counter}.km"
    else:
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # KMファイルの雛形構造
    km_template = {
        "root": {
            "data": {
                "id": generate_unique_id(),
                "created": int(time.time() * 1000),
                "text": f"依頼：{title}"
            },
            "children": [
                {
                    "data": {
                        "id": generate_unique_id(),
                        "created": int(time.time() * 1000),
                        "text": "コンテキスト："
                    },
                    "children": []
                },
                {
                    "data": {
                        "id": generate_unique_id(),
                        "created": int(time.time() * 1000),
                        "text": "詳細指示"
                    },
                    "children": [
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
                },
                {
                    "data": {
                        "id": generate_unique_id(),
                        "created": int(time.time() * 1000),
                        "text": "出力形式"
                    },
                    "children": [
                        {
                            "data": {
                                "id": generate_unique_id(),
                                "created": int(time.time() * 1000),
                                "text": "期待する出力の形式を記載"
                            },
                            "children": []
                        }
                    ]
                },
                {
                    "data": {
                        "id": generate_unique_id(),
                        "created": int(time.time() * 1000),
                        "text": "補足"
                    },
                    "children": [
                        {
                            "data": {
                                "id": generate_unique_id(),
                                "created": int(time.time() * 1000),
                                "text": "追加の情報や制約条件"
                            },
                            "children": []
                        }
                    ]
                }
            ]
        },
        "template": "filetree",
        "theme": "fresh-blue",
        "version": "1.4.43"
    }
    
    # ファイルに書き込み
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(km_template, f, ensure_ascii=False, indent=4)
    
    return str(output_path)


def main():
    """メイン関数"""
    if len(sys.argv) > 1:
        title = " ".join(sys.argv[1:])
    else:
        title = "新しい依頼"
    
    try:
        file_path = create_km_template(title)
        print(f"✅ KMファイルを作成しました: {file_path}")
        
        # 環境に応じて適切なエディタで開く
        opened = open_with_appropriate_editor(file_path)
        if not opened:
            print("💡 ファイルを手動で開いてください")
        
    except Exception as e:
        print(f"❌ エラーが発生しました: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
