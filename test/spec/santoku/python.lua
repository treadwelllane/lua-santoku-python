local assert = require("luassert")
local test = require("santoku.test")
local vec = require("santoku.vector")
local py = require("santoku.python")

test("python", function ()

  test("abs", function ()
    local abs = py.builtin("abs")
    local v = abs(-10)
    assert.equals(10, v)
  end)

  test("list", function ()
    local list = py.builtin("list")
    local l = list({ 1, 2, 3, 4 })
    assert.equals(4, l.pop())
    assert.equals(3, l.pop())
    assert.equals(2, l.pop())
    assert.equals(1, l.pop())
  end)

  test("dict", function ()
    local dict = py.builtin("dict")
    local d = dict({ a = 1, b = 2, c = 3 })
    assert.equals(1, d.get("a"))
    assert.equals(2, d.get("b"))
    assert.equals(3, d.get("c"))
  end)

  test("list vec", function ()
    local list = py.builtin("list")
    local l = list(vec(1, 2, 3, 4))
    assert.equals(4, l.pop())
    assert.equals(3, l.pop())
    assert.equals(2, l.pop())
    assert.equals(1, l.pop())
  end)

  test("numpy concat vec", function ()
    local np = py.import("numpy")
    local a = np.array(vec(1, 2))
    local b = np.array(vec(3, 4))
    local c = vec(a, b)
    local d = np.concatenate(c)
    assert.equals(1, d.item(0))
    assert.equals(2, d.item(1))
    assert.equals(3, d.item(2))
    assert.equals(4, d.item(3))
  end)

end)
