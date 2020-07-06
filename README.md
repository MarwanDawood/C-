# [C++ sandbox with focus on STL library]

### Compile files, run the following:
`g++ file.cpp`
 
or

`g++ file.cpp  -std=c++14 && chmod 777 a.out`

---
### Cmake

Generate Cmake files:
`cmake .`

Build the project:
`cd src && make`

Run the binary:
`./a.out`

---
### gdb

Add debugging data into the binary, this helps not to setp-in into unnecessary code
`g++ <source-file> -g`

Choose the parent process to debug
`set follow-fork-mode child`

Choose the other program that runs in the child to debug
`set follow-exec-mode new`

---
### System

View all process
`ps -e`

View top active processes
`top`

Debug programs (signals, arguments, callers, ...)
`strace ./a.out`

`malloc()` uses:
1. `brk()` for small memory allocation in a single contiguous chunk of virtual address space.
2. `mmap()` for big memory allocation into the heap in independent regions of memory.
