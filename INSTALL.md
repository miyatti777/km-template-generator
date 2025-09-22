# 🚀 KM Template Generator インストールガイド

## 📋 クイックインストール

### 1. 基本インストール（推奨）
```bash
# リポジトリをクローン
git clone https://github.com/miyatti777/km-template-generator.git
cd km-template-generator

# 自動インストール実行
./install.sh
```

### 2. カスタムパスでインストール
```bash
# 特定のディレクトリにインストール
INSTALL_DIR="/path/to/your/tools" ./install.sh

# Flowディレクトリの場所をカスタマイズ
FLOW_BASE_PATH="/path/to/your/projects" ./install.sh

# 両方をカスタマイズ
INSTALL_DIR="/usr/local/bin" FLOW_BASE_PATH="/Users/yourname/Documents" ./install.sh
```

## 🔧 環境変数

| 変数名 | 説明 | デフォルト値 |
|--------|------|-------------|
| `INSTALL_DIR` | スクリプトのインストール先 | 現在のディレクトリ |
| `FLOW_BASE_PATH` | Flowディレクトリのベースパス | インストールディレクトリの親 |

## 📁 ディレクトリ構造例

### デフォルトインストール
```
/Users/yourname/projects/
├── km-template-generator/     # インストール先
│   ├── install.sh
│   ├── km_template_generator.py
│   ├── create_km.sh
│   └── setup_km_alias.sh
└── Flow/                      # KMファイル保存先
    ├── 202509/
    │   └── 2025-09-22/
    │       ├── task1.km
    │       └── task2.km
    └── 202510/
        └── 2025-10-01/
            └── task1.km
```

### カスタムインストール例
```bash
# ツール用ディレクトリにインストール、プロジェクトディレクトリにFlow作成
INSTALL_DIR="/Users/yourname/tools/km-gen" \
FLOW_BASE_PATH="/Users/yourname/projects" \
./install.sh
```

結果：
```
/Users/yourname/
├── tools/
│   └── km-gen/               # スクリプト類
│       ├── km_template_generator.py
│       ├── create_km.sh
│       └── setup_km_alias.sh
└── projects/
    └── Flow/                 # KMファイル保存先
        └── 202509/
            └── 2025-09-22/
                └── task1.km
```

## 🎯 インストール後の確認

### エイリアスが設定されている場合
```bash
# ターミナルを再起動または設定を再読み込み
source ~/.zshrc

# テスト実行
create-km "テスト"
```

### 直接実行の場合
```bash
# インストールディレクトリで実行
/path/to/install/dir/create_km.sh "テスト"
```

## 🔄 アップデート

```bash
# 最新版を取得
git pull origin main

# 再インストール
./install.sh
```

## 🗑️ アンインストール

```bash
# エイリアス削除（手動）
# ~/.zshrc から以下の行を削除:
# alias create-km='/path/to/create_km.sh'

# ファイル削除
rm -rf /path/to/install/dir

# Flowディレクトリは必要に応じて削除
# rm -rf /path/to/Flow
```

## 🐛 トラブルシューティング

### パーミッションエラー
```bash
chmod +x install.sh
chmod +x create_km.sh
chmod +x setup_km_alias.sh
chmod +x km_template_generator.py
```

### パスが正しく設定されない
```bash
# 環境変数を明示的に指定して再実行
INSTALL_DIR="$(pwd)" FLOW_BASE_PATH="$(dirname $(pwd))" ./install.sh
```

### エイリアスが動作しない
```bash
# 設定を再読み込み
source ~/.zshrc

# または手動でエイリアス設定
./setup_km_alias.sh
```
