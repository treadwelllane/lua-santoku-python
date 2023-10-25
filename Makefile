export LUA := $(shell luarocks config lua_interpreter)
export LUA_PATH := $(shell luarocks path --lr-path);?.lua
export LUA_CPATH := $(shell luarocks path --lr-cpath)

all:
	luarocks make $(MAKEFLAGS:--%=%)

test: all
	luarocks test $(MAKEFLAGS:--%=%)

iterate:
	@while true; do \
		luarocks make $(MAKEFLAGS:--%=%); \
		luarocks test $(MAKEFLAGS:--%=%); \
		inotifywait -qqr -e close_write -e create -e delete \
			src test Makefile luarocks.mk *.rockspec; \
	done

.PHONY: all test iterate
