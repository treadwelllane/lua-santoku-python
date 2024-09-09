#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include <stdbool.h>
#include "lua.h"
#include "lauxlib.h"
#include "dlfcn.h"

#define TK_PYTHON_MT_VAL "santoku_python_val"
#define TK_PYTHON_MT_KWARGS "santoku_python_kwargs"
#define TK_PYTHON_MT_GENERIC "santoku_python_generic"
#define TK_PYTHON_MT_ITER "santoku_python_iter"
#define TK_PYTHON_MT_TUPLE "santoku_python_tuple"
#define TK_PYTHON_MT_LIST "santoku_python_list"

int TK_PYTHON_REF_IDX;
int TK_PYTHON_EPHEMERON_IDX;

typedef struct {
  PyObject_HEAD
  intptr_t Lp;
  int ref;
} tk_python_LuaVector;

typedef struct {
  PyObject_HEAD
  intptr_t Lp;
  int ref;
} tk_python_LuaTable;

typedef struct {
  PyObject_HEAD
  tk_python_LuaTable *source;
  int kref;
  int isarray;
  int maxn;
} tk_python_LuaTableIter;

typedef struct {
  PyObject_HEAD
  intptr_t Lp;
  int ref;
} tk_python_LuaFunction;

void tk_python_push_val (lua_State *, PyObject *);
void tk_python_generic_to_lua (lua_State *, int);
int tk_python_builtin (lua_State *);
int tk_python_error (lua_State *);
void tk_lua_callmod (lua_State *, int, int, const char *, const char *);
int tk_python_ref (lua_State *, int);
void tk_python_unref (lua_State *, int);
void tk_python_deref (lua_State *, int);
void tk_python_set_ephemeron (lua_State *, int, int);
void tk_python_get_ephemeron (lua_State *, int, int);
PyTypeObject tk_python_LuaTableIterType;
PyObject *tk_python_lua_to_python (lua_State *, int, bool, bool);
void tk_python_python_to_lua (lua_State *, int, bool, bool);
int tk_python_val_call (lua_State *);
int tk_python_call (lua_State *, int);

int tk_python_LuaTable_init
( tk_python_LuaTable *self,
  PyObject *args,
  PyObject *kwargs )
{
  PyObject *lpo = PyTuple_GetItem(args, 0);
  if (!lpo) return -1;

  PyObject *refo = PyTuple_GetItem(args, 1);
  if (!refo) return -1;

  PyObject *lpl = PyNumber_Long(lpo);
  if (!lpl) return -1;

  PyObject *refl = PyNumber_Long(refo);
  if (!refl) return -1;

  self->Lp = PyLong_AsLongLong(lpl);
  self->ref = PyLong_AsLongLong(refl);

  return 0;
}

int tk_python_LuaTableIter_init
( tk_python_LuaTableIter *self,
  PyObject *args,
  PyObject *kwargs )
{
  PyObject *source = PyTuple_GetItem(args, 0);
  if (!source) return -1;

  PyObject *isarrayi = PyTuple_GetItem(args, 1);
  if (!source) return -1;

  PyObject *maxni = PyTuple_GetItem(args, 2);
  if (!maxni) return -1;

  // TODO: Ensure type and throw error otherwise
  self->source = (tk_python_LuaTable *) source;

  Py_INCREF(source);

  self->kref = LUA_NOREF;

  // TODO: Use boolean, not long, and check type
  int isarray = PyLong_AsLongLong(isarrayi);
  self->isarray = isarray;

  // TODO: Check type
  int maxn = PyLong_AsLongLong(maxni);
  self->maxn = maxn;

  return 0;
}

int tk_python_LuaTableIter_dealloc
( tk_python_LuaTableIter *self )
{
  Py_DECREF(self->source);
  return 0;
}

PyObject *tk_python_LuaTableIter_next
( tk_python_LuaTableIter *self )
{
  lua_State *L = (lua_State *) self->source->Lp;

  tk_python_deref(L, self->source->ref); // tbl

  if (self->isarray) {

    if (self->kref == LUA_NOREF)
      self->kref = 1;
    else
      self->kref ++;

    if (self->kref > self->maxn) {
      lua_pop(L, 1);
      goto stop;
    }

    lua_pushinteger(L, self->kref); // tbl k
    lua_gettable(L, -2); // tbl v

    PyObject *val = tk_python_lua_to_python(L, -1, false, false);
    lua_pop(L, 2);

    return val;

  } else {

    if (self->kref == LUA_NOREF)
      lua_pushnil(L); // tbl k
    else
      tk_python_deref(L, self->kref); // tbl k

    if (lua_next(L, -2) == 0) {
      tk_python_unref(L, self->kref);
      lua_pop(L, 2);
      goto stop;
    }

    PyObject *key = tk_python_lua_to_python(L, -2, false, false);
    PyObject *val = tk_python_lua_to_python(L, -1, false, false);
    PyObject *ret = Py_BuildValue("(O O)", key, val);

    if (self->kref != LUA_NOREF)
      tk_python_unref(L, self->kref);

    self->kref = tk_python_ref(L, -2);
    lua_pop(L, 3);

    return ret;

  }

stop:
  PyErr_SetObject(PyExc_StopIteration, Py_None);
  return NULL;

}

