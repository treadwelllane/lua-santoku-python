package = "santoku-python"
version = "0.0.1-1"
rockspec_format = "3.0"

source = {
  url = "git+ssh://git@github.com:treadwelllane/lua-santoku-python.git",
  tag = version
}

description = {
  homepage = "https://github.com/treadwelllane/lua-santoku-python",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1",
  "santoku >= 0.0.90-1",
}

test_dependencies = {
  "luafilesystem >= 1.8.0-1",
  "luassert >= 1.9.0-1",
  "luacov >= 0.15.0",
}

build = {
  type = "make",
  makefile = "luarocks.mk",
  variables = {
    CC = "$(CC)",
    CFLAGS = "$(CFLAGS)",
    LIBFLAG = "$(LIBFLAG)",
    LIB_EXTENSION = "$(LIB_EXTENSION)",
  },
  install_variables = {
    INST_LIBDIR = "$(LIBDIR)",
    INST_LUADIR = "$(LUADIR)"
  }
}

test = {
  type = "command",
  command = "make -f luarocks.mk test",
}
