

include .build/preamble.mk

ifndef $(VPFX)_ENV
export $(VPFX)_ENV = default
endif

ROOT_DIR = $(PWD)
BUILD_DIR = $(ROOT_DIR)/.build/$($(VPFX)_ENV)

TOKU_TEMPLATE = toku template -M -c config.lua
ROCKSPEC = $(BUILD_DIR)/$(NAME)-$(VERSION).rockspec

SRC = $(shell find src -type f 2>/dev/null)
TEST = $(shell find test -type f 2>/dev/null)
RES = $(shell find res -type f 2>/dev/null)
DEPS = $(shell find deps -type f 2>/dev/null)

LUAROCKS = luarocks --tree $(BUILD_DIR)/lua_modules
LUAROCKS_MK = $(BUILD_DIR)/Makefile
SRC_MK = $(BUILD_DIR)/src/Makefile
LUACOV_CFG = $(BUILD_DIR)/test/luacov.lua
LUACHECK_CFG = $(BUILD_DIR)/test/luacheck.lua

PREAMBLE_DATA = TkFNRSA9IDwlIHJldHVybiBuYW1lICU+ClZFUlNJT04gPSA8JSByZXR1cm4gdmVyc2lvbiAlPgpWUEZYID0gPCUgcmV0dXJuIHZhcmlhYmxlX3ByZWZpeCAlPgoKZXhwb3J0IExVQSA9IDwlIHJldHVybiBvcy5nZXRlbnYoIkxVQSIpICU+CmV4cG9ydCBMVUFfUEFUSCA9IDwlIHJldHVybiBvcy5nZXRlbnYoIkxVQV9QQVRIIikgJT4KZXhwb3J0IExVQV9DUEFUSCA9IDwlIHJldHVybiBvcy5nZXRlbnYoIkxVQV9DUEFUSCIpICU+Cg==
ROCKSPEC_DATA = PCUgdmVjID0gcmVxdWlyZSgic2FudG9rdS52ZWN0b3IiKSAlPgo8JSBzdHIgPSByZXF1aXJlKCJzYW50b2t1LnN0cmluZyIpICU+CgpwYWNrYWdlID0gIjwlIHJldHVybiBuYW1lICU+Igp2ZXJzaW9uID0gIjwlIHJldHVybiB2ZXJzaW9uICU+Igpyb2Nrc3BlY19mb3JtYXQgPSAiMy4wIgoKc291cmNlID0gewogIHVybCA9ICI8JSByZXR1cm4gZG93bmxvYWQgJT4iLAp9CgpkZXNjcmlwdGlvbiA9IHsKICBob21lcGFnZSA9ICI8JSByZXR1cm4gaG9tZXBhZ2UgJT4iLAogIGxpY2Vuc2UgPSAiPCUgcmV0dXJuIGxpY2Vuc2UgJT4iCn0KCmRlcGVuZGVuY2llcyA9IHsKICA8JSByZXR1cm4gdmVjLndyYXAoZGVwZW5kZW5jaWVzIG9yIHt9KTptYXAoc3RyLnF1b3RlKTpjb25jYXQoIixcbiIpICU+Cn0KCnRlc3RfZGVwZW5kZW5jaWVzID0gewogIDwlIHJldHVybiB2ZWMud3JhcCh0ZXN0X2RlcGVuZGVuY2llcyBvciB7fSk6bWFwKHN0ci5xdW90ZSk6Y29uY2F0KCIsXG4iKSAlPgp9CgpidWlsZCA9IHsKICB0eXBlID0gIm1ha2UiLAogIHZhcmlhYmxlcyA9IHsKICAgIExJQl9FWFRFTlNJT04gPSAiJChMSUJfRVhURU5TSU9OKSIsCiAgfSwKICBidWlsZF92YXJpYWJsZXMgPSB7CiAgICBDQyA9ICIkKENDKSIsCiAgICBDRkxBR1MgPSAiJChDRkxBR1MpIiwKICAgIExJQkZMQUcgPSAiJChMSUJGTEFHKSIsCiAgICBMVUFfQklORElSID0gIiQoTFVBX0JJTkRJUikiLAogICAgTFVBX0lOQ0RJUiA9ICIkKExVQV9JTkNESVIpIiwKICAgIExVQV9MSUJESVIgPSAiJChMVUFfTElCRElSKSIsCiAgICBMVUEgPSAiJChMVUEpIiwKICB9LAogIGluc3RhbGxfdmFyaWFibGVzID0gewogICAgSU5TVF9QUkVGSVggPSAiJChQUkVGSVgpIiwKICAgIElOU1RfQklORElSID0gIiQoQklORElSKSIsCiAgICBJTlNUX0xJQkRJUiA9ICIkKExJQkRJUikiLAogICAgSU5TVF9MVUFESVIgPSAiJChMVUFESVIpIiwKICAgIElOU1RfQ09ORkRJUiA9ICIkKENPTkZESVIpIiwKICB9Cn0KCnRlc3QgPSB7CiAgdHlwZSA9ICJjb21tYW5kIiwKICBjb21tYW5kID0gIm1ha2UgdGVzdCIKfQo=
LUAROCKS_MK_DATA = ZXhwb3J0IFZQRlggPSA8JSByZXR1cm4gdmFyaWFibGVfcHJlZml4ICU+CgpERVBTX0RJUlMgPSAkKHNoZWxsIGZpbmQgZGVwcy8qIC1tYXhkZXB0aCAxIC10eXBlIGQpCkRFUFNfUkVTVUxUUyA9ICQoYWRkc3VmZml4IC9yZXN1bHRzLm1rLCAkKERFUFNfRElSUykpCgpTUkNfTFVBID0gJChzaGVsbCBmaW5kICogLW5hbWUgJyoubHVhJykKU1JDX0MgPSAkKHNoZWxsIGZpbmQgKiAtbmFtZSAnKi5jJykKU1JDX08gPSAkKFNSQ19DOi5jPS5vKQpTUkNfU08gPSAkKFNSQ19POi5vPS4kKExJQl9FWFRFTlNJT04pKQoKSU5TVF9MVUEgPSAkKGFkZHByZWZpeCAkKElOU1RfTFVBRElSKS8sICQoU1JDX0xVQSkpCklOU1RfU08gPSAkKGFkZHByZWZpeCAkKElOU1RfTElCRElSKS8sICQoU1JDX1NPKSkKCkxJQl9DRkxBR1MgPSAtV2FsbCAkKFBZVEhPTl9DRkxBR1MpIC1JJChMVUFfSU5DRElSKQpMSUJfTERGTEFHUyA9IC1XYWxsICQoUFlUSE9OX0xERkxBR1MpIC1MJChMVUFfTElCRElSKQoKaWZlcSAoJCgkKFZQRlgpX1NBTklUSVpFKSwxKQpMSUJfQ0ZMQUdTICs9IC1mc2FuaXRpemU9YWRkcmVzcyAtZnNhbml0aXplPWxlYWsKTElCX0xERkxBR1MgKz0gLWZzYW5pdGl6ZT1hZGRyZXNzIC1mc2FuaXRpemU9bGVhawplbmRpZgoKaW5jbHVkZSAkKERFUFNfUkVTVUxUUykKCmFsbDogJChERVBTX1JFU1VMVFMpIGx1YS5lbnYKCUAkKE1BS0UpIC1FICJpbmNsdWRlICQoYWRkcHJlZml4IC4uLywgJChERVBTX1JFU1VMVFMpKSIgLUMgc3JjCgp0ZXN0OgoJQHJtIC1mIGx1YWNvdi5zdGF0cy5vdXQgfHwgdHJ1ZQoJQC4gLi9sdWEuZW52ICYmICQoJChWUEZYKV9URVNUX1BSRUZJWCkgdG9rdSB0ZXN0IC1pICIkKExVQSkgLVcgLWwgbHVhY292IiAtLW1hdGNoICJeLiolLmx1YSQkIiB0ZXN0L3NwZWMKCUBlY2hvCglAbHVhY2hlY2sgLS1jb25maWcgdGVzdC9sdWFjaGVjay5sdWEgc3JjIHRlc3Qvc3BlYyB8fCB0cnVlCglAbHVhY292IC1jIHRlc3QvbHVhY292Lmx1YSB8fCB0cnVlCglAY2F0IGx1YWNvdi5yZXBvcnQub3V0IHwgYXdrICcvXlN1bW1hcnkvIHsgUCA9IE5SIH0gUCAmJiBOUiA+IFAgKyAxJwoJQGVjaG8KCmluc3RhbGw6IGFsbAoJQCQoTUFLRSkgLUMgc3JjIGluc3RhbGwKCmx1YS5lbnY6CglAZWNobyBleHBvcnQgTFVBPSIkKExVQSkiID4gbHVhLmVudgoKZGVwcy8lL3Jlc3VsdHMubWs6IGRlcHMvJS9NYWtlZmlsZQoJQCQoTUFLRSkgLUMgIiQoZGlyICRAKSIKCi5QSE9OWTogYWxsIHRlc3QgaW5zdGFsbAo=
SRC_MK_DATA = U1JDX0xVQSA9ICQoc2hlbGwgZmluZCAqIC1uYW1lICcqLmx1YScpClNSQ19DID0gJChzaGVsbCBmaW5kICogLW5hbWUgJyouYycpClNSQ19PID0gJChTUkNfQzouYz0ubykKU1JDX1NPID0gJChTUkNfTzoubz0uJChMSUJfRVhURU5TSU9OKSkKCklOU1RfTFVBID0gJChhZGRwcmVmaXggJChJTlNUX0xVQURJUikvLCAkKFNSQ19MVUEpKQpJTlNUX1NPID0gJChhZGRwcmVmaXggJChJTlNUX0xJQkRJUikvLCAkKFNSQ19TTykpCgpMSUJfQ0ZMQUdTICs9IC1XYWxsIC1JJChMVUFfSU5DRElSKQpMSUJfTERGTEFHUyArPSAtV2FsbCAtTCQoTFVBX0xJQkRJUikKCmlmZXEgKCQoJChWUEZYKV9TQU5JVElaRSksMSkKTElCX0NGTEFHUyArPSAtZnNhbml0aXplPWFkZHJlc3MgLWZzYW5pdGl6ZT1sZWFrCkxJQl9MREZMQUdTICs9IC1mc2FuaXRpemU9YWRkcmVzcyAtZnNhbml0aXplPWxlYWsKZW5kaWYKCmFsbDogJChTUkNfTykgJChTUkNfU08pCgolLm86ICUuYwoJJChDQykgJChMSUJfQ0ZMQUdTKSAkKENGTEFHUykgLWMgLW8gJEAgJDwKCiUuJChMSUJfRVhURU5TSU9OKTogJS5vCgkkKENDKSAkKExJQl9MREZMQUdTKSAkKExERkxBR1MpICQoTElCRkxBRykgLW8gJEAgJDwKCmluc3RhbGw6ICQoSU5TVF9MVUEpICQoSU5TVF9TTykKCiQoSU5TVF9MVUFESVIpLyUubHVhOiAuLyUubHVhCglta2RpciAtcCAkKGRpciAkQCkKCWNwICQ8ICRACgokKElOU1RfTElCRElSKS8lLiQoTElCX0VYVEVOU0lPTik6IC4vJS4kKExJQl9FWFRFTlNJT04pCglta2RpciAtcCAkKGRpciAkQCkKCWNwICQ8ICRACgouUEhPTlk6IGFsbCBpbnN0YWxsCg==
LUACOV_DATA = PCUgdmVjID0gcmVxdWlyZSgic2FudG9rdS52ZWN0b3IiKSAlPgo8JSBzdHIgPSByZXF1aXJlKCJzYW50b2t1LnN0cmluZyIpICU+CgppbmNsdWRlID0gewogIDwlIHJldHVybiB2ZWMud3JhcChsdWFjb3ZfaW5jbHVkZSBvciB7fSk6bWFwKHN0ci5xdW90ZSk6Y29uY2F0KCIsXG4iKSAlPgp9Cg==
LUACHECK_DATA = cXVpZXQgPSAxCnN0ZCA9ICJtaW4iCmlnbm9yZSA9IHsgIjQzKiIgfSAtLSBVcHZhbHVlIHNoYWRvd2luZwpnbG9iYWxzID0geyAibmd4IiwgImppdCIgfQo=

