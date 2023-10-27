ifndef $(ENV)
ENV = default
endif

export ROOT_DIR = $(PWD)
export BUILD_DIR = $(ROOT_DIR)/.build/$(ENV)
export TOKU_TEMPLATE = toku template -M -c config/toku-template.lua

include $(BUILD_DIR)/init.mk

TARBALL = $(TARBALL_DIR).tar.gz
TARBALL_DIR = $(NAME)-$(VERSION)
TARBALL_SRCS = Makefile $(shell find src deps res -type f 2>/dev/null)

all:
	@echo "Running all"
	cd $(BUILD_DIR) && $(LUAROCKS) make $(ROCKSPEC)

test: all
	@echo "Running test"
	cd $(BUILD_DIR) && $(LUAROCKS) test $(ROCKSPEC)

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
	@if test -z "$(LUAROCKS_API_KEY)"; then echo "Missing LUAROCKS_API_KEY variable"; exit 1; fi
	@if ! git diff --quiet; then echo "Commit your changes first"; exit 1; fi
	@git tag "$(VERSION)"
	@git push --tags
	@git push
	@rm -f $(BUILD_DIR)/$(TARBALL) || true
	@cd $(BUILD_DIR) && tar --transform 's#^#$(TARBALL_DIR)/#' -czvf $(TARBALL) $(TARBALL_SRCS)
	@gh release create $(VERSION) $(BUILD_DIR)/$(TARBALL)
	@luarocks upload --skip-pack --api-key "$(LUAROCKS_API_KEY)" "$(ROCKSPEC)"

$(BUILD_DIR)/init.mk: config/init.mk config/toku-template.lua
	@echo "Templating '$<' -> '$@'"
	$(TOKU_TEMPLATE) -f "$<" -o "$@"

$(BUILD_DIR)/env.mk: $(shell find src res config deps -type f 2>/dev/null) config/toku-template.lua
	$(MAKE) -f config/setup.mk

include $(BUILD_DIR)/env.mk
-include $(shell find $(BUILD_DIR) -path "*/deps" -prune -o -name "*.d" -print 2>/dev/null)

.PHONY: all test iterate upload