int tk_python_LuaTable_dealloc
( tk_python_LuaTable *self )
{
  lua_State *L = (lua_State *) self->Lp;
  tk_python_unref(L, self->ref);
  return 0;
}

PyObject *tk_python_LuaTable_iter
( tk_python_LuaTable *self )
{
  lua_State *L = (lua_State *) self->Lp;

  tk_python_deref(L, self->ref); // tbl
  lua_Integer maxn = lua_objlen(L, -1);
  bool isarray = maxn > 0;
  lua_pop(L, 1);

  if (!isarray)
    maxn = -1;

  PyObject *class = (PyObject *) &tk_python_LuaTableIterType;
  PyObject *obj = PyObject_CallFunction(class, "O i L", (PyObject *) self, isarray, maxn);
  if (!obj) { tk_python_error(L); return NULL; };

  return obj;
}

PyObject *tk_python_LuaTableIter_iter
( tk_python_LuaTableIter *self )
{
  return (PyObject *) self;
}

PySequenceMethods tk_python_LuaVector_as_sequence;

PyTypeObject tk_python_LuaVectorType = {
  .ob_base = PyVarObject_HEAD_INIT(NULL, 0)
  .tp_name = "santoku.LuaVector",
  .tp_doc = PyDoc_STR("Lua object wrappers"),
  .tp_basicsize = sizeof(tk_python_LuaVector),
  .tp_itemsize = 0,
  .tp_flags = Py_TPFLAGS_DEFAULT,
  .tp_new = PyType_GenericNew,
  .tp_init = (initproc) tk_python_LuaTable_init,
  .tp_dealloc = (destructor) tk_python_LuaTable_dealloc,
  .tp_iter = (getiterfunc) tk_python_LuaTable_iter,
  .tp_as_sequence = &tk_python_LuaVector_as_sequence
};

Py_ssize_t tk_python_LuaVector_sq_length (tk_python_LuaVector *self)
{
  lua_State *L = (lua_State *) self->Lp;
  tk_python_deref(L, self->ref); // obj
  lua_Integer l = lua_objlen(L, -1); // obj
  lua_pop(L, 1); //
  return l;
}

PyObject *tk_python_LuaVector_sq_item (tk_python_LuaVector *a, Py_ssize_t n)
{
  lua_State *L = (lua_State *) a->Lp;
  tk_python_deref(L, a->ref); // v
  lua_pushinteger(L, n + 1); // v n
  lua_gettable(L, -2); // v vv
  lua_remove(L, -2); // vv
  PyObject *obj = tk_python_lua_to_python(L, -1, false, false);
  if (!obj) { tk_python_error(L); return NULL; };
  return obj;
}

PyObject *tk_python_LuaFunction_call (
  tk_python_LuaFunction *self,
  PyObject *args, PyObject *kwargs)
{
  lua_State *L = (lua_State *) self->Lp;

  int top = lua_gettop(L);

  tk_python_deref(L, self->ref); // fn

  int argn_lua = 0;

  if (kwargs == NULL) {
    lua_pushnil(L); // fn kwargs
    argn_lua ++;
  } else {
    tk_python_push_val(L, kwargs); // fn kwargsval
    tk_python_python_to_lua(L, -1, false, false); // fn kwargsval kwargs
    lua_remove(L, -2); // fn kwargs
    argn_lua ++;
  }

  Py_ssize_t argn_py = PyTuple_Size(args);

  if (argn_py < 0) {
    tk_python_error(L);
    return NULL;
  }

  for (Py_ssize_t i = 0; i < argn_py; i ++) {
    PyObject *item = PyTuple_GetItem(args, i);
    tk_python_push_val(L, item); // fn kwargs argval..
    tk_python_python_to_lua(L, -1, false, false); // fn kwargs argval arg..
    lua_remove(L, -2); // fn kwargs arg..
    argn_lua ++;
  }

  lua_call(L, argn_lua, LUA_MULTRET);

  int nret = lua_gettop(L) - top;

  if (nret == 0) {

    return Py_None;

  } else if (nret == 1) {

    return tk_python_lua_to_python(L, top + 1, false, false);

  } else {

    PyObject *ret = PyTuple_New(nret);

    for (int i = 1; i <= nret; i ++) {
      PyObject *o = tk_python_lua_to_python(L, top + i, false, false);
      PyTuple_SetItem(ret, i - 1, o);
    }

    return ret;

  }

}

PySequenceMethods tk_python_LuaVector_as_sequence = {
  .sq_length = (lenfunc) tk_python_LuaVector_sq_length,
  .sq_item = (ssizeargfunc) tk_python_LuaVector_sq_item,
};

PyTypeObject tk_python_LuaTableType = {
  .ob_base = PyVarObject_HEAD_INIT(NULL, 0)
  .tp_name = "santoku.LuaTable",
  .tp_doc = PyDoc_STR("Lua object wrappers"),
  .tp_basicsize = sizeof(tk_python_LuaTable),
  .tp_itemsize = 0,
  .tp_flags = Py_TPFLAGS_DEFAULT,
  .tp_new = PyType_GenericNew,
  .tp_init = (initproc) tk_python_LuaTable_init,
  .tp_dealloc = (destructor) tk_python_LuaTable_dealloc,
  .tp_iter = (getiterfunc) tk_python_LuaTable_iter,
};

