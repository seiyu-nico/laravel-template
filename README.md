# Laravel + FrankenPHP + Octane Template

Docker を使用した Laravel 開発環境テンプレートです。FrankenPHP と Laravel Octane により、高速なパフォーマンスと優れた開発体験を提供します。

## 特徴

- **FrankenPHP**: Goで書かれた高速PHPアプリケーションサーバー
- **Laravel Octane**: アプリケーションをメモリに常駐させ、超高速レスポンスを実現
- **Traefik統合**: リバースプロキシによる複数プロジェクトの管理が容易
- **マルチ環境対応**: local（Xdebug付き）、dev、prod の3環境
- **自動セットアップ**: 対話形式のスクリプトで簡単セットアップ

## クイックスタート

### 自動セットアップスクリプト（推奨）

対話形式のセットアップスクリプトを実行するだけで、すべての設定が完了します。

```bash
./setup.sh
```

スクリプトが以下を自動で行います:
1. プロジェクト設定の収集（SERVICE_NAME、APP_HOST など）
2. .envファイルの生成
3. Dockerイメージのビルド
4. コンテナの起動
5. Laravelプロジェクトの作成（プロジェクト直下に配置）
6. Laravel Octaneのインストールと設定
7. 推奨パッケージのインストール（オプション）

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

```bash
make octane-start    # Octane起動
make octane-stop     # Octane停止
make octane-reload   # Octane再読み込み
make octane-status   # Octane状態確認
make octane-watch    # ファイル監視モードで起動
```

### Laravel

```bash
make migrate         # マイグレーション実行
make seed            # シーダー実行
make tinker          # Tinker起動
make test            # テスト実行
make pint            # コード整形
make phpstan         # 静的解析
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
├── compose.yaml          # Docker Compose設定
├── Makefile              # 便利コマンド集
└── README.md             # このファイル
```

## 環境設定

### .env ファイル

主要な環境変数:

```env
ENV=local                    # 環境 (local/dev/prod)
UID=1000                     # ユーザーID
GID=1000                     # グループID
SERVICE_NAME=laravel         # サービス名
CONTAINER_NAME=laravel       # コンテナ名
APP_HOST=laravel.example.com # Traefik用ホスト名

# FrankenPHP / Octane settings
OCTANE_SERVER=frankenphp     # Octaneサーバー
OCTANE_WORKERS=1             # ワーカー数
OCTANE_MAX_REQUESTS=500      # 最大リクエスト数
```

## アクセス方法

Traefik経由でアクセスします：

```
https://${APP_HOST}      # 例: https://laravel.example.com
```

**注意**: Traefikが起動していることを確認してください。

## パフォーマンス

Laravel Octane + FrankenPHP により、従来のPHP-FPM構成と比較して:

- リクエスト処理速度が約 **2-3倍** 向上
- アプリケーションがメモリに常駐するため、起動オーバーヘッドが削減
- ワーカープロセスの効率的な管理

## トラブルシューティング

### パーミッションエラー

```bash
# コンテナ内で権限を修正
docker compose exec app chmod -R 777 storage bootstrap/cache
```

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
