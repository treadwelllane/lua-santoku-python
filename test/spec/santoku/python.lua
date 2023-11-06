local assert = require("luassert")
local test = require("santoku.test")
local vec = require("santoku.vector")
local py_open = require("santoku.python")
local py

test("python", function ()

  test("open", function ()

    local ok, msg

    ok, py = py_open("libpython3.11.so")
    assert.equals(true, ok, py)

    ok, py, msg = py_open("libpython3.11.so")
    assert.equals(true, ok, py)
    assert.equals(msg, "embedded python already open: libpython3.11.so")

  end)

  test("wrap", function ()
    py({ 1, 2 })
  end)

  test("abs", function ()
    local abs = py.builtin("abs")
    local v = abs(-10)
    assert.equals(10, v)
  end)

  test("list", function ()
    local list = py.builtin("list")
    local l = list({ 1, 2, 3, 4, 5 })
    assert.equals(5, l.pop())
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

  -- test("dict kwargs", function ()
  --   local dict = py.builtin("dict")
  --   local d = dict(py.kwargs({ a = 1, b = 2, c = 3 }))
  --   assert.equals(1, d.get("a"))
  --   assert.equals(2, d.get("b"))
  --   assert.equals(3, d.get("c"))
  -- end)

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
    assert.equals(1, a.item(0))
    assert.equals(2, a.item(1))
    assert.equals(3, b.item(0))
    assert.equals(4, b.item(1))
    local c = vec(a, b)
    assert.equals(a, c:get(1))
    assert.equals(b, c:get(2))
    local d = np.array(c)
    assert.same({ 2, 2 }, { d.shape[0], d.shape[1] })
    assert.equals(1, d.item(0))
    assert.equals(2, d.item(1))
    assert.equals(3, d.item(2))
    assert.equals(4, d.item(3))
    local e = np.concatenate(d)
    assert.same({ 4 }, { e.shape[0] })
    assert.equals(1, e.item(0))
    assert.equals(2, e.item(1))
    assert.equals(3, e.item(2))
    assert.equals(4, e.item(3))
  end)

  test("bytes", function ()

    local str = "abc"
    local bytes = py.bytes(str)
    local str0 = bytes.decode("utf-8")

    assert.equals(str, str0)

  end)

end)

py.collect()
collectgarbage()

-- for k, v in ipairs(py.REF_IDX) do
--   print(k, require("santoku.inspect")(v))
-- end

py.close()
