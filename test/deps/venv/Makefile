results.mk:
	python3 -m venv venv
	source venv/bin/activate && \
		pip3 install numpy
	echo "TEST_PREFIX = source deps/venv/venv/bin/activate &&" > "$@"
