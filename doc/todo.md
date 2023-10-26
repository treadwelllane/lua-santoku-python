# Now

- Basic README
- Documentation

- Check for memory leaks
- Compile to emscripten
- Implement missing todos

- Protocols: object, call, mapping
- Coroutines

# Later

- Rework project structure
    - Development
        - Top level Makefile with all, test, iterate, upload
        - Additional Makefiles laid out in the project tree
          as necessary
        - Config dir, with luarocks config, rockspec
          template, etc.
        - Before doing anything, it copies project sources
          to .build using toku templates
        - TK_XXX_ENV variable sets the environment, which
          corresponds to a .build subdir and a specific
          template file
        - TK_XXX_YYY variables configure project specific
          and general settings like:
            - TK_PYTHON_EMSCRIPTEN=1
            - TK_PYTHON_LOCAL_PYTHON=1
    - Publishing
        - Executed via make upload in top-level Makefile
        - Git is tagged and a tarball built from the .build
          directory is uploaded to GitHub:
            - gh release create <tag> ./pkg.tar.gz
        - Rockspec is uploaded
        - The package should be installable without any
          special system dependencies like toku/etc
