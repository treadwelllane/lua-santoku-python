# Santoku Python

Santoku Python provides seamless integration between Lua and Python, allowing
Lua code to call Python functions, import Python modules, and work with Python
objects directly.

## Module Reference

### `santoku.python`

Python integration module providing bidirectional data conversion and object manipulation.

#### Constructor

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `santoku.python` | `library_path` | `python_instance` | Loads Python shared library and returns Python interface |

The module exports a single constructor function that must be called with the Python library path:

```lua
local python = require("santoku.python")
local py = python("libpython3.12.so")
```

#### Instance Methods

| Method | Arguments | Returns | Description |
|--------|-----------|---------|-------------|
| `py.builtin` | `name` | `function` | Gets Python built-in function by name |
| `py.import` | `module_name, [submodule, ...]` | `module` | Imports Python module or specific submodules |
| `py.bytes` | `string` | `bytes_object` | Converts Lua string to Python bytes |
| `py.kwargs` | `table` | `kwargs_object` | Creates Python keyword arguments from Lua table |
| `py.slice` | `object, start, end` | `slice_result` | Gets slice of Python sequence |
| `py.collect` | `-` | `number` | Triggers Python garbage collection, returns collected count |
| `py.close` | `-` | `-` | Closes Python interpreter and cleans up |

## Type Conversion

### Lua to Python
- `number` → `int` (if integer) or `float`
- `string` → `str`
- `boolean` → `bool`
- `table` (array-like) → `list`
- `table` (dict-like) → `dict` (when using `kwargs`)
- `function` → Callable Python object
- `nil` → `None`

### Python to Lua
- `int`, `float` → `number`
- `str` → `string`
- `bool` → `boolean`
- `bytes` → `string`
- `None` → `nil`
- `list`, `tuple` → Indexable objects with metamethods
- Other types → Generic objects with attribute access

### Python Object Access
- **Indexing**: Direct 0-based indexing for lists/arrays (`obj[0]`)
- **Methods**: Direct method calls (`obj.method(args)`)
- **Attributes**: Direct attribute access (`obj.attribute`)
- **Iteration**: Python iterables work with Lua `for` loops

## License

MIT License

Copyright 2025 Matthew Brooks

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
