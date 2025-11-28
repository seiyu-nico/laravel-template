#!/usr/bin/env bash

set -e

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# カラーメッセージ出力関数
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# 必須コマンドの確認
check_requirements() {
    print_header "必須環境のチェック"

    local missing_deps=0

    if ! command -v docker &> /dev/null; then
        print_error "Docker がインストールされていません"
        missing_deps=1
    else
        print_success "Docker がインストールされています"
    fi

    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose がインストールされていません"
        missing_deps=1
    else
        print_success "Docker Compose がインストールされています"
    fi

    if [ $missing_deps -eq 1 ]; then
        print_error "不足している依存関係をインストールしてから再度実行してください"
        exit 1
    fi
}

# ウェルカムメッセージ
print_header "Laravel + FrankenPHP セットアップスクリプト"
echo "このスクリプトは、FrankenPHP と Octane を使用した新しい Laravel プロジェクトをセットアップします。"
echo ""

# 必須環境チェック
check_requirements

# 情報の収集
print_header "プロジェクト設定"

# SERVICE_NAME
read -r -p "サービス名を入力してください (デフォルト: laravel): " SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-laravel}
print_info "サービス名: $SERVICE_NAME"

# CONTAINER_NAME（SERVICE_NAMEから自動生成）
echo ""
# SERVICE_NAMEから英数字とハイフン、アンダースコアのみ抽出してデフォルト値を生成
default_container_name=$(echo "$SERVICE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

echo "コンテナ名を入力してください（英数字、ハイフン、アンダースコアのみ）"
if [ -n "$default_container_name" ]; then
    # デフォルト値がある場合
    while true; do
        read -r -p "コンテナ名 (デフォルト: $default_container_name): " CONTAINER_NAME
        CONTAINER_NAME=${CONTAINER_NAME:-$default_container_name}

        # バリデーション: 英数字、ハイフン、アンダースコアのみ許可
        if [[ "$CONTAINER_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            break
        else
            print_warning "コンテナ名は英数字、ハイフン、アンダースコアのみ使用できます。"
        fi
    done
else
    # デフォルト値がない場合は必須入力
    print_warning "サービス名から有効なコンテナ名を生成できませんでした。"
    while true; do
        read -r -p "コンテナ名: " CONTAINER_NAME

        if [ -z "$CONTAINER_NAME" ]; then
            print_warning "コンテナ名は必須です。入力してください。"
        elif [[ "$CONTAINER_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            break
        else
            print_warning "コンテナ名は英数字、ハイフン、アンダースコアのみ使用できます。"
        fi
    done
fi
print_info "コンテナ名: $CONTAINER_NAME"

# APP_HOST
echo ""
echo "Traefik用のWeb URLを入力してください"
echo "  例: ${SERVICE_NAME}.example.com"
echo "      ${SERVICE_NAME}.localhost"
while true; do
    read -r -p "Web URL: " APP_HOST
    if [ -n "$APP_HOST" ]; then
        break
    else
        print_warning "Web URLは必須です。入力してください。"
    fi
done
print_info "Web URL: $APP_HOST"

# ENV (固定値: local)
ENV="local"

# UID/GID
echo ""
current_uid=$(id -u)
current_gid=$(id -g)
read -r -p "UID を入力してください (デフォルト: $current_uid): " USER_ID
USER_ID=${USER_ID:-$current_uid}
read -r -p "GID を入力してください (デフォルト: $current_gid): " GROUP_ID
GROUP_ID=${GROUP_ID:-$current_gid}
print_info "UID: $USER_ID, GID: $GROUP_ID"

# Octane設定（固定値）
OCTANE_WORKERS=1
OCTANE_MAX_REQUESTS=500

# 推奨パッケージのインストール確認
echo ""
read -r -p "推奨開発パッケージをインストールしますか? (IDE Helper, Debugbar, Pint, Larastan) [Y/n]: " INSTALL_PACKAGES
INSTALL_PACKAGES=${INSTALL_PACKAGES:-Y}

# 確認
echo ""
print_header "設定内容の確認"
echo "サービス名:            $SERVICE_NAME"
echo "コンテナ名:            $CONTAINER_NAME"
echo "Web URL:               $APP_HOST"
echo "UID:                   $USER_ID"
echo "GID:                   $GROUP_ID"
if [[ $INSTALL_PACKAGES =~ ^[Yy]$ ]]; then
    echo "推奨パッケージ:        インストールする"
else
    echo "推奨パッケージ:        インストールしない"
fi
echo ""
print_info "※ 環境は local (Xdebug有効) で作成されます"
echo ""
read -r -p "この設定で続行しますか? [y/N]: " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    print_warning "セットアップをキャンセルしました"
    exit 0
fi

# .envファイルの作成
print_header ".envファイルの作成"
cat > .env << EOF
ENV=$ENV
UID=$USER_ID
GID=$GROUP_ID
SERVICE_NAME=$SERVICE_NAME
CONTAINER_NAME=$CONTAINER_NAME
APP_HOST=$APP_HOST

# FrankenPHP / Octane settings
OCTANE_SERVER=frankenphp
OCTANE_WORKERS=$OCTANE_WORKERS
OCTANE_MAX_REQUESTS=$OCTANE_MAX_REQUESTS
EOF
print_success ".envファイルを作成しました"

# compose.yamlのコンテナ名を変更
print_header "compose.yamlとMakefileのコンテナ名を変更"
print_info "compose.yamlのコンテナ名を 'app' から '$CONTAINER_NAME' に変更しています..."
sed -i.bak "s/^  app:/  $CONTAINER_NAME:/" compose.yaml
sed -i.bak "s/docker compose exec app /docker compose exec $CONTAINER_NAME /g" compose.yaml
sed -i.bak "s/docker compose logs app$/docker compose logs $CONTAINER_NAME/" compose.yaml
rm -f compose.yaml.bak
print_success "compose.yamlのコンテナ名を変更しました"

# Makefileのコンテナ名変数を変更
print_info "Makefileのコンテナ名を 'app' から '$CONTAINER_NAME' に変更しています..."
sed -i.bak "s/^DOCKER_EXEC := \$(DOCKER_COMPOSE) exec app$/DOCKER_EXEC := \$(DOCKER_COMPOSE) exec $CONTAINER_NAME/" Makefile
sed -i.bak "s/^CONTAINER_NAME := app$/CONTAINER_NAME := $CONTAINER_NAME/" Makefile
sed -i.bak "s/^app:/$CONTAINER_NAME:/" Makefile
sed -i.bak "s/^log-app:/log-$CONTAINER_NAME:/" Makefile
sed -i.bak "s/^log-app-watch:/log-$CONTAINER_NAME-watch:/" Makefile
rm -f Makefile.bak
print_success "Makefileのコンテナ名を変更しました"

# srcディレクトリの準備
if [ -d "src" ] && [ "$(ls -A src)" ]; then
    print_warning "srcディレクトリに既存のファイルが存在します"
    read -r -p "srcディレクトリを削除して続行しますか? [y/N]: " confirm_src
    if [[ ! $confirm_src =~ ^[Yy]$ ]]; then
        print_warning "セットアップをキャンセルしました"
        exit 0
    fi
fi

print_info "インストール用ディレクトリを準備しています..."
rm -rf src
mkdir -p src
print_success "インストール用ディレクトリを準備しました"

# Dockerイメージのビルド
print_header "Dockerイメージのビルド"
# docker compose build --no-cache --force-rm
docker compose build
print_success "Dockerイメージをビルドしました"

# コンテナの起動
print_header "コンテナの起動"
docker compose up -d
print_success "コンテナを起動しました"

# コンテナの準備待ち
print_info "コンテナの準備を待っています..."
sleep 3

# Laravelプロジェクトの作成
print_header "Laravelプロジェクトの作成"
docker compose exec "$CONTAINER_NAME" composer create-project --prefer-dist laravel/laravel .
print_success "Laravelプロジェクトを作成しました"

# プロジェクトの再配置
print_header "プロジェクトの再配置"

# コンテナを停止
print_info "コンテナを停止しています..."
docker compose down
print_success "コンテナを停止しました"

# プロジェクトルートの.editorconfigと.envを削除
print_info "プロジェクトルートの.editorconfigと.envを削除しています..."
rm -f .editorconfig .env
print_success "プロジェクトルートの.editorconfigと.envを削除しました"

# srcの中身をプロジェクト直下に移動（ホスト側で実行）
print_info "Laravelプロジェクトをプロジェクト直下に移動しています..."
shopt -s dotglob
for item in src/*; do
    if [ -e "$item" ]; then
        mv "$item" ./ 2>/dev/null || true
    fi
done
shopt -u dotglob
print_success "Laravelプロジェクトを移動しました"

# .editorconfigにMakefileの設定を追記、compose.yamlのindent_sizeを修正
print_info ".editorconfigを編集しています..."
# compose.yamlのindent_sizeを4から2に変更
sed -i.bak "/\[compose\.yaml\]/,/^$/ s/^indent_size = 4$/indent_size = 2/" .editorconfig
rm -f .editorconfig.bak

# Makefileセクションを追加
cat >> .editorconfig << "EOF"

[Makefile]
indent_style = tab
EOF
print_success ".editorconfigを編集しました"

# srcディレクトリを削除
print_info "srcディレクトリを削除しています..."
rm -rf src
print_success "srcディレクトリを削除しました"

# .env.exampleから.envを生成
print_info ".env.exampleから.envを生成しています..."
cp .env.example .env
print_success ".envを生成しました"

# .envにDocker設定とOctane設定を追加
print_info ".envにDocker設定とOctane設定を追加しています..."
cat >> .env << EOF

# Docker / Traefik settings
UID=$USER_ID
GID=$GROUP_ID
SERVICE_NAME=$SERVICE_NAME
CONTAINER_NAME=$CONTAINER_NAME
APP_HOST=$APP_HOST

# FrankenPHP / Octane settings
OCTANE_SERVER=frankenphp
OCTANE_WORKERS=$OCTANE_WORKERS
OCTANE_MAX_REQUESTS=$OCTANE_MAX_REQUESTS
EOF
print_success ".envにDocker設定とOctane設定を追加しました"

# .env.exampleにDocker設定とOctane設定を追加（UIDとGIDはデフォルト値）
print_info ".env.exampleにDocker設定とOctane設定を追加しています..."
cat >> .env.example << EOF

# Docker / Traefik settings
UID=1000
GID=1000
SERVICE_NAME=$SERVICE_NAME
CONTAINER_NAME=$CONTAINER_NAME
APP_HOST=$APP_HOST

# FrankenPHP / Octane settings
OCTANE_SERVER=frankenphp
OCTANE_WORKERS=$OCTANE_WORKERS
OCTANE_MAX_REQUESTS=$OCTANE_MAX_REQUESTS
EOF
print_success ".env.exampleにDocker設定とOctane設定を追加しました"

# compose.yamlのマウント設定を修正
print_info "compose.yamlのマウント設定を修正しています..."
sed -i.bak "s|source: ./src|source: .|" compose.yaml
rm -f compose.yaml.bak
print_success "compose.yamlのマウント設定を修正しました"

# コンテナを再起動
print_info "コンテナを再起動しています..."
docker compose up -d
sleep 3
print_success "コンテナを再起動しました"

# アプリケーションキーの生成
print_info "アプリケーションキーを生成しています..."
docker compose exec "$CONTAINER_NAME" php artisan key:generate
print_success "アプリケーションキーを生成しました"

# ストレージリンクの作成
print_info "ストレージリンクを作成しています..."
docker compose exec "$CONTAINER_NAME" php artisan storage:link
print_success "ストレージリンクを作成しました"

# パーミッションの設定
print_info "パーミッションを設定しています..."
docker compose exec "$CONTAINER_NAME" chmod -R 777 storage bootstrap/cache
print_success "パーミッションを設定しました"

# Laravel Octaneのインストール
print_header "Laravel Octaneのインストール"
docker compose exec "$CONTAINER_NAME" composer require laravel/octane
print_success "Laravel Octaneをインストールしました"

# FrankenPHPでOctaneを設定
print_info "FrankenPHPでOctaneを設定しています..."
docker compose exec "$CONTAINER_NAME" php artisan octane:install --server=frankenphp
print_success "Octaneを設定しました"

# 推奨パッケージのインストール
if [[ $INSTALL_PACKAGES =~ ^[Yy]$ ]]; then
    echo ""
    print_header "推奨パッケージのインストール"

    print_info "doctrine/dbal をインストールしています..."
    docker compose exec "$CONTAINER_NAME" composer require doctrine/dbal

    print_info "Laravel IDE Helper をインストールしています..."
    docker compose exec "$CONTAINER_NAME" composer require --dev barryvdh/laravel-ide-helper
    docker compose exec "$CONTAINER_NAME" php artisan ide-helper:generate
    docker compose exec "$CONTAINER_NAME" php artisan ide-helper:meta

    print_info "Laravel Debugbar をインストールしています..."
    docker compose exec "$CONTAINER_NAME" composer require --dev barryvdh/laravel-debugbar
    docker compose exec "$CONTAINER_NAME" php artisan vendor:publish --provider="Barryvdh\Debugbar\ServiceProvider"

    print_info "Laravel Pint をインストールしています..."
    docker compose exec "$CONTAINER_NAME" composer require laravel/pint --dev
    # composer.jsonにpintスクリプトを追加（ホスト側で実行）
    if command -v jq &> /dev/null; then
        cp composer.json composer.json.tmp
        jq --indent 4 '.scripts |= .+{"pint": "./vendor/bin/pint -v", "check-pint": "./vendor/bin/pint --test"}' composer.json.tmp > composer.json
        rm -f composer.json.tmp
        print_success "composer.jsonにpintスクリプトを追加しました"
    else
        print_warning "jqがインストールされていないため、composer.jsonへのスクリプト追加をスキップしました"
    fi

    print_info "Larastan をインストールしています..."
    docker compose exec "$CONTAINER_NAME" composer require --dev "larastan/larastan:^3.0"
    # composer.jsonにphpstanスクリプトを追加（ホスト側で実行）
    if command -v jq &> /dev/null; then
        cp composer.json composer.json.tmp
        jq --indent 4 '.scripts |= .+{"phpstan": "./vendor/bin/phpstan analyse --xdebug"}' composer.json.tmp > composer.json
        rm -f composer.json.tmp
        print_success "composer.jsonにphpstanスクリプトを追加しました"
    else
        print_warning "jqがインストールされていないため、composer.jsonへのスクリプト追加をスキップしました"
    fi

    print_success "推奨パッケージをインストールしました"
fi

# 完了メッセージ
print_header "セットアップ完了!"
echo ""
print_success "FrankenPHPとOctaneを使用したLaravelプロジェクトのセットアップが完了しました!"
echo ""
print_info "プロジェクト詳細:"
echo "  - サービス名: $SERVICE_NAME"
echo "  - Web URL: $APP_HOST"
echo "  - 環境: local (Xdebug有効)"
echo ""
print_info "便利なコマンド:"
echo "  - ログ表示:           make logs"
echo "  - コンテナにアクセス: make $CONTAINER_NAME"
echo "  - コンテナ停止:       make down"
echo "  - コンテナ再起動:     make restart"
echo ""
print_info "Laravel Octane コマンド:"
echo "  - Octane起動:     make octane-start"
echo "  - Octane停止:     make octane-stop"
echo "  - Octane再読込:   make octane-reload"
echo "  - Octane状態確認: make octane-status"
echo "  - 監視モード:     make octane-watch"
echo ""
print_info "アプリケーションへのアクセス:"
echo "  - Traefik経由: https://$APP_HOST"
echo ""
print_warning "注意: Traefikが起動していることを確認してください"
echo ""
