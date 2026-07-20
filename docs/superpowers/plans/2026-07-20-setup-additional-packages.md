# setup.sh 追加パッケージ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `setup.sh` に、フルスタック向け追加パッケージ4種（laravel-data / Pest / Rector / internachi/modular）を個別選択（デフォルト Yes）でインストールする処理を追加する。

**Architecture:** 既存の対話フロー（プロンプト収集 → 設定確認 → インストール処理 → 完了メッセージ）に沿って、4パッケージ分の (1) プロンプト、(2) 確認サマリ行、(3) 独立した `if` インストールブロック、(4) 完了メッセージ案内、を挿入する。既存の「推奨パッケージ」束は変更しない。

**Tech Stack:** Bash, Docker Compose, Composer, Laravel（PHP 8.4 / FrankenPHP / Octane）, jq。

## Global Constraints

- 変更対象は `setup.sh` の1ファイルのみ。
- 追加4パッケージは全て個別選択、デフォルト Yes（`[Y/n]`、`${VAR:-Y}`）。
- インストール処理は既存「推奨パッケージ」ブロック直後・`cc-sdd` インストール前に、パッケージごとに独立した `if` ブロックとして配置。実行順: laravel-data → Pest → Rector → modular。
- 各ブロックは既存踏襲で `print_info`（開始）/`print_success`（完了）を使う。
- composer.json へのスクリプト追加は既存 pint/phpstan と同じ jq パターン（jq 無しなら `print_warning` してスキップ）。
- コンテナ内実行は `docker compose exec "$CONTAINER_NAME" ...`、ホスト側ファイル編集はコンテナ外で行う（既存パターン踏襲）。
- シェル構文チェック `bash -n setup.sh` が各コミット前に通ること。
- 変数名（確定）: `INSTALL_LARAVEL_DATA` / `INSTALL_PEST` / `INSTALL_RECTOR` / `INSTALL_MODULAR`。

## File Structure

- Modify: `setup.sh`
  - プロンプト収集部（現 149-160 行付近、`推奨パッケージ` プロンプト直後）
  - 設定確認サマリ部（現 175-189 行付近、`Laravel Boost` 表示の後）
  - インストール処理部（現「推奨パッケージ」`if` ブロック閉じ `fi`（現 463 行付近）直後、`cc-sdd` インストール前）
  - 完了メッセージ部（現 513-518 行付近、Octane コマンド案内の後）

**テストについて:** 本変更はシェルスクリプトの対話フロー追加であり、自動テストの仕組みは無い。検証は各タスクで `bash -n setup.sh`（構文）と、対象ブロックの `grep` による存在確認で行う。実際のパッケージ導入結果は本番 `./setup.sh` 実行時に確認される前提。

---

### Task 1: プロンプト収集と確認サマリの追加

**Files:**
- Modify: `setup.sh`（プロンプト収集部 / 確認サマリ部）

**Interfaces:**
- Produces: シェル変数 `INSTALL_LARAVEL_DATA`, `INSTALL_PEST`, `INSTALL_RECTOR`, `INSTALL_MODULAR`（各値は `Y`/`N` 相当。後続 Task 2-4 の `if [[ $VAR =~ ^[Yy]$ ]]` で参照）。

- [ ] **Step 1: プロンプト4つを追加**

`setup.sh` の以下の箇所（`推奨開発パッケージ` プロンプトの直後、`cc-sdd` プロンプトの前）を編集する。

対象（既存）:
```bash
read -r -p "推奨開発パッケージをインストールしますか? (IDE Helper, Debugbar, Pint, Larastan) [Y/n]: " INSTALL_PACKAGES
INSTALL_PACKAGES=${INSTALL_PACKAGES:-Y}

# cc-sddのインストール確認
```

