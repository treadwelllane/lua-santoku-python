ifndef $(ENV)
ENV = default
endif

export ROOT_DIR = $(PWD)
export BUILD_DIR = $(ROOT_DIR)/.build/$(ENV)
export TOKU_TEMPLATE = toku template -M -c config/toku-template.lua

include $(BUILD_DIR)/init.mk

SRC = $(shell find src -type f 2>/dev/null)
TEST = $(shell find test -type f 2>/dev/null)
RES = $(shell find res -type f 2>/dev/null)
DEPS = $(shell find deps -type f 2>/dev/null)

LUAROCKS = luarocks --tree $(BUILD_DIR)/lua_modules
LUAROCKS_MK = $(BUILD_DIR)/Makefile

CONFIG_DEPS = $(lastword $(MAKEFILE_LIST))
CONFIG_DEPS += $(ROCKSPEC) $(LUAROCKS_MK)
CONFIG_DEPS += $(addprefix $(BUILD_DIR)/, $(SRC) $(TEST) $(RES) $(DEPS))

TARBALL = $(TARBALL_DIR).tar.gz
TARBALL_DIR = $(NAME)-$(VERSION)
TARBALL_SRCS = Makefile $(shell find src deps res -type f 2>/dev/null)

all: $(CONFIG_DEPS)
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
	find $(BUILD_DIR)/* -maxdepth 1 -name deps -prune -o -print | xargs rm -rf

clean-all:
	@echo "Cleaning $(BUILD_DIR)"
	rm -rf "$(BUILD_DIR)"

upload: all
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
	@LUAROCKS="$(LUAROCKS)" \
	LUA="$(shell $(LUAROCKS) config lua_interpreter)" \
	LUA_PATH="$(shell $(LUAROCKS) path --lr-path);?.lua" \
	LUA_CPATH="$(shell $(LUAROCKS) path --lr-cpath)" \
		$(TOKU_TEMPLATE) -f "$<" -o "$@"

$(ROCKSPEC): config/template.rockspec $(BUILD_DIR)/init.mk
	@echo "Templating '$<' -> '$@'"
	@$(TOKU_TEMPLATE) -f "$<" -o "$@"

$(LUAROCKS_MK): config/luarocks.mk $(BUILD_DIR)/init.mk
	@echo "Templating '$<' -> '$@'"
	@$(TOKU_TEMPLATE) -f "$<" -o "$@"

$(BUILD_DIR)/%: %
	@if [ "$<" = "$${$^#res}" ]; then \
		echo "Templating '$<' -> '$@'"; \
		$(TOKU_TEMPLATE) -f "$<" -o "$@"; \
	else \
		echo "Copying '$<' -> '$@'"; \
		mkdir -p "$(dir $@)"; \
		cp "$<" "$@"; \
	fi

-include $(shell find $(BUILD_DIR) -path "*/deps" -prune -o -name "*.d" -print 2>/dev/null)

.PHONY: all test iterate clean clean-all upload
