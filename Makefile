DOCKER_IMAGE=localhost/bind9:latest

build:
	@wait-for-docker
	@chmod +x rootfs/docker-entrypoint.d/*.envsh || true
	@chmod +x rootfs/docker-entrypoint.d/*.sh || true
	@docker build -f "Dockerfile" -t "${DOCKER_IMAGE}" "."

push:
	@docker push "${DOCKER_IMAGE}"

run:
	@docker run --rm -it "${DOCKER_IMAGE}"
