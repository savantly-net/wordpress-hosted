PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BASE_IMAGE := "savantly/wordpress"
BASE_TAG := "6.6.1-apache"

VERSION := $(shell cat VERSION)
TAGGED_VERSION := $(VERSION)
NEXT_VERSION := $(shell echo $(VERSION) | awk -F. '{$$NF = $$NF + 1;} 1' | sed 's/ /./g')

IMAGE_NAME := "savantly/my-wordpress"
IMAGE_TAG := "$(IMAGE_NAME):$(BASE_TAG)-$(TAGGED_VERSION)"

GIT_COMMIT := $(shell git rev-parse --short HEAD)

IMAGE_TAG_LATEST := "$(IMAGE_NAME):$(BASE_TAG)"

K8S_NAMESPACE := 'default'
K8S_DEPLOYMENT := 'wordpress'

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
	kubectl cp $(K8S_NAMESPACE)/$$POD_NAME:/var/www/html/wp-content/plugins $(PROJECT_DIR)/plugins/ && \
	kubectl cp $(K8S_NAMESPACE)/$$POD_NAME:/var/www/html/wp-content/themes $(PROJECT_DIR)/themes/	