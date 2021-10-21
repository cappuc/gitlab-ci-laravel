IMAGE := cappuc/gitlab-ci-laravel

all: build push

build: php74 php73 php80 php81

push: push-php74 push-php73 push-php80 push-php81

php81:
	docker build -t ${IMAGE}:php8.1 -f php81.Dockerfile .

php80:
	docker build -t ${IMAGE}:php8.0 -f php80.Dockerfile .

php74:
	docker build -t ${IMAGE}:php7.4 -t ${IMAGE}:latest -f php74.Dockerfile .

php73:
	docker build -t ${IMAGE}:php7.3 -f php73.Dockerfile .

push-php81:
	docker push ${IMAGE}:php8.1

push-php80:
	docker push ${IMAGE}:php8.0
	docker push ${IMAGE}:latest

push-php74:
	docker push ${IMAGE}:php7.4

push-php73:
	docker push ${IMAGE}:php7.3