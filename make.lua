local env = {

  name = "santoku-python",
  version = "0.0.34-1",
  variable_prefix = "TK_PYTHON",
  license = "MIT",
  public = true,

  dependencies = {
    "lua >= 5.1",
  },

  test = {
    env_scripts = { "test/deps/venv/venv/bin/activate" },
    dependencies = {
      "santoku >= 0.0.151-1",
      "santoku-test >= 0.0.4-1",
      "luacov >= 0.15.0-1",
      "luassert >= 1.9.0-1",
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
