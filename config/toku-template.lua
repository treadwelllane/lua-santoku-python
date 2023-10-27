local _ENV = {}

name = "santoku-python"
version = "0.0.4-1"
variable_prefix = "TK_PYTHON"

license = "MIT"

dependencies = {
  "lua >= 5.1",
  "santoku >= 0.0.91-1",
}

test_dependencies = {
  "luafilesystem >= 1.8.0-1",
  "luassert >= 1.9.0-1",
  "luacov >= 0.15.0",
}

homepage = "https://github.com/treadwelllane/lua-" .. name
tarball = name .. "-" .. version .. ".tar.gz"
download = homepage .. "/releases/download/" .. version .. "/" .. tarball

return { env = _ENV }