PyTypeObject tk_python_LuaTableIterType = {
  .ob_base = PyVarObject_HEAD_INIT(NULL, 0)
  .tp_name = "santoku.LuaTableIter",
  .tp_doc = PyDoc_STR("Lua object wrappers iterator"),
  .tp_basicsize = sizeof(tk_python_LuaTableIter),
  .tp_itemsize = 0,
  .tp_flags = Py_TPFLAGS_DEFAULT,
  .tp_new = PyType_GenericNew,
  .tp_init = (initproc) tk_python_LuaTableIter_init,
  .tp_dealloc = (destructor) tk_python_LuaTableIter_dealloc,
  .tp_iter = (getiterfunc) tk_python_LuaTableIter_iter,
  .tp_iternext = (iternextfunc) tk_python_LuaTableIter_next
};

PyTypeObject tk_python_LuaFunctionType = {
  .ob_base = PyVarObject_HEAD_INIT(NULL, 0)
  .tp_name = "santoku.LuaFunction",
  .tp_doc = PyDoc_STR("Lua function wrappers"),
  .tp_basicsize = sizeof(tk_python_LuaFunction),
  .tp_itemsize = 0,
  .tp_flags = Py_TPFLAGS_DEFAULT,
  .tp_new = PyType_GenericNew,
  .tp_init = (initproc) tk_python_LuaTable_init,
  .tp_dealloc = (destructor) tk_python_LuaTable_dealloc,
  .tp_call = (ternaryfunc) tk_python_LuaFunction_call,
};

void tk_lua_callmod (lua_State *L, int nargs, int nret, const char *smod, const char *sfn)
{
  lua_getglobal(L, "require"); // arg req
  lua_pushstring(L, smod); // arg req smod
  lua_call(L, 1, 1); // arg mod
  lua_pushstring(L, sfn); // args mod sfn
  lua_gettable(L, -2); // args mod fn
  lua_remove(L, -2); // args fn
  lua_insert(L, - nargs - 1); // fn args
  lua_call(L, nargs, nret); // results
}

int tk_python_error (lua_State *L)
{
  PyObject *ptype, *pvalue, *traceback;
  PyErr_Fetch(&ptype, &pvalue, &traceback);

  int n = 1;
  lua_pushstring(L,  PyUnicode_AsUTF8(PyObject_Str(pvalue)));

  PyTracebackObject* traceRoot = (PyTracebackObject*)traceback;
  PyTracebackObject* pTrace = traceRoot;

  while (pTrace != NULL)
  {
    PyFrameObject* frame = pTrace->tb_frame;
    PyCodeObject* code = PyFrame_GetCode(frame);

    int lineNr = PyFrame_GetLineNumber(frame);
    const char *sCodeName = PyUnicode_AsUTF8(code->co_name);
    const char *sFileName = PyUnicode_AsUTF8(code->co_filename);

    lua_pushstring(L, "\n  at %s (%s:%d);");
    lua_pushstring(L, sCodeName);
    lua_pushstring(L, sFileName);
    lua_pushinteger(L, lineNr);
    lua_getfield(L, -4, "format");
    lua_insert(L, -5);
    lua_call(L, 4, 1);
    n ++;
    pTrace = pTrace->tb_next;
    Py_DECREF(code);
  }

  lua_concat(L, n);
  lua_error(L);

  return 0;
}

void tk_python_increment_refs (lua_State *L) {
  lua_rawgeti(L, LUA_REGISTRYINDEX, TK_PYTHON_REF_IDX); // idx
  lua_getfield(L, -1, "n"); // idx n
  int n = lua_type(L, -1) == LUA_TNIL ? 1 : lua_tointeger(L, -1) + 1;
  lua_pop(L, 1); // idx
  lua_pushinteger(L, n); // idx n
  lua_setfield(L, -2, "n"); // idx
  lua_pop(L, 1); //
}

void tk_python_decrement_refs (lua_State *L) {
  lua_rawgeti(L, LUA_REGISTRYINDEX, TK_PYTHON_REF_IDX); // idx
  lua_getfield(L, -1, "n"); // idx n
  int n = lua_type(L, -1) == LUA_TNIL ? 1 : lua_tointeger(L, -1) - 1;
  lua_pop(L, 1); // idx
  lua_pushinteger(L, n); // idx n
  lua_setfield(L, -2, "n"); // idx
  lua_pop(L, 1); //
}

int tk_python_ref (lua_State *L, int i)
{
  lua_pushvalue(L, i); // val
  lua_rawgeti(L, LUA_REGISTRYINDEX, TK_PYTHON_REF_IDX); // tbl idx
  lua_insert(L, -2); // idx tbl
  int ref = luaL_ref(L, -2); // idx
  lua_pop(L, 1); //
  tk_python_increment_refs(L);
  return ref;
}

void tk_python_unref (lua_State *L, int ref)
{
  lua_rawgeti(L, LUA_REGISTRYINDEX, TK_PYTHON_REF_IDX); // idx
  luaL_unref(L, -1, ref);
  lua_pop(L, 1);
  tk_python_decrement_refs(L);
}

void tk_python_deref (lua_State *L, int ref)
{
  lua_rawgeti(L, LUA_REGISTRYINDEX, TK_PYTHON_REF_IDX); // idx
  lua_rawgeti(L, -1, ref); // idx val
  lua_remove(L, -2); // val
}

