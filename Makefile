DOCKER_IMAGE=localhost/bind9:latest

build:
	@chmod +x rootfs/docker-entrypoint.d/*.envsh || true
	@chmod +x rootfs/docker-entrypoint.d/*.sh || true
	@docker build --rm -f "Dockerfile" -t "${DOCKER_IMAGE}" "."

run:
	@docker run --rm -it "${DOCKER_IMAGE}"