編集後:
```bash
read -r -p "推奨開発パッケージをインストールしますか? (IDE Helper, Debugbar, Pint, Larastan) [Y/n]: " INSTALL_PACKAGES
INSTALL_PACKAGES=${INSTALL_PACKAGES:-Y}

# 追加パッケージのインストール確認（個別選択、デフォルトYes）
echo ""
read -r -p "spatie/laravel-data をインストールしますか? [Y/n]: " INSTALL_LARAVEL_DATA
INSTALL_LARAVEL_DATA=${INSTALL_LARAVEL_DATA:-Y}

echo ""
read -r -p "Pest (テストフレームワーク) をインストールしますか? [Y/n]: " INSTALL_PEST
INSTALL_PEST=${INSTALL_PEST:-Y}

echo ""
read -r -p "Rector (自動リファクタ) をインストールしますか? [Y/n]: " INSTALL_RECTOR
INSTALL_RECTOR=${INSTALL_RECTOR:-Y}

echo ""
read -r -p "internachi/modular (モジュラー構成) をインストールしますか? [Y/n]: " INSTALL_MODULAR
INSTALL_MODULAR=${INSTALL_MODULAR:-Y}

# cc-sddのインストール確認
```

- [ ] **Step 2: 確認サマリ行を追加**

`Laravel Boost` の確認サマリ表示ブロックの直後（`setup.sh削除` サマリの前）に、以下を追加する。

対象（既存）:
```bash
if [[ $INSTALL_LARAVEL_BOOST =~ ^[Yy]$ ]]; then
    echo "Laravel Boost:         インストールする"
else
    echo "Laravel Boost:         インストールしない"
fi
```

この直後に追加:
```bash
if [[ $INSTALL_LARAVEL_DATA =~ ^[Yy]$ ]]; then
    echo "laravel-data:          インストールする"
else
    echo "laravel-data:          インストールしない"
fi
if [[ $INSTALL_PEST =~ ^[Yy]$ ]]; then
    echo "Pest:                  インストールする"
else
    echo "Pest:                  インストールしない"
fi
if [[ $INSTALL_RECTOR =~ ^[Yy]$ ]]; then
    echo "Rector:                インストールする"
else
    echo "Rector:                インストールしない"
fi
if [[ $INSTALL_MODULAR =~ ^[Yy]$ ]]; then
    echo "internachi/modular:    インストールする"
else
    echo "internachi/modular:    インストールしない"
fi
```

- [ ] **Step 3: 構文と挿入内容を検証**

Run:
```bash
bash -n setup.sh && grep -c 'INSTALL_LARAVEL_DATA\|INSTALL_PEST\|INSTALL_RECTOR\|INSTALL_MODULAR' setup.sh
```
Expected: 構文エラーなし。grep のカウントが `10`（プロンプト設定 各2回×4 = 8、確認サマリ `if` 各1回×4 = 4 → 実際は 12。数値は環境で確認し、4変数すべてが出現していれば可）。少なくとも4変数すべてがヒットすること。

- [ ] **Step 4: コミット**

```bash
git add setup.sh
git commit -m "feat: add prompts and summary for additional packages in setup.sh"
```

---

### Task 2: laravel-data と internachi/modular のインストール処理

**Files:**
- Modify: `setup.sh`（インストール処理部）

**Interfaces:**
- Consumes: `INSTALL_LARAVEL_DATA`, `INSTALL_MODULAR`（Task 1）, `$CONTAINER_NAME`（既存）。

- [ ] **Step 1: require のみの2ブロックを追加**

既存「推奨パッケージ」`if` ブロックを閉じる `fi` の直後（`cc-sdd` インストールの前）に追加する。

対象（既存、この `fi` の直後に挿入）:
```bash
    print_success "推奨パッケージをインストールしました"
fi
```

挿入するコード:
```bash

# spatie/laravel-data のインストール
if [[ $INSTALL_LARAVEL_DATA =~ ^[Yy]$ ]]; then
    echo ""
    print_header "spatie/laravel-data のインストール"
    print_info "spatie/laravel-data をインストールしています..."
    docker compose exec "$CONTAINER_NAME" composer require spatie/laravel-data
    print_success "spatie/laravel-data をインストールしました"
fi

# internachi/modular のインストール
if [[ $INSTALL_MODULAR =~ ^[Yy]$ ]]; then
    echo ""
    print_header "internachi/modular のインストール"
    print_info "internachi/modular をインストールしています..."
    docker compose exec "$CONTAINER_NAME" composer require internachi/modular
    print_success "internachi/modular をインストールしました"
fi
```

