local env = {

  name = "santoku-python",
  version = "0.0.38-1",
  variable_prefix = "TK_PYTHON",
  license = "MIT",
  public = true,

  dependencies = {
    "lua >= 5.1",
  },

  test = {
    env_scripts = { "test/deps/venv/venv/bin/activate" },
    dependencies = {
      "santoku >= 0.0.211-1",
      "luacov >= 0.15.0-1",
    }
  },

}

env.homepage = "https://github.com/treadwelllane/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return {
  type = "lib",
  env = env
}
