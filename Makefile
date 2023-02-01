DOCKER_IMAGE=localhost/bind9:latest

build:
	@docker build --rm -f "Dockerfile" -t "${DOCKER_IMAGE}" "."

run:
	@docker run --rm -it "${DOCKER_IMAGE}"
