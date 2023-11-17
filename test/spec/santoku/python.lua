local assert = require("luassert")
local test = require("santoku.test")
local vec = require("santoku.vector")
local ok, py = require("santoku.python")("libpython3.11.so")

assert.equals(true, ok, py)

test("python", function ()

  test("open", function ()

    local ok, msg

    ok, py, msg = require("santoku.python")("libpython3.11.so")
    assert.equals(true, ok, py)
    assert.equals(msg, "embedded python already open: libpython3.11.so")

  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("abs", function ()
    local abs = py.builtin("abs")
    local v = abs(-10)
    assert.equals(10, v)
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("list", function ()
    local list = py.builtin("list")
print("A")
io.flush()
    local l = list({ 1, 2, 3, 4, 5 })
print("B")
io.flush()
    assert.equals(5, l.pop())
    assert.equals(4, l.pop())
    assert.equals(3, l.pop())
    assert.equals(2, l.pop())
    assert.equals(1, l.pop())
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("dict", function ()
    local dict = py.builtin("dict")
    local d = dict({ a = 1, b = 2, c = 3 })
    assert.equals(1, d.get("a"))
    assert.equals(2, d.get("b"))
    assert.equals(3, d.get("c"))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("dict kwargs", function ()
    local dict = py.builtin("dict")
    local d = dict(py.kwargs({ a = 1, b = 2, c = 3 }))
    assert.equals(1, d.get("a"))
    assert.equals(2, d.get("b"))
    assert.equals(3, d.get("c"))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("list vec", function ()
    local list = py.builtin("list")
    local l = list(vec(1, 2, 3, 4))
    assert.equals(4, l.pop())
    assert.equals(3, l.pop())
    assert.equals(2, l.pop())
    assert.equals(1, l.pop())
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

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

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("bytes", function ()

    local str = "abc"
    local bytes = py.bytes(str)
    local str0 = bytes.decode("utf-8")

    assert.equals(str, str0)

  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("error", function ()
    local np = py.import("numpy")
    assert.equals(false, pcall(function ()
      local a, b = {}, {}
      np.array(a, b)
    end))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("error assertion", function ()
    local exec = py.builtin("exec")
    local ok, err = pcall(function ()
      exec("assert false, test")
    end)
    assert.equals(false, ok, err)
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("lots of arrays", function ()
    local np = py.import("numpy")
    local range = py.builtin("range")
    local arrays = vec()
    for _ = 1, 10000 do
      local rng = range(1000)
      local ar = np.array(rng)
      arrays:append(ar)
    end
    np.vstack(arrays)
    np.vstack(arrays)
    arrays = vec()
    for _ = 1, 10000 do
      local rng = range(1000)
      local ar = np.array(rng)
      arrays:append(ar)
    end
    np.vstack(arrays)
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("Nones are collected", function ()
    local _, py = require("santoku.python")("libpython3.11.so")
    py.import("numpy")
    py.import("numpy")
    local dict = py.builtin("dict")
    local _ = py.builtin("str")
    local d = dict(py.kwargs({ a = 1 }))
    local none = d.get("b")
    local _ = dict(py.kwargs({ a = 1, b = none }))
  end)

end)

py.collect()
collectgarbage()
py.collect()
collectgarbage()
py.collect()
collectgarbage()
py.collect()
collectgarbage()

-- local n = 0
-- print()
-- print("REF_IDX")
-- for k, v in pairs(py.REF_IDX) do
--   n = n + 1
--   print(k, v, require("santoku.inspect")(v))
--   if n > 100 then break end
-- end

-- n = 0
-- print()
-- print("EPHEMERON_IDX")
-- for k, v in pairs(py.EPHEMERON_IDX) do
--   n = n + 1
--   print(k, v, require("santoku.inspect")(v))
--   if n > 100 then break end
-- end

py.close()
