export NAME = <% return name %>
export VERSION = <% return version %>

export LUAROCKS = <% return os.getenv("LUAROCKS") %>
export LUA = <% return os.getenv("LUA") %>
export LUA_PATH = <% return os.getenv("LUA_PATH") %>
export LUA_CPATH = <% return os.getenv("LUA_CPATH") %>

export ROCKSPEC = $(BUILD_DIR)/$(NAME)-$(VERSION).rockspec