void *PYTHON = NULL;

int tk_python_close (lua_State *L)
{
  dlclose(PYTHON);
  Py_Finalize();
  return 0;
}

int tk_python_collect (lua_State *L)
{
  ssize_t res = PyGC_Collect();
  lua_pushinteger(L, res);
  return 1;
}

int tk_python_opened_lib_name_ref = LUA_NOREF;

int tk_python_open (lua_State *L)
{
  luaL_checktype(L, -1, LUA_TSTRING);
  size_t liblen;
  const char *lib = lua_tolstring(L, -1, &liblen);

  if (tk_python_opened_lib_name_ref != LUA_NOREF) {

    lua_rawgeti(L, LUA_REGISTRYINDEX, tk_python_opened_lib_name_ref); // lib oldlib
    size_t oldliblen;
    const char *oldlib = lua_tolstring(L, -1, &oldliblen);

    int same = liblen == oldliblen && !strncmp(lib, oldlib, fmin(liblen, oldliblen));

    lua_pushstring(L, "embedded python already open"); // lib oldlib msg
    lua_insert(L, -2); // lib msg oldlib
    lua_remove(L, -3); // msg oldlib

    if (!same) {
      tk_lua_callmod(L, 2, 0, "santoku.error", "error"); // msg oldlib
      return 0;
    } else {
      lua_pushvalue(L, lua_upvalueindex(1)); // msg oldlib py
      lua_insert(L, -3); // py msg oldlib
      return 3;
    }

  }

  tk_python_opened_lib_name_ref = luaL_ref(L, LUA_REGISTRYINDEX); //

  PYTHON = dlopen(lib, RTLD_NOW | RTLD_GLOBAL);

  if (PYTHON == NULL)
    luaL_error(L, "Error loading python library");

  Py_Initialize();

  if (PyType_Ready(&tk_python_LuaTableType) < 0)
    return tk_python_error(L);

  if (PyType_Ready(&tk_python_LuaTableIterType) < 0)
    return tk_python_error(L);

  if (PyType_Ready(&tk_python_LuaVectorType) < 0)
    return tk_python_error(L);

  if (PyType_Ready(&tk_python_LuaFunctionType) < 0)
    return tk_python_error(L);

  lua_pushvalue(L, lua_upvalueindex(1)); // py
  return 1;
}

int tk_python_check_metatable (lua_State *L, int i, char *mt)
{
  lua_pushvalue(L, i);

  if (lua_getmetatable(L, -1) == 0)
    goto none;

  luaL_getmetatable(L, mt);
  if (lua_type(L, -1) == LUA_TNIL)
    goto none;

  if (lua_equal(L, -1, -2)) {
    lua_pop(L, 3);
    return 1;
  } else {
    lua_pop(L, 3);
    return 0;
  }

none:
  lua_pop(L, 1);
  return 0;
}

// TODO: Combine with above
PyObject *tk_python_peek_val (lua_State *L, int i)
{
  if ((tk_python_check_metatable(L, i, TK_PYTHON_MT_GENERIC)) ||
      (tk_python_check_metatable(L, i, TK_PYTHON_MT_TUPLE)) ||
      (tk_python_check_metatable(L, i, TK_PYTHON_MT_ITER)) ||
      (tk_python_check_metatable(L, i, TK_PYTHON_MT_KWARGS))) {
    tk_python_get_ephemeron(L, i, 1);
    PyObject *obj = tk_python_peek_val(L, -1);
    lua_pop(L, 1);
    return obj;
  } else {
    luaL_checkudata(L, i, TK_PYTHON_MT_VAL);
    luaL_checkudata(L, i, TK_PYTHON_MT_VAL);
    tk_python_get_ephemeron(L, i, 1);
    PyObject *obj = (PyObject *) lua_touserdata(L, -1);
    lua_pop(L, 1);
    return obj;
  }
}

// TODO: Combine with below
PyObject *tk_python_peek_val_safe (lua_State *L, int i)
{
  if (tk_python_check_metatable(L, i, TK_PYTHON_MT_GENERIC) ||
      tk_python_check_metatable(L, i, TK_PYTHON_MT_TUPLE) ||
      tk_python_check_metatable(L, i, TK_PYTHON_MT_LIST) ||
      tk_python_check_metatable(L, i, TK_PYTHON_MT_ITER) ||
      tk_python_check_metatable(L, i, TK_PYTHON_MT_KWARGS)) {
    tk_python_get_ephemeron(L, i, 1);
    PyObject *obj = tk_python_peek_val(L, -1);
    lua_pop(L, 1);
    return obj;
  } else if (tk_python_check_metatable(L, i, TK_PYTHON_MT_VAL)) {
    tk_python_get_ephemeron(L, i, 1);
    PyObject *obj = (PyObject *) lua_touserdata(L, -1);
    lua_pop(L, 1);
    return obj;
  } else {
    return NULL;
  }
}

