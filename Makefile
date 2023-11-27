IMAGE := cappuc/gitlab-ci-laravel

all: build

build: php81 php82 php83

php83:
	docker buildx build --platform "linux/amd64,linux/arm64" --push -t ${IMAGE}:php8.3 -f php83.Dockerfile .

php82:
	docker buildx build --platform "linux/amd64,linux/arm64" --push -t ${IMAGE}:php8.2 -f php82.Dockerfile .

php81:
	docker buildx build --platform "linux/amd64,linux/arm64" --push -t ${IMAGE}:php8.1 -f php81.Dockerfile .
