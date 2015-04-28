
TARGET=libbpf.a

CFLAGS=-I/usr/include
OBJS=bpf_load.o libbpf.o

$(TARGET) : $(OBJS)
	ar -rcs $(TARGET) $(OBJS)
	ranlib $(TARGET)

%.o : %.c
	$(CC) -MD -c $(CFLAGS) $< -o $@

clean:
	@rm -rf $(TARGET) *.d *.o