void tk_python_set_ephemeron (lua_State *L, int iu, int ie)
{
  // eph
  luaL_checktype(L, iu, LUA_TUSERDATA);
  lua_pushvalue(L, iu); // eph val
  lua_insert(L, -2); // val eph
  lua_rawgeti(L, LUA_REGISTRYINDEX, TK_PYTHON_EPHEMERON_IDX); // val eph idx
  lua_pushvalue(L, -3); // val eph idx val
  lua_gettable(L, -2); // val eph idx epht
  if (lua_type(L, -1) == LUA_TNIL) {
    lua_pop(L, 1); // val eph idx
    lua_pushvalue(L, -3); // val eph idx val
    lua_newtable(L); // val eph idx val epht
    lua_settable(L, -3); // val eph idx
    lua_pushvalue(L, -3); // val eph idx val
    lua_gettable(L, -2); // val eph idx epht
  }
  lua_pushinteger(L, ie); // val eph idx epht ie
  lua_pushvalue(L, -4); // val eph idx epht ie eph
  lua_settable(L, -3); // val eph idx epht
  lua_pop(L, 4); //
}

void tk_python_get_ephemeron (lua_State *L, int iu, int ie)
{
  lua_pushvalue(L, iu); // val
  lua_rawgeti(L, LUA_REGISTRYINDEX, TK_PYTHON_EPHEMERON_IDX); // val idx
  lua_insert(L, -2); // idx val
  lua_gettable(L, -2); // idx epht
  if (lua_type(L, -1) == LUA_TNIL) {
    lua_remove(L, -2); // eph
  } else {
    lua_pushinteger(L, ie); // idx epht ie
    lua_gettable(L, -2); // idx epht eph
    lua_remove(L, -2); // idx eph
    lua_remove(L, -2); // eph
  }
}

void tk_python_push_val (lua_State *L, PyObject *obj)
{
  lua_newuserdata(L, 0);
  lua_pushlightuserdata(L, obj);
  tk_python_set_ephemeron(L, -2, 1);
  luaL_getmetatable(L, TK_PYTHON_MT_VAL);
  lua_setmetatable(L, -2);
}

int tk_python_kwargs (lua_State *L)
{
  luaL_checktype(L, -1, LUA_TTABLE); // tbl
  lua_pushstring(L, "dict"); // tbl dict
  tk_python_builtin(L); // tbl dict fn
  lua_remove(L, -2); // tbl fn
  lua_insert(L, -2); // fn tbl
  tk_python_call(L, 1); // fn tbl d

  lua_newuserdata(L, 0); // fn tbl d ud
  lua_insert(L, -2); // fn tbl ud d
  tk_python_set_ephemeron(L, -2, 1); // fn tbl ud
  luaL_getmetatable(L, TK_PYTHON_MT_KWARGS);
  lua_setmetatable(L, -2);

  return 1;
}

int tk_python_bytes (lua_State *L)
{
  luaL_checktype(L, -1, LUA_TSTRING);
  unsigned long len;
  const char *str = lua_tolstring(L, -1, &len);

  PyObject *bytes = PyBytes_FromStringAndSize(str, len);
  tk_python_push_val(L, bytes); // str bi
  tk_python_python_to_lua(L, -1, false, true);
  return 1;
}

int tk_python_slice (lua_State *L)
{
  PyObject *obj = tk_python_peek_val_safe(L, 1);
  Py_ssize_t start = luaL_checkinteger(L, 2);
  Py_ssize_t end = luaL_checkinteger(L, 3);
  PyObject *slice = PySequence_GetSlice(obj, start, end);
  tk_python_push_val(L, slice);
  tk_python_python_to_lua(L, -1, false, false);
  return 1;
}

int tk_python_builtin (lua_State *L)
{
  luaL_checktype(L, -1, LUA_TSTRING);
  const char *name = lua_tostring(L, -1);

  PyObject *builtins = PyEval_GetBuiltins();
  if (!builtins) return tk_python_error(L);

  PyObject *builtin = PyObject_CallMethod(builtins, "get", "s", name);
  if (!builtin) return tk_python_error(L);

  tk_python_push_val(L, builtin); // str bi
  tk_python_python_to_lua(L, -1, false, false); // str bi lua
  lua_remove(L, -2); // str bi
  return 1;
}

int tk_python_import (lua_State *L)
{
  luaL_checktype(L, 1, LUA_TSTRING);
  const char *name = lua_tostring(L, 1);

  int n = lua_gettop(L);

  if (n == 1)
  {
    PyObject *lib = PyImport_ImportModule(name);
    if (!lib) return tk_python_error(L);

    tk_python_push_val(L, lib);
    tk_python_python_to_lua(L, -1, false, false);
    return 1;
  }

  PyObject *fromlist = PyList_New(0);
  if (!fromlist) return tk_python_error(L);

  for (int i = 1; i < n; i ++)
  {
    luaL_checktype(L, i + 1, LUA_TSTRING);
    const char *submod = lua_tostring(L, i + 1);
    PyObject *submodobj = PyUnicode_FromString(submod);

    int rc = PyList_Append(fromlist, submodobj);
    Py_DECREF(submodobj);

    if (rc == -1)
    {
      Py_DECREF(fromlist);
      return tk_python_error(L);
    }
  }

  PyObject *lib = PyImport_ImportModuleEx(name, NULL, NULL, fromlist);
  Py_DECREF(fromlist);

  if (!lib) return tk_python_error(L);

  Py_DECREF(fromlist);

  tk_python_push_val(L, lib);
  tk_python_python_to_lua(L, -1, false, false);
  return 1;
}

