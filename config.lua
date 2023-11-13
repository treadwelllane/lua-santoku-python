local env = {

  name = "santoku-python",
  version = "0.0.29-1",
  variable_prefix = "TK_PYTHON",
  license = "MIT",
  public = true,

  dependencies = {
    "lua >= 5.1",
    "santoku >= 0.0.119-1",
  },

  test_dependencies = {
    "inspect >= 3.1.3-0",
    "luaposix >= 36.2.1-1",
    "luassert >= 1.9.0-1",
    "luacov >= 0.15.0-1",
  },

}

env.homepage = "https://github.com/treadwelllane/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return { env = env }
