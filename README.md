# ghq-worktree-select

ghq管理下のリポジトリからブランチを選択してgit worktreeを作成・移動するシェルユーティリティ

## 機能

- ghqで管理しているリポジトリをfzfで選択
- 選択したリポジトリのブランチをfzfで選択
- git worktreeを自動作成
- 作成したworktreeのパスを出力（cdコマンドと組み合わせて使用）

## 必要な依存関係

- [ghq](https://github.com/x-motemen/ghq) - リポジトリ管理
- [fzf](https://github.com/junegunn/fzf) - ファジーファインダー
- git - バージョン管理（worktree対応版）

## インストール

### 方法1: 手動インストール（curl）

```bash
# ダウンロード
curl -o ~/.ghq-worktree-select.sh https://raw.githubusercontent.com/ToshikiImagawa/ghq-worktree-select/main/ghq-worktree-select.sh

# .zshrc または .bashrc に追加
echo 'source ~/.ghq-worktree-select.sh' >> ~/.zshrc
```

### 方法2: git clone

```bash
# クローン
git clone https://github.com/ToshikiImagawa/ghq-worktree-select.git ~/.ghq-worktree-select

# .zshrc または .bashrc に追加
echo 'source ~/.ghq-worktree-select/ghq-worktree-select.sh' >> ~/.zshrc
```

### 方法3: zinit/zplug（zshプラグインマネージャー）

#### zinit の場合

```bash
# .zshrc に追加
zinit light ToshikiImagawa/ghq-worktree-select
```

#### zplug の場合

```bash
# .zshrc に追加
zplug "ToshikiImagawa/ghq-worktree-select"
```

## 使い方

### 基本的な使い方

```bash
# リポジトリとブランチを選択してworktreeを作成し、移動
cd $(ghq-worktree-select)
```

### 便利なエイリアス

スクリプトには `gws` エイリアス関数が含まれています：

```bash
# 使用例
gws  # リポジトリとブランチを選択して自動的に移動
```

または、`.zshrc`/`.bashrc`に独自のエイリアスを追加できます：

```bash
alias gws='cd $(ghq-worktree-select)'
```

## worktreeの命名規則

作成されるworktreeのパスは以下の形式になります：

```
{リポジトリパス}+{ブランチ名}
```

例：
- リポジトリ: `~/ghq/github.com/user/repo`
- ブランチ: `feature/new-feature`
- worktree: `~/ghq/github.com/user/repo+feature_new-feature`

（ブランチ名の `/` は `_` に置換されます）

## アンインストール

```bash
# .zshrc または .bashrc から以下の行を削除
# source ~/.ghq-worktree-select.sh

# ファイルを削除
rm ~/.ghq-worktree-select.sh
# または
rm -rf ~/.ghq-worktree-select
```

## ライセンス

MIT License

## 貢献

Issue・Pull Requestを歓迎します！

## 作者

[Toshiki Imagawa](https://github.com/ToshikiImagawa)
