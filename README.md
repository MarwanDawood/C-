### Compile files, run the following:
`g++ file.cpp`
 
or

`g++ file.cpp  -std=c++14 && chmod 777 a.out`

To compile and link threads, add the option `-pthread`

---
### Cmake

* Generate Cmake files `cmake .`
* Build the project `cd src && make`
* Run the binary `./a.out`
* Debug programs (signals, arguments, callers, ...) `strace ./a.out`

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

* add a breakpoint (break) `b <function or line number>`
* clear breakpoint `clear <function or line number>`
* watch for variable changes `watch <global variable>`
* start the program (run) `r`
* step line by line (step) `s`
* step over a function (next) `n`
* continue till the next breakpoint or watch point (continue) `c`
* repeat the last command `press enter`
* Print variable `p <variable>`
* Show a local variable `info variables <variable>`
* Show local variables `info locals`
* Show all variables `info variables`
* Show stack frames, the current frame has value of 0 `fr <frame number (optional)>
* Show call stack (backtrace) `bt`
* Examine memory by address or by symbol if -g was used `x/<number><format o|h|d|...><size b|h|w|g><address or symbol>`, `help x`
* List code associated with this variable `li`
* exit the gdb `quit`

