### System

To see every process on the system using standard syntax:
`ps -e`

To see every process on the system using BSD syntax:
`ps aux`

* a = show processes for all users,
* u = display the process's user/owner,
* x = also show processes not attached to a terminal

View top active processes
`top`

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
3. `free()` does not use `munmap()` as `free()` is a standard library c function that doesn't need to deallocate the memory from kernel, it is enough that it marks this address to be reusable in the scope of the c application.

Linux OS handles the following:
* processes
* threads
* files
* networking sockets (a type of IPC)
* inter-process communication
* signals
* terminals
* I/O devices

BIOS (developed by IBM) booting firmware is now replaced by UEFI.

A process can have the following states:
* Created
* Waiting (waiting to be selected by the scheduler)
* running
* blocked (blocked on some resource, i.e. another process is reading from slow I/O device therefore it cannot run this process, after it is unblocked, it goes to waiting state again)
* terminated

Registers:
* status registers (PC, IR, ...)
* general purpose registers (r1, r2, ..., the size of these registers determines the CPU word size, any operation reading/writing/processing data from memory shall be copied here)
* cache memory (SRAM memory used to copy data chunks from DRAM as this is faster than copying only specific bytes besides the fetched data are normally relevant and used in the application, this memory is intermediate between DRAM and GP registers)
* memory (DRAM which needs to be refreshed periodically)

Endianess:
* little endian was used in the past for architectural reasons, now it continued as a legacy i.e. **x86** from Intel and **PowerPC**
* big endian is more logical as if the data 0x12345678 needs to be written to memory (0xa 0xa+1 0xa+2 0xa+3), then this is 1 to 1 mapping, LSB 0x78 will be written to address highest address i.e. 0xa+3, it is used in **ARM**

I/O address:
* memory mapped: advantage is to use the same instructions for accessing memory with the I/O devices
* port mapped: a special decoder is used for the port address lines to decode which device is selected, the other address lines are mapped to the memory, i.e. if the address size is 16-bit, then 2 bits can be reserved for I/O and 14 bits for the memory.

Definitions:
* byte size: 8 bits, there were some conventions in the past for 7 bits
* word size: general purpose register size
* address size: the size of adress that can be allocated, they are stored normally in 64 bits but in the architectural specification only the low-order 48 bits are implemented

**Process Control Block (PCB)** contains all information related to the process.

**Queues:**
There is a queue for each resource, and the scheduler decides from which queue it will pick up. Queues contain the PCB.

**Scheduler:**
***Short Term Scheduler:***
Picks up a queued process from Ready state to the Running state.
***Medium Term Scheduler:***
In case that all the resources are occupied and a process need to be run, then OS uses a space in the secondary memory (called swap in Linux and pagefile.sys in Windows) to move some process and clean up the memory for the new process, moved process can be brought back to memory to continue execution afterwards.
***Long Term Scheduler:***
Picks up  a process which is not yet queued and add it to the Ready state queue. LTS shall mix between the selected processes so some are processor bounded and some are resources bounded.

