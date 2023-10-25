all:
	$(MAKE) -C deps
	$(MAKE) -C src

test:
	@rm -f luacov.stats.out || true
	@source deps/python/venv/bin/activate && \
		$(LUA) -l luacov test/run.lua
	@luacheck --config test/luacheck.lua src test/spec || true
	@luacov -c test/luacov.lua || true
	@cat luacov.report.out | awk '/^Summary/ { P = NR } P && NR > P + 1'

install: all
	$(MAKE) -C src install

.PHONY: all test install
