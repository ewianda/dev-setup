test:
	docker build -t test-script .
	docker run --rm test-script
	docker run --rm -it --entrypoint bash -v $(pwd):/home/testuser  test-script
