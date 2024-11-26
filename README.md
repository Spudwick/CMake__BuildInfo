# CMake Build Info Header Generator

**Author**: Thomas Oliver ([Spudwick](https://github.com/Spudwick))

## Overview

This repository contains a CMake module that can be used to automatically generate a build information header for use in C and C++ projects.

## Requirements

| Software | Version Used | Minimum Required |
|---|---|---|
| `cmake` | 3.25.1 | *Not tested* |

## Usage

A single function call is used to define a build information header for a pre-defined target.
An interface library is created in the form of `<target>::buildinfo`. This should be linked against using `target_link_libraries`.

```cmake
t_build_target_define_header(<target> <header include path>)
```

`<target>` is the CMake target to add the build information header to.

`<header include path>` is the path that will be used to include the build information header within the project source.

The generated *interface* library contains two components...
 1. The generated build information header as a *PUBLIC* source file.
 2. A *PUBLIC* include directory such that the build header can be included using the specified `<header include path>`.

### Example

CMakeLists.txt:
```cmake
include(build-info)

add_executable(example "main.c")
t_build_target_define_header(example "cmake/build.h")
target_link_libraries(example PRIVATE example::buildinfo)
```

main.c:
```C
#include "cmake/build.h"

int main(int argc, char* argc[]) {}
```

See the [example](example) directory for a buildable example.

## Header Format

The build information is provided in the header through several `#defines`.

| Define | Description |
|---|---|
| VERSION_MAJOR | Major component of version |
| VERSION_MINOR | Minor component of version |
| VERSION_PATCH | Patch component of version |
| VERSION_TWEAK | Tweak component of version |
| CONFIG_TIMESTAMP | Timestamp of when the CMake project was configured, in seconds since the Unix Epoch (UTC) |
| BUILD_TIMESTAMP | Timestamp of when the project was built, in seconds since the Unix Epoch (UTC) |
| COMPILER_NAME | String name of compiler |
| COMPILER_VERSION_MAJOR | Major component of compiler version |
| COMPILER_VERSION_MINOR | Minor component of compiler version |
| COMPILER_VERSION_PATCH | Patch component of compiler version |
| COMPILER_VERSION_TWEAK | Tweak component of compiler version |

### Versioning

The module attempts to extract the version information from the following places, in order of priority.

1) The version property of the given `<target>`.

This can be specified as below.
```cmake
set_target_properties(example PROPERTIES
    VERSION 1.2.3.4
)
```

2) The top-level CMake projects version.

This is specified when defining the project.
```cmake
project(example
    VERSION 1.2.3.4
)
```

3) Defaults to `1.0.0.0`.

The version used by the module always consists of 4 components, major/minor/patch/tweak. If the provided version information contains more or fewer components, the version number is truncated or padded respectively such that there are 4 components.

## License

This code is made available under the [LICENSE](LICENSE) distributed with the repository.
