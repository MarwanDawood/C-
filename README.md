### Compile files, run the following:
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
