<%
  gen = require("santoku.gen")
  str = require("santoku.string")
  tbl = require("santoku.table")
%>

package = "<% return name %>"
version = "<% return version %>"
rockspec_format = "3.0"

source = {
  url = "<% return download %>",
}

description = {
  homepage = "<% return homepage %>",
  license = "<% return license or 'UNLICENSED' %>"
}

dependencies = {
  <% return gen.ivals(dependencies or {}):map(str.quote):concat(",\n") .. ",\n" %>
  <% template:push(build.istest) %>
  <% if template:showing() then
      return gen.ivals(tbl.get(test, "dependencies") or {}):map(str.quote):concat(",\n")
     end %>
  <% template:pop() %>
}

build = {
  type = "make",
  makefile = "Makefile",
  variables = {
    LIB_EXTENSION = "$(LIB_EXTENSION)",
  },
  build_variables = {
    CC = "$(CC)",
    CFLAGS = "$(CFLAGS)",
    LIBFLAG = "$(LIBFLAG)",
    LUA_BINDIR = "$(LUA_BINDIR)",
    LUA_INCDIR = "$(LUA_INCDIR)",
    LUA_LIBDIR = "$(LUA_LIBDIR)",
    LUA = "$(LUA)",
  },
  install_variables = {
    INST_PREFIX = "$(PREFIX)",
    INST_BINDIR = "$(BINDIR)",
    INST_LIBDIR = "$(LIBDIR)",
    INST_LUADIR = "$(LUADIR)",
    INST_CONFDIR = "$(CONFDIR)",
  }
}
