# =============================================================================
# Skilloka - Makefile
# Common development and deployment commands
# =============================================================================

.PHONY: help build up down logs shell migrate fresh seed test lint deploy

# Default target
help:
	@echo "Skilloka Development Commands"
	@echo "=============================="
	@echo ""
	@echo "Development:"
	@echo "  make up         - Start development containers"
	@echo "  make down       - Stop all containers"
	@echo "  make build      - Build Docker images"
	@echo "  make logs       - View container logs"
	@echo "  make shell      - Open shell in backend container"
	@echo ""
	@echo "Database:"
	@echo "  make migrate    - Run database migrations"
	@echo "  make fresh      - Fresh migration with seeders"
	@echo "  make seed       - Run database seeders"
	@echo "  make backup     - Backup database"
	@echo ""
	@echo "Testing:"
	@echo "  make test       - Run all tests"
	@echo "  make lint       - Run code linting"
	@echo "  make analyze    - Run static analysis"
	@echo ""
	@echo "Production:"
	@echo "  make deploy     - Deploy to production"
	@echo "  make rollback   - Rollback deployment"

# =============================================================================
# Development
# =============================================================================

up:
	docker compose up -d
	@echo "✅ Development environment started"
	@echo "📡 API: http://localhost:80"
	@echo "📧 Mail: http://localhost:8025"
	@echo "📊 MinIO: http://localhost:9001"
	@echo "🔍 Search: http://localhost:7700"

down:
	docker compose down

build:
	docker compose build --no-cache

logs:
	docker compose logs -f

shell:
	docker compose exec backend sh

# =============================================================================
# Database
# =============================================================================

migrate:
	docker compose exec backend php artisan migrate

fresh:
	docker compose exec backend php artisan migrate:fresh --seed

seed:
	docker compose exec backend php artisan db:seed

backup:
	./scripts/backup-database.sh

restore:
	@echo "Usage: make restore FILE=<backup_file>"
	./scripts/restore-database.sh $(FILE)

# =============================================================================
# Testing
# =============================================================================

test:
	docker compose exec backend php artisan test

test-coverage:
	docker compose exec backend php artisan test --coverage

lint:
	docker compose exec backend ./vendor/bin/pint

lint-fix:
	docker compose exec backend ./vendor/bin/pint --fix

analyze:
	docker compose exec backend ./vendor/bin/phpstan analyse

# =============================================================================
# Cache Management
# =============================================================================

cache-clear:
	docker compose exec backend php artisan optimize:clear

cache-warm:
	docker compose exec backend php artisan optimize

# =============================================================================
# Queue Management
# =============================================================================

queue-work:
	docker compose exec backend php artisan queue:work

queue-restart:
	docker compose exec backend php artisan horizon:terminate

queue-failed:
	docker compose exec backend php artisan queue:failed

queue-retry:
	docker compose exec backend php artisan queue:retry all

# =============================================================================
# Production
# =============================================================================

deploy:
	./scripts/deploy.sh deploy

rollback:
	./scripts/deploy.sh rollback

health:
	./scripts/deploy.sh health

ssl-renew:
	./scripts/ssl-renew.sh renew

# =============================================================================
# Utilities
# =============================================================================

clean:
	docker system prune -af
	docker volume prune -f

ps:
	docker compose ps

stats:
	docker stats

# Flutter commands
flutter-build:
	flutter build apk --release

flutter-test:
	flutter test
