# Setup ————————————————————————————————————————————————————————————————————————

# Parameters
SHELL         = bash
HTTP_PORT     = 8000

# Executables
EXEC_PHP      = php
COMPOSER      = composer
REDIS         = redis-cli
GIT           = git
YARN          = yarn
NPX           = npx

# Alias
SYMFONY       = $(EXEC_PHP) bin/console

# Executables: vendors
PHPUNIT       = ./vendor/bin/phpunit
PHPSTAN       = ./vendor/bin/phpstan
PHP_CS_FIXER  = ./vendor/bin/php-cs-fixer
CODESNIFFER   = ./vendor/squizlabs/php_codesniffer/bin/phpcs

# Executables: local only
SYMFONY_BIN   = symfony
BREW          = brew
SPHP          = SPHP

# Misc
.DEFAULT_GOAL = help
.PHONY       =  # Not needed here, but you can put your all your targets to be sure
                # there is no name conflict between your files and your targets.

## —— Symfony Makefile ———————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Composer 🧙‍♂️ ————————————————————————————————————————————————————————————
install: composer.lock ## Install vendors according to the current composer.lock file
	$(COMPOSER) install --no-progress --prefer-dist --optimize-autoloader

update: composer.json ## Update vendors according to the current composer.json file
	$(COMPOSER) update --no-interaction --no-progress --prefer-dist

check: ## Check dependencies
	$(VENDOR_BIN)composer-require-checker check composer.json

## —— PHP 🐘 (macOS with brew) —————————————————————————————————————————————————
php-upgrade: ## Upgrade PHP to the last version
	$(BREW) upgrade

php-set-5-6: ## Set php 5.6 as the current PHP version
	$(SPHP) 5.6

php-set-7-0: ## Set php 7.0 as the current PHP version
	$(SPHP) 7.0

php-set-7-1: ## Set php 7.1 as the current PHP version
	$(SPHP) 7.1

php-set-7-2: ## Set php 7.2 as the current PHP version
	$(SPHP) 7.2

php-set-7-3: ## Set php 7.3 as the current PHP version
	$(SPHP) 7.3

php-set-7-4: ## Set php 7.4 as the current PHP version
	$(SPHP) 7.4

php-set-8-0: ## Set php 8.0 as the current PHP version
	$(SPHP) 8.0

## —— Symfony 🎵 ———————————————————————————————————————————————————————————————
sf: ## List all Symfony commands
	$(SYMFONY)

cc: ## Clear the cache. DID YOU CLEAR YOUR CACHE????
	$(SYMFONY) c:c

warmup: ## Warmup the cache
	$(SYMFONY) cache:warmup

fix-perms: ## Fix permissions of all var files
	chmod -R 777 var/*

start: ## Start the local Symfony web server
	$(SYMFONY) server:start

stop: ## Stop the local Symfony web server
	$(SYMFONY) server:stop

assets: purge ## Install the assets with symlinks in the public folder
	$(SYMFONY) assets:install public/ --symlink --relative

purge: ## Purge cache and logs
	rm -rf var/cache/* var/logs/*
	$(SYMFONY) doctrine:cache:clear-metadata
	$(SYMFONY) doctrine:cache:clear-query
	$(SYMFONY) doctrine:cache:clear-result

## —— Symfony binary 💻 ————————————————————————————————————————————————————————
cert-install: ## Install the local HTTPS certificates
	$(SYMFONY_BIN) server:ca:install

serve: ## Serve the application with HTTPS support
	$(SYMFONY_BIN) serve --daemon --port=$(HTTP_PORT)

unserve: ## Stop the webserver
	$(SYMFONY_BIN) server:stop

## —— Tests ✅ —————————————————————————————————————————————————————————————————
test: phpunit.xml check ## Run main functional and unit tests
	$(eval testsuite ?= 'main') # or "external"
	$(eval filter ?= '.')
	$(PHPUNIT) --testsuite=$(testsuite) --filter=$(filter) --stop-on-failure

test-all: phpunit.xml ## Run all tests
	$(PHPUNIT) --stop-on-failure

## —— Coding standards ✨ ——————————————————————————————————————————————————————
cs: lint-php lint-js ## Run all coding standards checks

static-analysis: stan ## Run the static analysis (PHPStan)

stan: ## Run PHPStan
	$(PHPSTAN) analyse -c configuration/phpstan.neon --memory-limit 1G

lint-php: ## Lint files with php-cs-fixer
	$(PHP_CS_FIXER) fix --dry-run

fix-php: ## Fix files with php-cs-fixer
	$(PHP_CS_FIXER) fix

## —— Yarn 🐱 / JavaScript —————————————————————————————————————————————————————
dev: ## Rebuild assets for the dev env
	$(YARN) install
	$(YARN) run encore dev

watch: ## Watch files and build assets when needed for the dev env
	$(YARN) run encore dev --watch

build: ## Build assets for production
	$(YARN) run encore production

lint-js: ## Lints JS coding standarts
	$(NPX) eslint assets/js

fix-js: ## Fixes JS files
	$(NPX) eslint assets/js --fix

## —— JWT 🕸 ———————————————————————————————————————————————————————————————————
BEARER    = `cat ./config/jwt/bearer.txt`
BASE_URL  = https://127.0.0.1#https://www.strangebuzz.com
PORT      = :8000

jwt-generate-keys: ## Generates the main JWT ket set
	mkdir -p config/jwt
	jwt_passhrase=$$(grep ''^JWT_PASSPHRASE='' .env | cut -f 2 -d ''=''); \
	echo $$jwt_passhrase | openssl genpkey -out config/jwt/private.pem -pass stdin -aes256 -algorithm rsa -pkeyopt rsa_keygen_bits:4096; \
	echo $$jwt_passhrase | openssl pkey -in config/jwt/private.pem -passin stdin -out config/jwt/public.pem -pubout;
	chmod 655 config/jwt/public.pem
	chmod 644 config/jwt/private.pem

jwt-create-ok: ## Create a JWT for a valid test account
	@curl -v -X POST -H "Content-Type: application/json" ${BASE_URL}${PORT}/api/login_check -d '{"username":"reader","password":"test"}'

jwt-create-nok: ## Login attempt with wrong credentials
	@curl -v -X POST -H "Content-Type: application/json" ${BASE_URL}${PORT}/api/login_check -d '{"username":"foo","password":"bar"}'

jwt-test: ./config/jwt/bearer.txt ## Test a JWT token to access an API Platform resource
	@curl -v -X GET -H 'Cache-Control: no-cache' -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER}" ${BASE_URL}${PORT}/api/books/1?1=dsds
