# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

ghq-worktree-selectは、ghq管理下のリポジトリからブランチを選択し、git worktreeの作成・移動を支援するシェルユーティリティです。

### 主要ファイル

- `ghq-worktree-select.sh`: メインスクリプト（全ての機能を含む単一ファイル）
- `CHANGELOG.md`: Keep a Changelog形式の変更履歴
- `.github/workflows/release.yml`: タグpush時の自動リリースワークフロー

### アーキテクチャ

単一のBashスクリプトで完結する設計。主要な関数構成:

- `ghq-worktree-select()`: メイン処理（リポジトリ選択 → ブランチ選択 → worktree作成 → symlink作成）
- `_find_existing_worktree()`: 既存worktreeの検索
- `_find_main_worktree()`: main/masterブランチのworktreeパス取得
- `_validate_path()`: セキュリティチェック（絶対パス・親ディレクトリ参照の拒否）
- `_create_symlinks()`: `.ghq-worktree-symlinks`設定ファイルに基づくシンボリックリンク作成
- `gws()`: エイリアス関数（worktree作成後に`cd`を実行）

## 開発コマンド

### 基本動作確認

```bash
# スクリプトを直接実行
./ghq-worktree-select.sh

# バージョン確認
./ghq-worktree-select.sh --version

# ヘルプ表示
./ghq-worktree-select.sh --help
```

### 依存関係

以下のツールが必須:
- `ghq`: リポジトリ管理
- `fzf`: ファジーファインダー
- `git`: worktree機能が必要

```bash
# 依存関係の確認（スクリプト内で自動チェック）
command -v ghq && command -v fzf && command -v git
```

### バージョン更新手順

1. `ghq-worktree-select.sh`内の`GHQ_WORKTREE_SELECT_VERSION`変数を更新
2. `CHANGELOG.md`を更新（`/changelog`スキルを使用可能）
3. コミット・プッシュ
4. Gitタグを作成（`v1.x.x`形式）してpush → GitHub Actionsが自動リリース

```bash
# タグ作成例
git tag v1.2.0
git push origin v1.2.0
```

### リリース自動化

`.github/workflows/release.yml`により、`v*.*.*`形式のタグがpushされると:
1. CHANGELOG.mdから該当バージョンのセクションを抽出
2. GitHubリリースを自動作成

## コーディングガイドライン

### Bashスクリプトのスタイル

- 関数名: プライベート関数には`_`プレフィックス（例: `_validate_path`）
- エラー処理: `>&2`で標準エラー出力に警告を出力
- セキュリティ: パス検証を必ず実施（絶対パス・`..`・特殊文字の拒否）
- 互換性: Bash 3.2+で動作すること（macOSデフォルト）

### Worktreeパス命名規則

```
{repository_path}+{branch_name}
```

- ブランチ名の`/`は`_`に置換
- 例: `~/ghq/github.com/user/repo+feature_new-feature`

### シンボリックリンク機能

- `.ghq-worktree-symlinks`ファイルをmain/masterブランチに配置
- セキュリティ制約: 相対パスのみ許可、絶対パス・親ディレクトリ参照は拒否
- main/masterブランチ自身へのworktree作成時はsymlink作成をスキップ

## コミットメッセージ規則

プレフィックスを使用:
- `[add]`: 新機能追加
- `[update]`: 既存機能の更新
- `[fix]`: バグ修正
- `[refactoring]`: リファクタリング
- `[remove]`: 機能削除
- `[docs]`: ドキュメント更新
- `[test]`: テスト関連

## 利用可能なスキル

- `/changelog`: CHANGELOG.md更新（Keep a Changelog形式）
- `/create-pr`: PR作成支援
- `/review-pr`: PR包括レビュー