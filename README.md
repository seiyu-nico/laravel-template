# Laravel + FrankenPHP + Octane Template

Docker を使用した Laravel 開発環境テンプレートです。FrankenPHP と Laravel Octane により、高速なパフォーマンスと優れた開発体験を提供します。

## 特徴

- **FrankenPHP**: Goで書かれた高速PHPアプリケーションサーバー
- **Laravel Octane**: アプリケーションをメモリに常駐させ、超高速レスポンスを実現
- **Traefik統合**: リバースプロキシによる複数プロジェクトの管理が容易
- **マルチ環境対応**: local（PCOV付き）、dev、prod の3環境
- **自動セットアップ**: 対話形式のスクリプトで簡単セットアップ

## クイックスタート

### 自動セットアップスクリプト（推奨）

対話形式のセットアップスクリプトを実行するだけで、すべての設定が完了します。

```bash
./setup.sh
```

スクリプトが以下を自動で行います:
1. プロジェクト設定の収集（SERVICE_NAME、APP_HOST など）
2. compose.yamlへのサービス名・Traefik設定の書き込み
3. Dockerイメージのビルド
4. Laravelプロジェクトの作成（プロジェクト直下に配置）と .env.local / .env.testing の生成
5. Laravel Octaneのインストールと設定
6. 推奨パッケージのインストール（オプション）
7. 追加パッケージのインストール（オプション、個別選択）: spatie/laravel-data、Pest、Rector、internachi/modular
8. コンテナの起動（Octane）

## 必要な環境

- Docker
- Docker Compose
- Traefik（リバースプロキシとして動作中であること）

## よく使うコマンド

### コンテナ管理

```bash
make up              # コンテナ起動
make down            # コンテナ停止
make restart         # コンテナ再起動
make ps              # コンテナ状態確認
make logs            # ログ表示
make app             # appコンテナにログイン
```

### Laravel Octane

コンテナ起動時に Octane (FrankenPHP) がファイル監視モード (`--watch`) で自動起動し、コード変更は自動で反映されます。

```bash
make octane-reload   # Octane再読み込み
make octane-status   # Octane状態確認
```

### Laravel

```bash
make migrate         # マイグレーション実行
make seed            # シーダー実行
make tinker          # Tinker起動
make test            # 変更の影響を受けるテストのみ実行（Pest TIA）
make test-all        # 全テスト実行
make pint            # コード整形
make phpstan         # 静的解析
make rector          # Rectorによる自動リファクタ適用
make check-rector    # Rectorによる自動リファクタ確認（dry-run）
```

## ディレクトリ構造

```
laravel-template/
├── app/                  # Laravelアプリケーション
├── bootstrap/
├── config/
├── ...                   # その他Laravelディレクトリ
├── infra/docker/
│   └── php/              # FrankenPHP + PHP設定
│       ├── Dockerfile
│       └── php.ini/
├── setup.sh              # 自動セットアップスクリプト
├── compose.yaml          # Docker Compose設定（サービス名・Traefik設定を含む）
├── Makefile              # 便利コマンド集
└── README.md             # このファイル
```

## 環境設定

### 環境設定ファイル

| ファイル | 用途 | git管理 |
|---|---|---|
| `.env.local` | アプリの設定。`compose.yaml` の `APP_ENV=local` により Laravel はこれを読み込む | する |
| `.env.testing` | テスト実行時の設定 | する |
| `compose.override.yaml` | コンテナ設定を各自で上書きしたい場合に作成する | しない |

チーム全員が同じ設定を使えるよう、`.env.local` と `.env.testing` は git 管理します。`.env` と `.env.example` は使いません。

```env
APP_ENV=local
APP_KEY=base64:...

# FrankenPHP / Octane settings
OCTANE_SERVER=frankenphp     # Octaneサーバー
OCTANE_WORKERS=1             # ワーカー数
OCTANE_MAX_REQUESTS=500      # 最大リクエスト数
```

### コンテナ設定

サービス名・Traefik のホスト名・ビルドターゲットは `compose.yaml` に直接記述しています（`setup.sh` が書き換えます）。
worktree で別ホスト名を使うなど、各自で変更したい場合は `compose.override.yaml` を作成して上書きしてください。

## アクセス方法

Traefik経由でアクセスします：

```
https://laravel.example.com   # compose.yaml の Host() に設定したホスト名
```

**注意**: Traefikが起動していることを確認してください。

## パフォーマンス

Laravel Octane + FrankenPHP により、従来のPHP-FPM構成と比較して:

- リクエスト処理速度が約 **2-3倍** 向上
- アプリケーションがメモリに常駐するため、起動オーバーヘッドが削減
- ワーカープロセスの効率的な管理

## トラブルシューティング

### Octaneが起動しない

```bash
# キャッシュクリア
docker compose exec app php artisan optimize:clear

# Octane状態確認
docker compose exec app php artisan octane:status
```

### コンテナにアクセスできない

```bash
# Traefikが起動しているか確認
docker ps | grep traefik

# コンテナのログを確認
make logs
```

## 詳細ドキュメント

- [FrankenPHP公式ドキュメント](https://frankenphp.dev/)
- [Laravel Octane公式ドキュメント](https://laravel.com/docs/octane)

## ライセンス

MIT License

## 作者

seiyu-nico (2025)
