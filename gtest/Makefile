# Makefile for gtest examples

GOOGLE_TEST_LIB = gtest
GOOGLE_TEST_INCLUDE = ../../googletest/googletest/include

G++ = g++
G++_FLAGS = -c -Wall -fsanitize=leak -I $(GOOGLE_TEST_INCLUDE)
LD_FLAGS = -L /usr/local/lib -l $(GOOGLE_TEST_LIB) -l pthread

OBJECTS = main.o tests.o
TARGET = a.out

all: $(TARGET)

$(TARGET): $(OBJECTS)
	g++ -o $(TARGET) $(OBJECTS) $(LD_FLAGS)

%.o : %.cpp
	$(G++) $(G++_FLAGS) $<

clean:
	rm -f $(TARGET) $(OBJECTS)
                    
.PHONY: all clean
