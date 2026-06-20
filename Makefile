# ============================================================
#  KENZORF — Makefile (raccourcis dev)
#    API .NET · back-office Angular · marketplace Flutter · Docker
#    Surcharge : make <cible> VAR=valeur   (⚠️ valeurs SANS chevrons < >)
# ============================================================

API_DIR     := api
FRONT_DIR   := back-office
FLUTTER_DIR := marketplace

# Node 22 requis pour Angular 22 (shell par défaut = Node 20)
NODE22      := export PATH="$$HOME/.nvm/versions/node/v22.22.3/bin:$$PATH";

# --- iOS / iPhone -------------------------------------------------
# UDID de l'iPhone (voir `make devices`) :
DEVICE       ?=
# URL de l'API vue par le téléphone. iPhone PHYSIQUE = IP LAN du Mac (pas localhost) :
#   make build-ios API_BASE_URL=http://192.168.1.57:8080/api
API_BASE_URL ?= http://localhost:8080/api
RUNNER_APP   := $(FLUTTER_DIR)/build/ios/iphoneos/Runner.app

# Contourne un ~/.pub-cache cassé (symlink vers un volume externe non monté) :
# si ~/.pub-cache est absent/lien mort, on bascule sur un cache local au repo.
PUB_CACHE_LOCAL := $(CURDIR)/.pub-cache-local
FLUTTER_ENV     := $(shell [ -e "$$HOME/.pub-cache" ] || echo PUB_CACHE=$(PUB_CACHE_LOCAL))

# Ports que KENZORF doit occuper sur cette machine (libérés au lancement)
KENZORF_PORTS   ?= 8080 4200 5432

.DEFAULT_GOAL := help

.PHONY: help
help:  ## Affiche les cibles disponibles
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	 awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

# --- Ports / multi-projets ----------------------------------------
.PHONY: free-ports
free-ports:  ## Libère les ports KENZORF (stoppe conteneurs/process qui les occupent)
	@bash scripts/free-ports.sh $(KENZORF_PORTS)

# --- API .NET -----------------------------------------------------
.PHONY: api migrate
api:  ## Lance l'API .NET — http://localhost:8080 (libère d'abord le port 8080)
	@bash scripts/free-ports.sh 8080
	cd $(API_DIR) && dotnet run --project src/KENZORF.Api

migrate:  ## Applique les migrations EF Core
	cd $(API_DIR) && dotnet ef database update \
	  --project src/KENZORF.Infrastructure --startup-project src/KENZORF.Api

# --- Back-office Angular ------------------------------------------
.PHONY: front front-build
front:  ## Lance le back-office Angular — http://localhost:4200 (libère d'abord le port 4200)
	@bash scripts/free-ports.sh 4200
	$(NODE22) cd $(FRONT_DIR) && npm start

front-build:  ## Build prod du back-office
	$(NODE22) cd $(FRONT_DIR) && npm run build

# --- Marketplace Flutter (iOS sur iPhone physique) ----------------
.PHONY: ip devices build-ios install-ios deploy-ios run-ios
ip:  ## Affiche l'IP LAN du Mac (à mettre dans API_BASE_URL pour l'iPhone)
	@ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "IP LAN introuvable (vérifie le Wi-Fi)"

devices:  ## Liste les appareils connectés (récupère l'UDID de l'iPhone)
	xcrun devicectl list devices

build-ios:  ## Build l'app iOS release signée (API_BASE_URL=http://<IP_Mac>:8080/api pour un device)
	cd $(FLUTTER_DIR) && $(FLUTTER_ENV) flutter build ios --release --dart-define=API_BASE_URL=$(API_BASE_URL)

install-ios:  ## Installe le Runner.app sur l'iPhone (requiert DEVICE=UDID, sans chevrons)
	@test -n "$(DEVICE)" || { echo "❌ DEVICE manquant : make install-ios DEVICE=<colle-ton-UDID-sans-chevrons>  (voir 'make devices')"; exit 1; }
	xcrun devicectl device install app --device $(DEVICE) $(RUNNER_APP)

deploy-ios: build-ios install-ios  ## Build + installe sur l'iPhone (DEVICE=UDID [API_BASE_URL=http://IP:8080/api])

run-ios:  ## Build + run + hot reload sur l'iPhone (DEVICE=UDID)
	cd $(FLUTTER_DIR) && $(FLUTTER_ENV) flutter run --release -d $(DEVICE) --dart-define=API_BASE_URL=$(API_BASE_URL)

# --- Docker -------------------------------------------------------
.PHONY: up down logs
up: free-ports  ## Lance la stack Docker (libère d'abord 8080/4200/5432) — Postgres + API + back-office
	@test -f .env || { cp .env.example .env && echo "ℹ️  .env créé depuis .env.example (adapte les secrets avant la prod)"; }
	docker compose up --build

down:  ## Arrête la stack docker KENZORF
	docker compose down

logs:  ## Suit les logs docker
	docker compose logs -f

# --- Tests --------------------------------------------------------
.PHONY: test-front test-flutter
test-front:  ## Tests back-office (Vitest)
	$(NODE22) cd $(FRONT_DIR) && npm test

test-flutter:  ## Tests Flutter (unit + widget)
	cd $(FLUTTER_DIR) && $(FLUTTER_ENV) flutter test
