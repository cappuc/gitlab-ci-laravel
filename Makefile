IMAGE := cappuc/gitlab-ci-laravel

all: build push

build: php74 php73 php80-rc

push: push-php74 push-php73 push-php80-rc

php80-rc:
	docker build -t ${IMAGE}:php8.0-rc -f php80-rc.Dockerfile .

php74:
	docker build -t ${IMAGE}:php7.4 -t ${IMAGE}:latest -f php74.Dockerfile .

php73:
	docker build -t ${IMAGE}:php7.3 -f php73.Dockerfile .

push-php80-rc:
	docker push ${IMAGE}:php8.0

push-php74:
	docker push ${IMAGE}:php7.4
	docker push ${IMAGE}:latest

push-php73:
	docker push ${IMAGE}:php7.3