LUAROCKS = luarocks --tree $(BUILD_DIR)/lua_modules
TOKU_TEMPLATE = toku template -M -c config/toku-template.lua

SRC = $(shell find src -type f 2>/dev/null)
TEST = $(shell find test -type f 2>/dev/null)
RES = $(shell find res -type f 2>/dev/null)
DEPS = $(shell find deps -type f 2>/dev/null)

ROCKSPEC = $(BUILD_DIR)/$(NAME)-$(VERSION).rockspec
LUAROCKS_MK = $(BUILD_DIR)/Makefile

CONFIG_DEPS = $(lastword $(MAKEFILE_LIST))
CONFIG_DEPS += $(ROCKSPEC) $(LUAROCKS_MK)
CONFIG_DEPS += $(addprefix $(BUILD_DIR)/, $(SRC) $(TEST) $(RES) $(DEPS))

$(BUILD_DIR)/env.mk: config/env.mk $(CONFIG_DEPS)
	@echo "Templating '$<' -> '$@'"
	@LUAROCKS="$(LUAROCKS)" \
	LUA="$(shell $(LUAROCKS) config lua_interpreter)" \
	LUA_PATH="$(shell $(LUAROCKS) path --lr-path);?.lua" \
	LUA_CPATH="$(shell $(LUAROCKS) path --lr-cpath)" \
	ROCKSPEC="$(ROCKSPEC)" \
		$(TOKU_TEMPLATE) -f "$<" -o "$@"

$(BUILD_DIR)/%: %
	@if [ "$<" = "$${$^#res}" ]; then \
		echo "Templating '$<' -> '$@'"; \
		$(TOKU_TEMPLATE) -f "$<" -o "$@"; \
	else \
		echo "Copying '$<' -> '$@'"; \
		mkdir -p "$(dir $@)"; \
		cp "$<" "$@"; \
	fi

$(ROCKSPEC): config/template.rockspec
	@echo "Templating '$<' -> '$@'"
	@$(TOKU_TEMPLATE) -f "$<" -o "$@"

$(LUAROCKS_MK): config/luarocks.mk
	@echo "Templating '$<' -> '$@'"
	@$(TOKU_TEMPLATE) -f "$<" -o "$@"
