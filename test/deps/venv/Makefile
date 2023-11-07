results.mk:
	python3 -m venv venv
	source venv/bin/activate && \
		pip3 install numpy
	echo "export TEST_ENVS += deps/venv/venv/bin/activate" > "$@"
