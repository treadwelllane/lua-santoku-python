# Now

- TK_PYTHON_PC_NAME doesn't work passed via LUAROCKS_VARS
- Use dlsym instead linking python to lua lib

- Basic README
- Documentation
- Protocols: object, call, mapping
- Coroutines

# Later

- Confirm that there are no memory leaks
    - Difficult due to the apparent memory leaks in Python itself
    - Seems to strictly be caused by py.import(...), which might be due to
      caching of imported module in sys.modules (i.e. not a problem...)
    - Address sanitizer prints out way too much output from embedded python
    - Valgrind fails due to embedded python
