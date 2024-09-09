local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local iter = require("santoku.iter")
local collect = iter.collect
local map = iter.map

local err = require("santoku.error")
local assert = err.assert

local tbl = require("santoku.table")
local teq = tbl.equals

local validate = require("santoku.validate")
local eq = validate.isequal

local py = require("santoku.python")("libpython3.12.so")

test("python", function ()

  test("open", function ()
    local _, msg, oldlib = require("santoku.python")("libpython3.12.so")
    assert(teq({ msg, oldlib }, { "embedded python already open", "libpython3.12.so" }))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("abs", function ()
    local abs = py.builtin("abs")
    local v = abs(-10)
    assert(eq(10, v))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("list", function ()
    local list = py.builtin("list")
    local l = list({ 1, 2, 3, 4, 5 })
    assert(eq(5, l.pop()))
    assert(eq(4, l.pop()))
    assert(eq(3, l.pop()))
    assert(eq(2, l.pop()))
    assert(eq(1, l.pop()))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("list indexing", function ()
    local list = py.builtin("list")
    local l = list({ 1, 2, 3, 4, 5 })
    assert(eq(5, l[4]))
    assert(eq(4, l[3]))
    assert(eq(3, l[2]))
    assert(eq(2, l[1]))
    assert(eq(1, l[0]))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("list slicing", function ()
    local list = py.builtin("list")
    local l0 = list({ 1, 2, 3, 4, 5 })
    local l1
    l1 = py.slice(l0, 2, 3)
    assert(eq(3, l1[0]))
    l1 = py.slice(l0, 2, 6)
    assert(eq(3, l1[0]))
    assert(eq(4, l1[1]))
    assert(eq(5, l1[2]))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("sequence protocol", function ()
    assert(eq(3, py.builtin("len")({ 1, 2, 3 })))
    assert(teq({ 1, 2, 3 }, collect(map(function (kv)
      return kv[1]
    end, py.builtin("enumerate")({ 1, 2, 3 })))))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("dict", function ()
    local dict = py.builtin("dict")
    local d = dict({ a = 1, b = 2, c = 3 })
    assert(eq(1, d.get("a")))
    assert(eq(2, d.get("b")))
    assert(eq(3, d.get("c")))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("dict kwargs", function ()
    local dict = py.builtin("dict")
    local d = dict(py.kwargs({ a = 1, b = 2, c = 3 }))
    assert(eq(1, d.get("a")))
    assert(eq(2, d.get("b")))
    assert(eq(3, d.get("c")))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("numpy concat", function ()
    local np = py.import("numpy")
    local a = np.array({ 1, 2 })
    local b = np.array({ 3, 4 })
    assert(eq(1, a.item(0)))
    assert(eq(2, a.item(1)))
    assert(eq(3, b.item(0)))
    assert(eq(4, b.item(1)))
    local c = { a, b }
    assert(eq(a, c[1]))
    assert(eq(b, c[2]))
    local d = np.array(c)
    assert(teq({ 2, 2 }, { d.shape[0], d.shape[1] }))
    assert(eq(1, d.item(0)))
    assert(eq(2, d.item(1)))
    assert(eq(3, d.item(2)))
    assert(eq(4, d.item(3)))
    local e = np.concatenate(d)
    assert(teq({ 4 }, { e.shape[0] }))
    assert(eq(1, e.item(0)))
    assert(eq(2, e.item(1)))
    assert(eq(3, e.item(2)))
    assert(eq(4, e.item(3)))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("bytes", function ()

    local str = "abc"
    local bytes = py.bytes(str)
    local str0 = bytes.decode("utf-8")

    assert(eq(str, str0))

  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("error", function ()
    local np = py.import("numpy")
    assert(eq(false, pcall(function ()
      local a, b = {}, {}
      np.array(a, b)
    end)))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("function single return", function ()
    local map = py.builtin("map")
    local list = py.builtin("list")
    local r = list(map(function (_, v)
      return v * v
    end, list({ 1, 2, 3, 4 })))
    assert(eq(16, r.pop()))
    assert(eq(9, r.pop()))
    assert(eq(4, r.pop()))
    assert(eq(1, r.pop()))
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("function multi return", function ()
    local map = py.builtin("map")
    local list = py.builtin("list")
    local r = list(map(function (_, v)
      return v, v, v
    end, list({ 1, 2, 3, 4 })))
    local v
    v = r.pop()
    assert(teq({ 4, 4, 4 }, { v[0], v[1], v[2] }))
    v = r.pop()
    assert(teq({ 3, 3, 3 }, { v[0], v[1], v[2] }))
    v = r.pop()
    assert(teq({ 2, 2, 2 }, { v[0], v[1], v[2] }))
    v = r.pop()
    assert(teq({ 1, 1, 1 }, { v[0], v[1], v[2] }))
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
    assert(eq(false, ok), err)
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("lots of arrays", function ()
    local np = py.import("numpy")
    local range = py.builtin("range")
    local arrays = {}
    for i = 1, 10000 do
      local rng = range(1000)
      local ar = np.array(rng)
      arrays[i] = ar
    end
    np.vstack(arrays)
    np.vstack(arrays)
    arrays = {}
    for i = 1, 10000 do
      local rng = range(1000)
      local ar = np.array(rng)
      arrays[i] = ar
    end
    np.vstack(arrays)
  end)

  py.collect()
  collectgarbage()
  py.collect()
  collectgarbage()

  test("Nones are collected", function ()
    local py = require("santoku.python")("libpython3.12.so")
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

assert(py.REF_IDX.n == 0, "ref index count not equal to zero")

local n = 0
for _ in pairs(py.EPHEMERON_IDX) do
  n = n + 1
  if n > 100 then break end
end

assert(n == 0, "ephemeron table not empty")

py.close()
