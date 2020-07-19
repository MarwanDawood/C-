obj-m =hello.o

# eruivalent to /usr/src/linux-headers-4.15.0-101-generic
KDIR = $(shell uname -r)

all:
	make -C /lib/modules/$(KDIR)/build SUBDIRS=$(PWD) modules

clean:
	rm -rf *.o *.ko *.mod.* *.symvers *.order