int tk_python_val_gc (lua_State *L)
{
  PyObject *obj = tk_python_peek_val(L, -1);
  Py_DECREF(obj);
  return 0;
}

PyObject *tk_python_table_to_python (lua_State *L, int i, bool recurse)
{
  int ref = tk_python_ref(L, i);

  if (!recurse) {

    // TODO: Support specific wrappers for
    // santoku tuples, generators, etc.

    int isvec = lua_objlen(L, i) > 0;

    if (isvec) {

      PyObject *class = (PyObject *) &tk_python_LuaVectorType;
      PyObject *obj = PyObject_CallFunction(class, "L L", (intptr_t) L, ref);
      if (!obj) { tk_python_error(L); return NULL; };
      return obj;

    } else {

      PyObject *class = (PyObject *) &tk_python_LuaTableType;
      PyObject *obj = PyObject_CallFunction(class, "L L", (intptr_t) L, ref);
      if (!obj) { tk_python_error(L); return NULL; };
      return obj;

    }

  } else {

    luaL_error(L, "table_to_python recurse not implemented");
    return NULL;

  }

}

PyObject *tk_python_function_to_python (lua_State *L, int i)
{
  int ref = tk_python_ref(L, i);
  PyObject *class = (PyObject *) &tk_python_LuaFunctionType;
  PyObject *obj = PyObject_CallFunction(class, "L L", (intptr_t) L, ref);
  if (!obj) { tk_python_error(L); return NULL; };
  return obj;
}

PyObject *tk_python_lua_to_python (lua_State *L, int i, bool recurse, bool force_wrap)
{
  if (!force_wrap) {
    PyObject *obj = tk_python_peek_val_safe(L, i);
    if (obj) {
      Py_INCREF(obj);
      return obj;
    }
  }

  int type = lua_type(L, i);

  if (type == LUA_TSTRING) {
    unsigned long len;
    const char *str = lua_tolstring(L, i, &len);
    return PyUnicode_FromStringAndSize(str, len);

  } else if (type == LUA_TNUMBER) {
    lua_Number n = lua_tonumber(L, i);
    return fmod(n, 1) == 0
      ? PyLong_FromLongLong((lua_Integer) n)
      : PyFloat_FromDouble(n);

  } else if (type == LUA_TBOOLEAN) {
    return lua_toboolean(L, i) ? Py_True : Py_False;

  } else if (type == LUA_TTABLE) {
    return tk_python_table_to_python(L, i, recurse);

  } else if (type == LUA_TFUNCTION) {
    return tk_python_function_to_python(L, i);

  } else if (type == LUA_TNIL) {
    return Py_None;

  } else {
    return Py_None;
  }

}

int tk_python_generic_index (lua_State *L)
{
  PyObject *obj = tk_python_lua_to_python(L, -2, false, false);
  PyObject *attr = tk_python_lua_to_python(L, -1, false, false);

  PyObject *mem = PyObject_GenericGetAttr(obj, attr);
  if (!mem) return tk_python_error(L);

  tk_python_push_val(L, mem);
  tk_python_python_to_lua(L, -1, false, false);
  return 1;
}

int tk_python_tuple_index (lua_State *L)
{
  PyObject *tup = tk_python_peek_val(L, -2);

  if (lua_type(L, -1) == LUA_TNUMBER) {

    lua_Number i = lua_tointeger(L, -1);

    PyObject *mem = PyTuple_GetItem(tup, i);
    if (!mem) return tk_python_error(L);
    Py_INCREF(mem);

    tk_python_push_val(L, mem);
    tk_python_python_to_lua(L, -1, false, false);
    return 1;

  } else {

    return tk_python_generic_index(L);

  }
}

int tk_python_list_index (lua_State *L)
{
  PyObject *list = tk_python_lua_to_python(L, -2, false, false);

  if (lua_type(L, -1) == LUA_TNUMBER) {

    lua_Number i = lua_tointeger(L, -1);

    PyObject *mem = PyList_GetItem(list, i);
    if (!mem) return tk_python_error(L);
    Py_INCREF(mem);

    tk_python_push_val(L, mem);
    tk_python_python_to_lua(L, -1, false, false);
    return 1;

  } else {

    return tk_python_generic_index(L);

  }
}
int tk_python_iter_call (lua_State *L)
{
  PyObject *iter = tk_python_peek_val(L, 1);
  PyObject *next = PyIter_Next(iter);
  if (next == NULL) {
    if (PyErr_Occurred())
      return tk_python_error(L);
    return 0;
  } else {
    tk_python_push_val(L, next);
    tk_python_python_to_lua(L, -1, false, false);
    return 1;
  }
}

int tk_python_generic_call (lua_State *L)
{
  tk_python_val_call(L);
  tk_python_python_to_lua(L, -1, false, false);
  return 1;
}

void tk_python_generic_to_lua (lua_State *L, int i)
{
  lua_pushvalue(L, i); // val
  lua_newuserdata(L, 0); // val udata
  lua_insert(L, -2); // udata val
  tk_python_set_ephemeron(L, -2, 1); // udata
  luaL_getmetatable(L, TK_PYTHON_MT_GENERIC); // udata mt
  lua_setmetatable(L, -2); // udata
}

