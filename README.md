# [C++ sandbox with focus on STL library]

### Compile files, run the following:
`g++ file.cpp`
 
or

`g++ file.cpp  -std=c++14 && chmod 777 a.out`

To compile and link threads, add the option `-pthread`

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

Jump to the moment your system crashed and generated the coredump, debugging information shall be enabled in compilation
`gdb ./a.out core`

Show variable (print its value)
`p <variable>`

Show code associated with this variable
`list`

---
### System

To see every process on the system using standard syntax:
`ps -e`

To see every process on the system using BSD syntax:
`ps aux`

a = show processes for all users,
u = display the process's user/owner,
x = also show processes not attached to a terminal




View top active processes
`top`

Debug programs (signals, arguments, callers, ...)
`strace ./a.out`

Show program execution time, where -p is to specify POSIX format, 1m2 means 62 seconds
`time -p <command/program>`

Get IPv4 address
`ping -4 <url>`

Socket programming functions
`socket()`, `inet_pton()`, `connect()`, `write()` and `read()`

Getting the assigned memory limit for coredump, where c means coredump
`ulimit -c`
Setting the assigned memory limit for coredump to unlimited
`ulimit -c unlimited`

Compress a file and keep original
`bzip2 -k <file>`

`malloc()` uses:
1. `brk()` for small memory allocation in a single contiguous chunk of virtual address space.
2. `mmap()` for big memory allocation into the heap in independent regions of memory.