CONFIG_DEPS = $(lastword $(MAKEFILE_LIST))
CONFIG_DEPS += $(ROCKSPEC) $(LUAROCKS_MK) $(SRC_MK) $(LUACOV_CFG) $(LUACHECK_CFG)
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

# NOTE: intentionally not using $(LUAROCKS) here
install: all
	cd $(BUILD_DIR) && luarocks make $(ROCKSPEC)

touch:
	find * -exec touch {} \+

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

.build/preamble.mk: config.lua
	@echo "Templating preamble -> '$@'"
	@LUA="$(shell $(LUAROCKS) config lua_interpreter)" \
	LUA_PATH="$(shell $(LUAROCKS) path --lr-path);?.lua" \
	LUA_CPATH="$(shell $(LUAROCKS) path --lr-cpath)" \
		sh -c 'echo $(PREAMBLE_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(ROCKSPEC): .build/preamble.mk
	@echo "Templating '$<' -> '$@'"
	@sh -c 'echo $(ROCKSPEC_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(LUAROCKS_MK): .build/preamble.mk
	@echo "Templating '$<' -> '$@'"
	@sh -c 'echo $(LUAROCKS_MK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(SRC_MK): .build/preamble.mk
	@echo "Templating '$<' -> '$@'"
	@sh -c 'echo $(SRC_MK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(LUACOV_CFG): .build/preamble.mk
	@echo "Templating '$<' -> '$@'"
	@sh -c 'echo $(LUACOV_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(LUACHECK_CFG): .build/preamble.mk
	@echo "Templating '$<' -> '$@'"
	@sh -c 'echo $(LUACHECK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(BUILD_DIR)/%: %
	@case "$<" in \
		res/*) \
			echo "Copying '$<' -> '$@'"; \
			mkdir -p "$(dir $@)"; \
			cp "$<" "$@";; \
		*) \
			echo "Templating '$<' -> '$@'"; \
			$(TOKU_TEMPLATE) -f "$<" -o "$@";; \
	esac

-include $(shell find $(BUILD_DIR) -regex ".*/deps/.*/.*" -prune -o -name "*.d" -print 2>/dev/null)

.PHONY: all test iterate install touch clean clean-all upload
.DEFAULT_GOAL: all
