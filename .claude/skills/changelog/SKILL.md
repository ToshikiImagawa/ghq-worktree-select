---
name: changelog
description: リリース時にCHANGELOG.mdを自動生成・更新するスキル。Keep a Changelog形式に従い、gitコミット履歴から変更内容を抽出してCHANGELOG.mdに記録する。リリース時、バージョンアップ時、または明示的にチェンジログの更新を依頼された場合に使用する。
---

# Changelog

リリース時にCHANGELOG.mdを自動生成・更新するスキル。

## 概要

このスキルは、gitコミット履歴から変更内容を抽出し、[Keep a Changelog](https://keepachangelog.com/)形式でCHANGELOG.mdファイルを生成・更新する。コミットメッセージのプレフィックス（`[add]`, `[update]`, `[fix]`等）を解析し、適切なカテゴリに分類する。

## 使用タイミング

- ユーザーが「チェンジログを更新して」「CHANGELOG.mdを作成して」と依頼した場合
- リリース準備時に明示的にチェンジログの更新が必要な場合
- 新しいバージョンをタグ付けする前

## ワークフロー

### 1. 現在の状態を確認

まず、CHANGELOG.mdが既に存在するかを確認する。

```bash
ls CHANGELOG.md 2>/dev/null || echo "ファイルが存在しません"
```

### 2. 最新のリリースタグを特定

最新のリリースタグを取得し、そのタグ以降のコミットを対象とする。

```bash
# 最新のタグを取得
git describe --tags --abbrev=0 2>/dev/null || echo "HEAD"
```

タグが存在しない場合は、すべてのコミット履歴を対象とする。

### 3. コミット履歴を取得

最新タグ以降（またはすべて）のコミット履歴を取得する。

```bash
# タグが存在する場合
git log <最新タグ>..HEAD --oneline --no-merges

# タグが存在しない場合
git log --oneline --no-merges
```

### 4. コミットメッセージを分類

コミットメッセージのプレフィックスに基づいて、以下のカテゴリに分類する：

- `[add]` → **Added** (新機能)
- `[update]` → **Changed** (既存機能の変更)
- `[fix]` → **Fixed** (バグ修正)
- `[refactoring]` → **Changed** (リファクタリング)
- `[remove]` → **Removed** (削除された機能)
- `[docs]` → **Changed** (ドキュメント更新)
- `[test]` → 記載しない（チェンジログには含めない）

プレフィックスがない場合は **Changed** カテゴリに分類する。

### 5. CHANGELOG.mdを生成・更新

Keep a Changelog形式でCHANGELOG.mdを生成または更新する。

#### 新規作成の場合

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- 新機能の説明

### Changed
- 既存機能の変更内容

### Fixed
- 修正されたバグの説明
```

#### 既存ファイルの更新の場合

- `## [Unreleased]` セクションが存在する場合は、そこに追記する
- 存在しない場合は、`# Changelog` の直後に `## [Unreleased]` セクションを追加する
- 各カテゴリ（Added/Changed/Fixed等）は、エントリがある場合のみ表示する

### 6. ユーザーに確認

生成されたCHANGELOG.mdの内容をユーザーに提示し、確認を求める。必要に応じて手動での調整を促す。

## バージョンのリリース

リリース時には、`[Unreleased]` セクションを新しいバージョン番号に変更する。

```markdown
## [1.2.0] - 2026-02-17

### Added
- 新機能の説明
```

## 注意事項

- コミットメッセージは日本語で記述されている前提
- マージコミット（`--no-merges`）は除外する
- `[test]` プレフィックスのコミットはチェンジログに含めない
- ユーザーが最終確認を行い、必要に応じて手動で調整できるようにする
