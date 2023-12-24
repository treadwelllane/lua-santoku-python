ifneq ($(<% return variable_prefix %>_LOCAL_PYTHON),1)

ifndef <% return variable_prefix %>_PC_NAME
<% return variable_prefix %>_PC_NAME = python3-embed
endif

results.mk: Makefile
	truncate -s0 results.mk
	echo "LIB_CFLAGS += $(shell pkg-config --cflags $(<% return variable_prefix %>_PC_NAME))" >> results.mk
	echo "LIB_LDFLAGS += $(shell pkg-config --libs $(<% return variable_prefix %>_PC_NAME))" >> results.mk

else

LIB = libpython3.11.so
PRELOAD = LD_PRELOAD=$(CURDIR)/cpython/$(LIB)

export PYTHON = $(PRELOAD) $(CURDIR)/cpython/python
export PIP = $(PRELOAD) $(CURDIR)/venv/bin/pip

results.mk: Makefile cpython/$(LIB)
	truncate -s0 results.mk
	echo "LIB_CFLAGS += -I$(CURDIR)/cpython -I$(CURDIR)/cpython/Include" >> results.mk
	echo "LIB_LDFLAGS += -L$(CURDIR)/cpython -lpython3.11" >> results.mk

cpython/$(LIB):
	[ ! -d cpython ] && \
		git clone https://github.com/python/cpython --depth 1 --branch 3.11 || true
	cd cpython && ./configure --enable-shared --with-address-sanitizer --with-pydebug
	cd cpython && make -s -j2

endif

.PHONY: all
