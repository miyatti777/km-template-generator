# VS CodeでLLMへの構造化リクエストを効率化する「KMテンプレートジェネレーター」の手動セットアップガイド

## はじめに

LLMへのリクエストを構造化して伝えることで、より精度の高い回答を得られることをご存知でしょうか？しかし、XMLのような構造を手書きするのは面倒ですよね。

今回は、マインドマップ形式でビジュアルに思考を整理し、構造化されたリクエストをLLMに送るワークフローを実現する「KMテンプレートジェネレーター」の手動セットアップ方法をご紹介します。

## 🎯 このツールで実現できること

1. **ワンクリックでテンプレート生成**: VS CodeのタスクランナーからKMファイル（マインドマップJSON）を瞬時に作成
2. **ビジュアルな思考整理**: VS Code Mind Map拡張機能でマインドマップとして編集
3. **構造化テキストの自動生成**: Export Node機能でXMLライクな階層構造を取得
4. **LLMへの効果的なリクエスト**: 整理された構造でコンテキストを正確に伝達

## 📋 前提条件

- VS Code または Cursor がインストールされていること
- Python 3.7以上がインストールされていること
- 基本的なターミナル操作ができること

## 🛠️ 手動セットアップ手順

### Step 1: プロジェクトファイルの準備

まず、必要なファイルを取得します。

```bash
# 1. 作業ディレクトリを作成（お好みの場所で）
mkdir -p ~/tools/km-template-generator
cd ~/tools/km-template-generator

# 2. GitHubからファイルをダウンロード
# 方法A: gitがある場合
git clone https://github.com/miyatti777/km-template-generator.git .

# 方法B: gitがない場合は直接ダウンロード
curl -O https://raw.githubusercontent.com/miyatti777/km-template-generator/main/km_template_generator.py
curl -O https://raw.githubusercontent.com/miyatti777/km-template-generator/main/README.md
curl -O https://raw.githubusercontent.com/miyatti777/km-template-generator/main/LICENSE
```

### Step 2: Pythonスクリプトの設定

次に、KMファイルの出力先を設定します。

```bash
# km_template_generator.py を開いて編集
# DEFAULT_FLOW_BASE_DIR の行を探して、自分のプロジェクトのパスに変更

# 例：VS Codeで開く場合
code km_template_generator.py
```

変更箇所の例：
```python
# 変更前
DEFAULT_FLOW_BASE_DIR = "/Users/daisukemiyata/aipm_v3/Flow"

# 変更後（あなたのプロジェクトパスに合わせて変更）
DEFAULT_FLOW_BASE_DIR = "/Users/あなたのユーザー名/プロジェクト/Flow"
```

💡 **ポイント**: Flowディレクトリは日付ベースでファイルを整理する場所です。プロジェクトごとに適切な場所を指定してください。

### Step 3: VS Code Tasks の設定

VS Codeから簡単に実行できるようにタスクを設定します。

#### 3-1. .vscodeディレクトリを作成

```bash
# プロジェクトのルートディレクトリで実行
mkdir -p .vscode
```

#### 3-2. tasks.json を作成または編集

`.vscode/tasks.json` ファイルを作成し、以下の内容を追加します：

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Create KM Template",
      "type": "shell",
      "command": "python3",
      "args": [
        "/Users/あなたのユーザー名/tools/km-template-generator/km_template_generator.py",
        "${input:kmTitle}"
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
  ],
  "inputs": [
    {
      "id": "kmTitle",
      "description": "KMファイルのタイトルを入力してください",
      "default": "新しい依頼",
      "type": "promptString"
    }
  ]
}
```

⚠️ **重要**: `args` 内のパスを、Step 1でダウンロードした `km_template_generator.py` の実際のパスに変更してください。

既存の `tasks.json` がある場合は、`tasks` 配列と `inputs` 配列にそれぞれ追加してください。

### Step 4: VS Code Mind Map 拡張機能のインストール

KMファイルをビジュアルに編集するための拡張機能をインストールします。

1. VS Code/Cursor を開く
2. 拡張機能パネルを開く（`Ctrl+Shift+X` / `Cmd+Shift+X`）
3. "oorzc.mind-map" を検索
4. "Mind Map" 拡張機能をインストール

または、以下のリンクから直接インストール：
- [Open VSX](https://open-vsx.org/extension/oorzc/mind-map)
- [Cursor Marketplace](http://marketplace.cursorapi.com/items/?itemName=oorzc.mind-map)

### Step 5: 動作確認

すべての設定が完了したら、実際に使ってみましょう。

1. **VS Code/Cursor でプロジェクトを開く**
2. **コマンドパレットを開く**（`Cmd/Ctrl+Shift+P`）
3. **"Tasks: Run Task" を選択**
4. **"Create KM Template" を選択**
5. **タイトルを入力**（例：「データ分析の依頼」）
6. **自動的にKMファイルが作成され、エディタで開かれます**

## 🎯 使用方法（ワークフロー）

### 1️⃣ KMテンプレート生成
```
Cmd/Ctrl+Shift+P → "Tasks: Run Task" → "Create KM Template"
```

### 2️⃣ ビジュアル編集
- 生成されたKMファイルがMind Mapビューで開きます
- ノードを追加・編集・移動して思考を整理

### 3️⃣ 構造化テキストの取得
- 右クリックまたはコマンドパレットから「Export Node」を実行
- インデントされた構造化テキストがクリップボードにコピーされます

### 4️⃣ LLMへ貼り付け
- 構造化されたテキストをLLMチャットに貼り付けて依頼

## 🚀 自動インストールを使いたい方へ

手動セットアップが面倒な方は、自動インストールスクリプトも用意しています：

```bash
git clone https://github.com/miyatti777/km-template-generator.git
cd km-template-generator
./install.sh
```

ただし、手動セットアップの方が以下の利点があります：
- 各設定の意味を理解できる
- 環境に合わせたカスタマイズが容易
- トラブルシューティングが簡単
- セキュリティ面で安心

## 📝 カスタマイズのヒント

### 出力先の変更

環境変数で一時的に出力先を変更できます：

```bash
export KM_FLOW_BASE_DIR="/path/to/custom/flow"
```

### テンプレート構造のカスタマイズ

`km_template_generator.py` の `create_km_template()` 関数を編集して、デフォルトの構造をカスタマイズできます。

## 🎯 まとめ

このセットアップにより、以下のワークフローが実現できます：

1. **高速なテンプレート生成**: タスクランナーから数秒で作成
2. **直感的な思考整理**: マインドマップで視覚的に構造化
3. **効果的なLLM活用**: 整理されたコンテキストで精度の高い回答を取得

手動セットアップは一見面倒に見えますが、一度設定すれば長期的に大きな生産性向上が期待できます。ぜひお試しください！

## 📚 関連リンク

- [GitHubリポジトリ](https://github.com/miyatti777/km-template-generator)
- [VS Code Mind Map 拡張機能](https://open-vsx.org/extension/oorzc/mind-map)
- [VS Code Tasks ドキュメント](https://code.visualstudio.com/docs/editor/tasks)

---

**質問やフィードバック**: GitHubのIssueまたはTwitter @miyatti777 までお気軽にどうぞ！
