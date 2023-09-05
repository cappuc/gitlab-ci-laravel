IMAGE := cappuc/gitlab-ci-laravel

all: build push

build: php80 php81 php82

push: push-php80 push-php81 push-php82

php82:
	docker build -t ${IMAGE}:php8.2 -f php82.Dockerfile .

php81:
	docker build -t ${IMAGE}:php8.1 -f php81.Dockerfile .

php80:
	docker build -t ${IMAGE}:php8.0 -f php80.Dockerfile .

push-php82:
	docker push ${IMAGE}:php8.2

push-php81:
	docker push ${IMAGE}:php8.1

push-php80:
	docker push ${IMAGE}:php8.0
