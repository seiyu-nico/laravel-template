# setup.sh 追加パッケージ 設計書

- 日付: 2026-07-20
- 対象ファイル: `setup.sh`（このファイルのみ変更）
- 目的: `setup.sh` によるプロジェクト構築時に、フルスタック Web アプリ向けの追加パッケージを個別選択でインストールできるようにする。

## 背景・前提

- このリポジトリは Laravel + FrankenPHP + Octane のプロジェクトテンプレート。`setup.sh` が Laravel をルート直下に生成する。
- 主なユースケースは **フルスタック Web アプリ**。フロントエンド構成（Livewire / Inertia / Blade 等）はプロジェクトごとに変わるため、フロント固有パッケージはテンプレートに固定しない。
- 既存の「推奨開発パッケージ」（`doctrine/dbal`, `barryvdh/laravel-ide-helper`, `barryvdh/laravel-debugbar`, `laravel/pint`, `larastan/larastan`）は **定番として一括インストールのまま維持**する（今回は変更しない）。

## スコープ

### 追加するパッケージ（個別選択・全てデフォルト Yes = `[Y/n]`）

| パッケージ | 種別 | セットアップ深度 |
|---|---|---|
| `spatie/laravel-data` | 本番 (`require`) | require のみ |
| `pestphp/pest` + `pestphp/pest-plugin-laravel` | dev | フル（`pest --init` で初期化まで） |
| `rector/rector` + `driftingly/rector-laravel` | dev | フル（`rector.php` 生成 + composer スクリプト追加） |
| `internachi/modular` | 本番 (`require`) | require のみ |

### 対象外（今回やらない）

- 既存推奨5パッケージの構成変更。
- フロントエンド関連パッケージ（Livewire / Inertia など）。
- config の publish（laravel-data / modular はデフォルトのまま。必要時に手動）。
- Makefile / Taskfile への新規ターゲット追加（`make test` は既存の `php artisan test` 経由で Pest もそのまま動作するため不要）。

## 詳細設計

### 1. プロンプト収集

既存の「推奨開発パッケージ `[Y/n]`」プロンプトの直後、`cc-sdd` プロンプトの前に、以下4つを追加する。全てデフォルト Yes。

```bash
read -r -p "spatie/laravel-data をインストールしますか? [Y/n]: " INSTALL_LARAVEL_DATA
INSTALL_LARAVEL_DATA=${INSTALL_LARAVEL_DATA:-Y}

read -r -p "Pest (テストフレームワーク) をインストールしますか? [Y/n]: " INSTALL_PEST
INSTALL_PEST=${INSTALL_PEST:-Y}

read -r -p "Rector (自動リファクタ) をインストールしますか? [Y/n]: " INSTALL_RECTOR
INSTALL_RECTOR=${INSTALL_RECTOR:-Y}

read -r -p "internachi/modular (モジュラー構成) をインストールしますか? [Y/n]: " INSTALL_MODULAR
INSTALL_MODULAR=${INSTALL_MODULAR:-Y}
```

### 2. 設定確認サマリ

実行前の設定確認セクションに、上記4パッケージの「インストールする / しない」を追記し、実行前に一覧確認できるようにする（既存の cc-sdd / Laravel Boost の表示に倣う）。

### 3. インストール処理

配置場所: 既存「推奨パッケージ」ブロックの直後、`cc-sdd` インストールの前。各パッケージは独立した `if` ブロックとし、推奨パッケージの Y/N とは無関係に単独で判定する。実行順は laravel-data → Pest → Rector → modular。各ブロックに既存踏襲の `print_info` / `print_success` を付ける。

#### 3-1. laravel-data

```bash
if [[ $INSTALL_LARAVEL_DATA =~ ^[Yy]$ ]]; then
    docker compose exec "$CONTAINER_NAME" composer require spatie/laravel-data
fi
```

#### 3-2. Pest（フル）

```bash
if [[ $INSTALL_PEST =~ ^[Yy]$ ]]; then
    docker compose exec "$CONTAINER_NAME" composer require --dev --with-all-dependencies \
        pestphp/pest pestphp/pest-plugin-laravel
    docker compose exec "$CONTAINER_NAME" ./vendor/bin/pest --init
fi
```

- `make test`（= `php artisan test`）で Pest がそのまま動作するため Makefile 変更は不要。
- Larastan（既存）と Pest は併用可。

#### 3-3. Rector（フル）

```bash
if [[ $INSTALL_RECTOR =~ ^[Yy]$ ]]; then
    docker compose exec "$CONTAINER_NAME" composer require --dev rector/rector driftingly/rector-laravel
    # rector.php を生成（ホスト側 heredoc）
    # composer.json に rector / check-rector スクリプトを追加（jq、pint/phpstan と同パターン）
fi
```

生成する `rector.php`:

```php
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
```

追加する composer スクリプト（jq、既存 pint/phpstan と同じパターン。jq が無い場合は警告してスキップ）:

- `"rector": "./vendor/bin/rector process"` — リファクタを**適用して実行**
- `"check-rector": "./vendor/bin/rector process --dry-run"` — 変更せずチェック（CI 用）

#### 3-4. internachi/modular

```bash
if [[ $INSTALL_MODULAR =~ ^[Yy]$ ]]; then
    docker compose exec "$CONTAINER_NAME" composer require internachi/modular
fi
```

### 4. 完了メッセージ

スクリプト末尾のコマンド案内に、Rector（`composer rector` / `composer check-rector`）と Pest（`make test`）の案内を軽く追記する。

## 検証方法

- `bash -n setup.sh` で構文チェック。
- プロンプトのデフォルト値（Enter で Yes）が想定どおりか目視確認。
- jq 分岐（jq 有 / 無）で composer.json スクリプト追加がスキップされる挙動を確認。

## 留意点

- `driftingly/rector-laravel` の `LaravelSetList::LARAVEL_120` は Laravel 12 系向けセット。生成される Laravel のバージョンに追従が必要になった場合、この定数を見直す。
- Pest 初期化（`pest --init`）は生成直後の状態を前提とする。既存テストを大きく改変した後の再実行は想定しない。
