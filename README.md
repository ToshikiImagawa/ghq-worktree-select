# ghq-worktree-select

ghq管理下のリポジトリからブランチを選択してgit worktreeを作成・移動するシェルユーティリティ

## 機能

- ghqで管理しているリポジトリをfzfで選択
- 選択したリポジトリのブランチをfzfで選択
- git worktreeを自動作成
- 作成したworktreeのパスを出力（cdコマンドと組み合わせて使用）

## インストール

### Homebrew（推奨）

```bash
brew install ToshikiImagawa/ghq-worktree-select/ghq-worktree-select
```

Homebrewでインストールすると、依存関係（ghq、fzf、git）が自動的にインストールされます。

### 必要な依存関係

- [ghq](https://github.com/x-motemen/ghq) - リポジトリ管理
- [fzf](https://github.com/junegunn/fzf) - ファジーファインダー
- git - バージョン管理（worktree対応版）

## 使い方

### 基本的な使い方

```bash
# リポジトリとブランチを選択してworktreeを作成し、移動
cd $(ghq-worktree-select)
```

### オプション

```bash
ghq-worktree-select --version  # バージョン情報を表示
ghq-worktree-select --help     # ヘルプを表示
```

### 便利なエイリアス

`.zshrc`または`.bashrc`にエイリアスを追加すると便利です：

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
brew uninstall ghq-worktree-select
```

## ライセンス

MIT License

## 貢献

Issue・Pull Requestを歓迎します！

## 作者

[Toshiki Imagawa](https://github.com/ToshikiImagawa)