void tk_python_tuple_to_lua (lua_State *L, int i)
{
  lua_pushvalue(L, i); // val
  lua_newuserdata(L, 0); // val udata
  lua_insert(L, -2); // udata val
  tk_python_set_ephemeron(L, -2, 1); // udata
  luaL_getmetatable(L, TK_PYTHON_MT_TUPLE);
  lua_setmetatable(L, -2);
}

void tk_python_list_to_lua (lua_State *L, int i)
{
  lua_pushvalue(L, i); // val
  lua_newuserdata(L, 0); // val udata
  lua_insert(L, -2); // udata val
  tk_python_set_ephemeron(L, -2, 1); // udata
  luaL_getmetatable(L, TK_PYTHON_MT_LIST);
  lua_setmetatable(L, -2);
}

void tk_python_iter_to_lua (lua_State *L, int i)
{
  lua_pushvalue(L, i); // val
  lua_newuserdata(L, 0); // val udata
  lua_insert(L, -2); // udata val
  tk_python_set_ephemeron(L, -2, 1); // udata
  luaL_getmetatable(L, TK_PYTHON_MT_ITER);
  lua_setmetatable(L, -2);
}

void tk_python_python_to_lua (lua_State *L, int i, bool recurse, bool force_generic)
{
  PyObject *obj = tk_python_peek_val(L, i);

  if (force_generic)
    goto generic;

  if (Py_IS_TYPE(obj, &PyBool_Type)) {
    lua_pushboolean(L, obj == Py_True ? 1 : 0);

  } else if (Py_IS_TYPE(obj, &PyFloat_Type)) {
    lua_pushnumber(L, PyFloat_AsDouble(obj));

  } else if (Py_IS_TYPE(obj, &PyLong_Type)) {
    lua_pushinteger(L, PyLong_AsLongLong(obj));

  } else if (Py_IS_TYPE(obj, &PyUnicode_Type)) {

    ssize_t len;
    const char *str = PyUnicode_AsUTF8AndSize(obj, &len);

    if (!str)
      tk_python_error(L);

    lua_pushlstring(L, str, len);

  } else if (Py_IS_TYPE(obj, &PyBytes_Type)) {

    ssize_t len;
    char *str;
    if (PyBytes_AsStringAndSize(obj, &str, &len) == -1)
      tk_python_error(L);

    lua_pushlstring(L, str, len);

  } else if (Py_IS_TYPE(obj, &PyTuple_Type)) {
    tk_python_tuple_to_lua(L, i);

  } else if (Py_IS_TYPE(obj, &PyList_Type)) {
    tk_python_list_to_lua(L, i);

  } else if (PyIter_Check(obj)) {
    tk_python_iter_to_lua(L, i);

  } else {
    goto generic;
  }

  return;

generic:
  tk_python_generic_to_lua(L, i);
  return;

  // PyBool_Type
  // PyFloat_Type
  // PyLong_Type
  // PyDict_Type
  // PyList_Type
  // PyTuple_Type
  //
  // PyUnicode_Type
  // PyBytes_Type
  //
  // PyFunction_Type
  // PyCFunction_Type
  // PyCMethod_Type
  // PyClassMethod_Type
  // PyInstanceMethod_Type
  //
  // PyMap_Type
  // PySet_Type
  //
  // PyAsyncGen_Type
  // PyBaseObject_Type
  // PyByteArrayIter_Type
  // PyByteArray_Type
  // PyBytesIter_Type
  // PyCallIter_Type
  // PyCapsule_Type
  // PyCell_Type
  // PyClassMethodDescr_Type
  // PyCode_Type
  // PyComplex_Type
  // PyContextToken_Type
  // PyContextVar_Type
  // PyContext_Type
  // PyCoro_Type
  // PyDictItems_Type
  // PyDictIterItem_Type
  // PyDictIterKey_Type
  // PyDictIterValue_Type
  // PyDictKeys_Type
  // PyDictProxy_Type
  // PyDictRevIterItem_Type
  // PyDictRevIterKey_Type
  // PyDictRevIterValue_Type
  // PyDictValues_Type
  // PyEllipsis_Type
  // PyEnum_Type
  // PyFilter_Type
  // PyFrame_Type
  // PyFrozenSet_Type
  // PyGen_Type
  // PyGetSetDescr_Type
  // PyListIter_Type
  // PyListRevIter_Type
  // PyLongRangeIter_Type
  // PyMemberDescr_Type
  // PyMemoryView_Type
  // PyMethodDescr_Type
  // PyMethod_Type
  // PyModuleDef_Type
  // PyModule_Type
  // PyODictItems_Type
  // PyODictIter_Type
  // PyODictKeys_Type
  // PyODictValues_Type
  // PyODict_Type
  // PyPickleBuffer_Type
  // PyProperty_Type
  // PyRangeIter_Type
  // PyRange_Type
  // PyReversed_Type
  // PySeqIter_Type
  // PySetIter_Type
  // PySlice_Type
  // PyStaticMethod_Type
  // PyStdPrinter_Type
  // PySuper_Type
  // PyTraceBack_Type
  // PyTupleIter_Type
  // PyTuple_Type
  // PyType_Type
  // PyUnicodeIter_Type
  // PyWrapperDescr_Type
  // PyZip_Type
}

