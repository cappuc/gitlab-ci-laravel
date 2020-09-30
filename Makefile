IMAGE := cappuc/gitlab-ci-laravel

all: php74 php73

php74:
	docker build -t ${IMAGE}:php7.4 -t ${IMAGE}:latest -f php74.Dockerfile .

php73:
	docker build -t ${IMAGE}:php7.3 -f php73.Dockerfile .