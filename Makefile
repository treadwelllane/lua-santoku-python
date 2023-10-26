NAME = santoku-python
VERSION = 0.0.1-1

ifndef $(ENV)
ENV = default
endif

ROOT_DIR = $(PWD)
BUILD_DIR = $(ROOT_DIR)/.build/$(ENV)

TARBALL = $(TARBALL_DIR).tar.gz
TARBALL_DIR = $(NAME)-$(VERSION)
TARBALL_SRCS = Makefile $(shell find src deps res -type f 2>/dev/null)

all:
	@echo "Running all"
	cd $(BUILD_DIR) && $(LUAROCKS) make

test: all
	@echo "Running test"
	cd $(BUILD_DIR) && $(LUAROCKS) test

iterate:
	@echo "Running iterate"
	@while true; do \
		$(MAKE) test; \
		inotifywait -qqr -e close_write -e create -e delete *; \
	done

clean:
	@echo "Cleaning $(BUILD_DIR)"
	rm -rf "$(BUILD_DIR)"

upload:
	rm -f $(BUILD_DIR)/$(TARBALL) || true
	cd $(BUILD_DIR) && tar --transform 's#^#$(TARBALL_DIR)/#' -czvf $(TARBALL) $(TARBALL_SRCS)

include $(BUILD_DIR)/env.mk
-include $(shell find $(BUILD_DIR) -path "*/deps" -prune -o -name "*.d" -print 2>/dev/null)

$(BUILD_DIR)/env.mk: $(shell find src res config deps -type f 2>/dev/null)
	$(MAKE) -f config/setup.mk

.PHONY: all test iterate upload