int tk_python_val_lua (lua_State *L)
{
  int n = lua_gettop(L);

  if (n > 2 || n < 1) {
    luaL_error(L, "expected 1 or 2 arguments to val(...)");
    return 0;
  }

  bool recurse = false;

  if (n == 2) {
    recurse = lua_toboolean(L, -1);
    lua_pop(L, 1);
  }

  tk_python_python_to_lua(L, -1, recurse, false);
  lua_remove(L, -2);
  return 1;
}

int tk_python_call (lua_State *L, int nargs)
{
  int kwargsi = -1;
  PyObject *kwargs = NULL;

  for (int i = -nargs; i < 0; i ++)
  {
    if (tk_python_check_metatable(L, i, TK_PYTHON_MT_KWARGS)) {
      kwargs = tk_python_peek_val(L, i);
      kwargsi = i;
      break;
    }
  }

  PyObject *fn = tk_python_peek_val(L, - (nargs + 1));
  PyObject *args = PyTuple_New(kwargs ? nargs - 1 : nargs);
  if (!args) return tk_python_error(L);

  for (int i = -nargs; i < 0; i ++)
  {
    if (kwargs && i == kwargsi)
      continue;
    PyObject *arg = tk_python_lua_to_python(L, i, false, false);
    if (PyTuple_SetItem(args, i + nargs, arg)) {
      Py_DECREF(args);
      return tk_python_error(L);
    }
  }

  PyObject *res = PyObject_Call(fn, args, kwargs);

  if (!res) {
    Py_DECREF(args);
    return tk_python_error(L);
  }

  Py_DECREF(args);

  tk_python_push_val(L, res);
  return 1;
}

int tk_python_val_call (lua_State *L)
{
  tk_python_call(L, lua_gettop(L) - 1);
  return 1;
}

luaL_Reg tk_python_fns[] =
{
  { "bytes", tk_python_bytes },
  { "slice", tk_python_slice },
  { "collect", tk_python_collect },
  { "close", tk_python_close },
  { "builtin", tk_python_builtin },
  { "import", tk_python_import },
  { "kwargs", tk_python_kwargs },
  { NULL, NULL }
};

int luaopen_santoku_python (lua_State *L)
{
  lua_newtable(L); // mt
  luaL_register(L, NULL, tk_python_fns); // mt
  lua_newtable(L); // mt mt
  lua_setmetatable(L, -2); // mt

  luaL_newmetatable(L, TK_PYTHON_MT_VAL); // mt mte
  lua_pushcfunction(L, tk_python_val_gc); // mt mte fn
  lua_setfield(L, -2, "__gc"); // mt mte
  lua_pop(L, 1); // mt

  luaL_newmetatable(L, TK_PYTHON_MT_KWARGS); // mt mte
  lua_pop(L, 1); // mt

  luaL_newmetatable(L, TK_PYTHON_MT_GENERIC); // mt mte
  lua_pushcfunction(L, tk_python_generic_index);
  lua_setfield(L, -2, "__index"); // mt mte
  lua_pushcfunction(L, tk_python_generic_call);
  lua_setfield(L, -2, "__call"); // mt mte
  lua_pop(L, 1); // mt

  luaL_newmetatable(L, TK_PYTHON_MT_ITER); // mt mte
  lua_pushcfunction(L, tk_python_generic_index);
  lua_setfield(L, -2, "__index"); // mt mte
  lua_pushcfunction(L, tk_python_iter_call);
  lua_setfield(L, -2, "__call"); // mt mte
  lua_pop(L, 1); // mt

  luaL_newmetatable(L, TK_PYTHON_MT_TUPLE); // mt mte
  lua_pushcfunction(L, tk_python_tuple_index);
  lua_setfield(L, -2, "__index"); // mt mte
  lua_pop(L, 1); // mt

  luaL_newmetatable(L, TK_PYTHON_MT_LIST); // mt mte
  lua_pushcfunction(L, tk_python_list_index);
  lua_setfield(L, -2, "__index"); // mt mte
  lua_pop(L, 1); // mt

  lua_newtable(L); // mt t
  lua_pushinteger(L, 0); // mt t n
  lua_setfield(L, -2, "n"); // mt t
  TK_PYTHON_REF_IDX = luaL_ref(L, LUA_REGISTRYINDEX); // mt
  lua_rawgeti(L, LUA_REGISTRYINDEX, TK_PYTHON_REF_IDX); // mt t
  lua_setfield(L, -2, "REF_IDX"); // mt

  lua_newtable(L); // mt t
  lua_newtable(L); // mt t mt
  lua_pushstring(L, "k"); // mt t mt v
  lua_setfield(L, -2, "__mode"); // mt t mt
  lua_setmetatable(L, -2); // mt t
  TK_PYTHON_EPHEMERON_IDX = luaL_ref(L, LUA_REGISTRYINDEX); // mt
  lua_rawgeti(L, LUA_REGISTRYINDEX, TK_PYTHON_EPHEMERON_IDX); // mt t
  lua_setfield(L, -2, "EPHEMERON_IDX"); // mt

  lua_pushinteger(L, 0); // mt n
  lua_setfield(L, -2, "REF_IDX_N"); // mt

  lua_pushcclosure(L, tk_python_open, 1); // fn
  return 1;
}
