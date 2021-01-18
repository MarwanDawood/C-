#  $@ is a macro that refers to the target
#  $< is a macro that refers to the first dependency
#  $^ is a macro that refers to all dependencies
#  % is a macro to make a pattern that we want to watch in both the target and the dependency

INC_DIR    = #"-I/usr/include/SFML/Audio"
CC         = g++
CCFLAGS    = -Wall -std=c++11 -O3
LDFLAGS    =

TARGET     = a
HFILES     =
CFILES     = *.cpp
SRCS       = $(HFILES) $(CFILES)
OBJ        = *.o

.PHONY: all build clean clearscr

all:	$(TARGET)
build:	clearscr clean all run
clean:
	-rm -f $(OBJ) $(TARGET)
clearscr:
	clear
run:
	./$(TARGET)
$(TARGET):
	$(CC) -o $@ $(INC_DIR) $(SRCS) $^ $(CCFLAGS) $(LDFLAGS)
