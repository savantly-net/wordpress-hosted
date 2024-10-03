# Makefile version 1.0

# Load the project configuration
include project.mk


PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BASE_IMAGE := "savantly/wordpress"
BASE_TAG := "6.6.1-php8.1-fpm"

VERSION := $(shell cat VERSION)
TAGGED_VERSION := $(VERSION)
NEXT_VERSION := $(shell echo $(VERSION) | awk -F. '{$$NF = $$NF + 1;} 1' | sed 's/ /./g')

# IMAGE_NAME - from project.mk
IMAGE_TAG := "$(IMAGE_NAME):$(BASE_TAG)-$(TAGGED_VERSION)"

GIT_COMMIT := $(shell git rev-parse --short HEAD)

IMAGE_TAG_LATEST := "$(IMAGE_NAME):$(BASE_TAG)"

# Define a variable to check if Composer is installed
COMPOSER_CHECK := $(shell command -v composer > /dev/null 2>&1 && echo "yes" || echo "no")


.PHONY: setup
setup:
	@echo "Checking for composer..."
	@if [ "$(COMPOSER_CHECK)" = "no" ]; then \
		echo "Composer is not installed. Please install composer and try again."; \
		exit 1; \
	fi
	@echo "Setting up..."
	@command composer require --dev phpstan/phpstan


.PHONY: analyze
analyze:
	@echo "Analyzing..."
	@vendor/bin/phpstan --memory-limit=1024M analyse themes


.PHONY: build
build:
	@echo "Building..."
	@echo "Dont push this image to docker hub, use 'make push' instead"
	@docker build \
	--build-arg="BASE_IMAGE=$(BASE_IMAGE)" \
	--build-arg="BASE_TAG=$(BASE_TAG)" \
	-t $(IMAGE_TAG) -t $(IMAGE_TAG_LATEST) .
	@echo "Done!"

.PHONY: ensure-git-repo-pristine
ensure-git-repo-pristine:
	@echo "Ensuring git repo is pristine"
	@[[ $(shell git status --porcelain=v1 2>/dev/null | wc -l) -gt 0 ]] && echo "Git repo is not pristine" && exit 1 || echo "Git repo is pristine"


.PHONY: bump-version
bump-version:
	@echo "Bumping version to $(NEXT_VERSION)"
	@echo $(NEXT_VERSION) > VERSION
	git add VERSION
	git commit -m "Published $(VERSION) and prepared for $(NEXT_VERSION)"


.PHONY: push
push: ensure-git-repo-pristine 
	@echo "Building..."
	@docker buildx build --platform=linux/amd64,linux/arm64 \
	--build-arg="BASE_IMAGE=$(BASE_IMAGE)" \
	--build-arg="BASE_TAG=$(BASE_TAG)" \
	--push -t $(IMAGE_TAG) -t $(IMAGE_TAG_LATEST) .
	@echo "Done!"


.PHONY: release
release: push bump-version 
	@echo "Preparing release..."
	@echo "Version: $(VERSION)"
	@echo "BASE_IMAGE: $(BASE_IMAGE)"
	@echo "BASE_TAG: $(BASE_TAG)"
	@echo "Commit: $(GIT_COMMIT)"
	@echo "Image Tag: $(IMAGE_TAG)"
	git tag -a $(TAGGED_VERSION) -m "Release $(VERSION)"
	git push origin $(TAGGED_VERSION)
	@echo "Tag $(TAGGED_VERSION) created and pushed to origin"


.PHONY: dev
dev:
	@echo "Running docker compose..."
	docker compose up --build

.PHONY: download-pod
download-pod:
	@echo "Downloading from pod..."
	export POD_NAME=$(shell kubectl get pods -n $(K8S_NAMESPACE) -l app.kubernetes.io/instance=$(K8S_DEPLOYMENT) -o jsonpath='{.items[0].metadata.name}') && \
	kubectl cp $(K8S_NAMESPACE)/$$POD_NAME:/usr/src/wordpress/wp-content/plugins/ $(PROJECT_DIR)/plugins/ && \
	kubectl cp $(K8S_NAMESPACE)/$$POD_NAME:/usr/src/wordpress/wp-content/uploads/ $(PROJECT_DIR)/uploads/ && \
	kubectl cp $(K8S_NAMESPACE)/$$POD_NAME:/usr/src/wordpress/wp-content/themes/ $(PROJECT_DIR)/themes/	


.PHONY: upload-pod
upload-pod:
	@echo "Uploading to pod..."
	export POD_NAME=$(shell kubectl get pods -n $(K8S_NAMESPACE) -l app.kubernetes.io/instance=$(K8S_DEPLOYMENT) -o jsonpath='{.items[0].metadata.name}') && \
	kubectl cp $(PROJECT_DIR)/plugins $(K8S_NAMESPACE)/$$POD_NAME:/usr/src/wordpress/wp-content/ --no-preserve=true && \
	kubectl cp $(PROJECT_DIR)/uploads $(K8S_NAMESPACE)/$$POD_NAME:/usr/src/wordpress/wp-content/ --no-preserve=true && \
	kubectl cp $(PROJECT_DIR)/themes $(K8S_NAMESPACE)/$$POD_NAME:/usr/src/wordpress/wp-content/ --no-preserve=true


.PHONY: upload-pod-themes
upload-pod-themes:
	@echo "Uploading to pod..."
	export POD_NAME=$(shell kubectl get pods -n $(K8S_NAMESPACE) -l app.kubernetes.io/instance=$(K8S_DEPLOYMENT) -o jsonpath='{.items[0].metadata.name}') && \
	kubectl cp $(PROJECT_DIR)/themes $(K8S_NAMESPACE)/$$POD_NAME:/usr/src/wordpress/wp-content/ --no-preserve=true 

.PHONY: pod-shell
pod-shell:
	@echo "Opening shell in pod..."
	export POD_NAME=$(shell kubectl get pods -n $(K8S_NAMESPACE) -l app.kubernetes.io/instance=$(K8S_DEPLOYMENT) -o jsonpath='{.items[0].metadata.name}') && \
	kubectl exec -it $$POD_NAME -n $(K8S_NAMESPACE) -- /bin/bash

.PHONY: pod-logs
pod-logs:
	@echo "Getting logs from pod..."
	export POD_NAME=$(shell kubectl get pods -n $(K8S_NAMESPACE) -l app.kubernetes.io/instance=$(K8S_DEPLOYMENT) -o jsonpath='{.items[0].metadata.name}') && \
	kubectl logs -f $$POD_NAME -n $(K8S_NAMESPACE)

# uses kubectl to get the secret and decode the base64 encoded values
.PHONY: reveal-cicd-creds
reveal-cicd-creds:
	@echo "Revealing cicd creds..."
	@kubectl get secret cicd -n $(K8S_NAMESPACE) -o jsonpath="{.data.AWS_ACCESS_KEY_ID}" | base64 --decode
	@kubectl get secret cicd -n $(K8S_NAMESPACE) -o jsonpath="{.data.AWS_SECRET_ACCESS_KEY}" | base64 --decode
