## libdave C++

Contains the libdave C++ library, which handles the bulk of the DAVE protocol implementation for Discord's native clients.

### Dependencies

- [mlspp](https://github.com/cisco/mlspp)
  - Configured with `-DMLS_CXX_NAMESPACE="mlspp"` and `-DDISABLE_GREASE=ON`
- One of the supported SSL backends:
  - [OpenSSL 1.1 or 3.0](https://github.com/openssl/openssl)
  - [boringssl](https://boringssl.googlesource.com/boringssl)

#### Testing

- [googletest](https://github.com/google/googletest)
- [AFLplusplus](https://github.com/AFLplusplus/AFLplusplus)


## Building

### vcpkg

Make sure the vcpkg submodule is up to date and initialized:
```
git submodule update --recursive
./vcpkg/bootstrap-vcpkg.sh
```

### Compiling

For a static library, run:
```
make cclean
make
```

For a shared library, run:
```
make cclean
make shared
```

### Homebrew (macOS)

Homebrew requires formulae to be installed from a tap. Because this repository
is named `discord/libdave` rather than `discord/homebrew-libdave`, tap it with
an explicit URL first:
```
brew tap discord/libdave https://github.com/discord/libdave
brew install --build-from-source discord/libdave/libdave
```

To install the latest repository head instead of the latest tagged release referenced by the formula, run:
```
brew tap discord/libdave https://github.com/discord/libdave
brew install --build-from-source --HEAD discord/libdave/libdave
```

The Homebrew install exports a CMake package, so downstream projects can consume libdave with:
```
find_package(libdave CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE libdave::libdave)
```

### SSL

By default the library builds with OpenSSL 3, however you can modify `VCPKG_MANIFEST_DIR` in the [Makefile](Makefile) to build with OpenSSL 1.1 or BoringSSL instead.
