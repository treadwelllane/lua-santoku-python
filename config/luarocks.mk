all: deps/python/env.mk lua.env
	@$(MAKE) -E "include ../$<" -C src

test:
	@rm -f luacov.stats.out || true
	@echo
	@. ./lua.env && $(LUA) -l luacov test/run.lua
	@luacheck --config test/luacheck.lua src test/spec || true
	@luacov -c test/luacov.lua || true
	@cat luacov.report.out | awk '/^Summary/ { P = NR } P && NR > P + 1'
	@echo

install: all
	@$(MAKE) -C src install

lua.env:
	@echo export LUA="$(LUA)" > lua.env

deps/python/env.mk:
	@$(MAKE) -C deps

.PHONY: all test install
