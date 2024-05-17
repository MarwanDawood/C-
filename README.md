### Compilation
* `g++ file.cpp`
or
* `g++ file.cpp  -std=c++14 && chmod 777 a.out`

To compile and link threads, add the option `-pthread`

---
### Cmake
* Generate Cmake files `cmake .`
* Build the project `cd src && make`
* Run the binary `./a.out`
* Debug programs (signals, arguments, callers, ...) `strace ./a.out`

### Libraries
#### in Linux
* .so is short for 'shared object', which is a dynamic library
* .a is short for 'archive', which is a static library
#### in Windows
* .dll is dynamic library
* .lib is static library
