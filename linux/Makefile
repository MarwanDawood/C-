CC = g++
CFLAGS = -g
OBJ = 112_common_sharedmem_process.o
EXE = 112_write_sharedmem_process.elf 112_read_sharedmem_process.elf 112_destroy_sharedmem_process.elf

all: $(EXE)

%.elf: %.o $(OBJ)
	$(CC) $(CFLAGS) $< $(OBJ) -o $@

%.o: %.c %.h
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf *.dSYM *.o $(EXE)