- [ ] **Step 2: 構文と挿入内容を検証**

Run:
```bash
bash -n setup.sh && grep -c 'composer require spatie/laravel-data\|composer require internachi/modular' setup.sh
```
Expected: 構文エラーなし。カウント `2`。

- [ ] **Step 3: コミット**

```bash
git add setup.sh
git commit -m "feat: install spatie/laravel-data and internachi/modular in setup.sh"
```

---

### Task 3: Pest のインストール処理（フル）

**Files:**
- Modify: `setup.sh`（インストール処理部、Task 2 のブロック群の後・`cc-sdd` の前）

**Interfaces:**
- Consumes: `INSTALL_PEST`（Task 1）, `$CONTAINER_NAME`（既存）。

- [ ] **Step 1: Pest インストールブロックを追加**

Task 2 で挿入した `internachi/modular` ブロックの直後に追加する。

```bash

# Pest のインストール
if [[ $INSTALL_PEST =~ ^[Yy]$ ]]; then
    echo ""
    print_header "Pest のインストール"
    print_info "Pest をインストールしています..."
    docker compose exec "$CONTAINER_NAME" composer require --dev --with-all-dependencies \
        pestphp/pest pestphp/pest-plugin-laravel
    print_info "Pest を初期化しています..."
    docker compose exec "$CONTAINER_NAME" ./vendor/bin/pest --init
    print_success "Pest をインストールしました"
fi
```

- [ ] **Step 2: 構文と挿入内容を検証**

Run:
```bash
bash -n setup.sh && grep -c 'pestphp/pest\|vendor/bin/pest --init' setup.sh
```
Expected: 構文エラーなし。カウント `2`（require 行に `pestphp/pest`、init 行に `vendor/bin/pest --init`）。

- [ ] **Step 3: コミット**

```bash
git add setup.sh
git commit -m "feat: install and init Pest in setup.sh"
```

---

### Task 4: Rector のインストール処理（フル：設定生成＋composerスクリプト）

**Files:**
- Modify: `setup.sh`（インストール処理部、Task 3 の Pest ブロックの後・`cc-sdd` の前）

**Interfaces:**
- Consumes: `INSTALL_RECTOR`（Task 1）, `$CONTAINER_NAME`（既存）, `jq`（存在時のみ）。

- [ ] **Step 1: Rector インストールブロックを追加**

Task 3 で挿入した Pest ブロックの直後に追加する。`rector.php` はホスト側 heredoc で生成（`'EOF'` クオートで変数展開を無効化）。composer スクリプト追加は既存 pint/phpstan と同じ jq パターン。

```bash

# Rector のインストール
if [[ $INSTALL_RECTOR =~ ^[Yy]$ ]]; then
    echo ""
    print_header "Rector のインストール"
    print_info "Rector をインストールしています..."
    docker compose exec "$CONTAINER_NAME" composer require --dev rector/rector driftingly/rector-laravel

    print_info "rector.php を生成しています..."
    cat > rector.php << 'EOF'
<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use RectorLaravel\Set\LaravelSetList;

return RectorConfig::configure()
    ->withPaths([
        __DIR__.'/app',
        __DIR__.'/config',
        __DIR__.'/database',
        __DIR__.'/routes',
        __DIR__.'/tests',
    ])
    ->withPhpSets()
    ->withSets([
        LaravelSetList::LARAVEL_120,
    ])
    ->withPreparedSets(deadCode: true, codeQuality: true);
EOF
    print_success "rector.php を生成しました"

    # composer.jsonにrectorスクリプトを追加（ホスト側で実行）
    if command -v jq &> /dev/null; then
        cp composer.json composer.json.tmp
        jq --indent 4 '.scripts |= .+{"rector": "./vendor/bin/rector process", "check-rector": "./vendor/bin/rector process --dry-run"}' composer.json.tmp > composer.json
        rm -f composer.json.tmp
        print_success "composer.jsonにrectorスクリプトを追加しました"
    else
        print_warning "jqがインストールされていないため、composer.jsonへのスクリプト追加をスキップしました"
    fi

    print_success "Rector をインストールしました"
fi
```

