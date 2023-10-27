ifndef $(VPFX)_LOCAL_PYTHON

all: env.mk

env.mk:
	truncate -s0 env.mk
	echo "PYTHON_CFLAGS = $(pkg-config --cflags python3)" >> env.mk
	echo "PYTHON_LDFLAGS = $(pkg-config --libs python3)" >> env.mk

else

LIB = libpython3.11.so
PRELOAD = LD_PRELOAD=$(CURDIR)/cpython/$(LIB)

export PYTHON = $(PRELOAD) $(CURDIR)/cpython/python
export PIP = $(PRELOAD) $(CURDIR)/venv/bin/pip

all: cpython/$(LIB) env.mk

cpython/$(LIB):
	[ ! -d cpython ] && \
		git clone https://github.com/python/cpython --depth 1 --branch 3.11 || true
	cd cpython && ./configure --enable-shared
	cd cpython && make -s -j2

env.mk:
	truncate -s0 env.mk
	echo "PYTHON_CFLAGS = -I$(CURDIR)/cpython -I$(CURDIR)/cpython/Include" >> env.mk
	echo "PYTHON_LDFLAGS = -L$(CURDIR)/cpython -lpython3.11" >> env.mk

endif

.PHONY: all
