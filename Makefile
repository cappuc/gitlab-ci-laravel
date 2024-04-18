IMAGE := cappuc/gitlab-ci-laravel

all: build

build: php81 php82 php83

php83:
	docker buildx build --platform "linux/amd64,linux/arm64" --push -f php83.Dockerfile -t ${IMAGE}:php8.3 --target slim .
	docker buildx build --platform "linux/amd64,linux/arm64" --push -f php83.Dockerfile -t ${IMAGE}:php8.3-browsers .

php82:
	docker buildx build --platform "linux/amd64,linux/arm64" --push -f php82.Dockerfile -t ${IMAGE}:php8.2 --target slim .
	docker buildx build --platform "linux/amd64,linux/arm64" --push -f php82.Dockerfile -t ${IMAGE}:php8.2-browsers .

php81:
	docker buildx build --platform "linux/amd64,linux/arm64" --push -f php81.Dockerfile -t ${IMAGE}:php8.1 --target slim .
	docker buildx build --platform "linux/amd64,linux/arm64" --push -f php81.Dockerfile -t ${IMAGE}:php8.1-browsers .