- [ ] **Step 2: 構文・挿入内容・生成 rector.php の妥当性を検証**

Run（シェル構文とキーワード確認）:
```bash
bash -n setup.sh && grep -c 'rector/rector\|driftingly/rector-laravel\|vendor/bin/rector process' setup.sh
```
Expected: 構文エラーなし。`rector/rector` と `driftingly/rector-laravel`（require 行）、`vendor/bin/rector process`（jq スクリプト内、2箇所）がヒット。

Run（heredoc で生成される rector.php が PHP として妥当かを、setup.sh から heredoc 部を抜き出して確認）:
```bash
sed -n '/cat > rector.php/,/^EOF$/p' setup.sh | sed '1d;$d' > /tmp/rector_check.php && php -l /tmp/rector_check.php && rm -f /tmp/rector_check.php
```
Expected: `No syntax errors detected in /tmp/rector_check.php`。（ローカルに php が無い場合はスキップ可。その場合は目視で PHP 構文を確認する。）

- [ ] **Step 3: コミット**

```bash
git add setup.sh
git commit -m "feat: install Rector with config and composer scripts in setup.sh"
```

---

### Task 5: 完了メッセージへのコマンド案内追加

**Files:**
- Modify: `setup.sh`（完了メッセージ部）

**Interfaces:**
- Consumes: なし（表示のみ）。

- [ ] **Step 1: 完了メッセージに Pest / Rector 案内を追加**

`Laravel Octane コマンド` の案内ブロック（`make octane-watch` の行を含む `echo` 群）の直後、`アプリケーションへのアクセス` の案内の前に追加する。

対象（既存）:
```bash
print_info "Laravel Octane コマンド:"
echo "  - Octane起動:     make octane-start"
echo "  - Octane停止:     make octane-stop"
echo "  - Octane再読込:   make octane-reload"
echo "  - Octane状態確認: make octane-status"
echo "  - 監視モード:     make octane-watch"
echo ""
```

この直後に追加:
```bash
print_info "品質・テスト コマンド:"
echo "  - テスト実行:     make test"
echo "  - Rector適用:     composer rector"
echo "  - Rector確認:     composer check-rector"
echo ""
```

- [ ] **Step 2: 構文と挿入内容を検証**

Run:
```bash
bash -n setup.sh && grep -c 'composer rector\|composer check-rector' setup.sh
```
Expected: 構文エラーなし。カウント `2`。

- [ ] **Step 3: コミット**

```bash
git add setup.sh
git commit -m "docs: add Pest/Rector command hints to setup.sh completion message"
```

---

## 検証（全タスク完了後）

- [ ] `bash -n setup.sh` が通ること。
- [ ] 4つの追加プロンプトが `推奨パッケージ` と `cc-sdd` の間に並ぶこと（`grep -n 'をインストールしますか' setup.sh` で順序確認）。
- [ ] インストール4ブロックが「推奨パッケージ」ブロックの後・`cc-sdd` の前に並ぶこと。
- [ ] 生成される `rector.php` が `php -l` を通ること（Task 4 Step 2 で確認済み）。

## 留意点

- `LaravelSetList::LARAVEL_120` は Laravel 12 系向けセット。生成される Laravel が別メジャーの場合はこの定数を追従させる（`driftingly/rector-laravel` の提供定数に依存）。
- `pest --init` は Laravel 生成直後のクリーンな状態を前提とする。
- 実際のパッケージ導入可否（バージョン整合など）は本番 `./setup.sh` 実行時に確定する。本プランのタスクレベル検証はシェル構文と挿入内容に限定される。
