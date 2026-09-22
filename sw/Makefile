# Variables
CC = riscv64-unknown-elf-gcc

CFLAGS = -march=rv32i_zicsr_zifencei -mabi=ilp32 -O0 -I ./src

LDFLAGS = -march=rv32i_zicsr_zifencei -mabi=ilp32 \
	-specs=nano.specs -specs=nosys.specs \
	-fno-common -fverbose-asm -nostartfiles -mstrict-align -mcmodel=medany \
	-fno-builtin -fsigned-char -fdata-sections -ffunction-sections -Wno-unused \
	-T ./link.ld -Wl,--gc-sections,-Map=link.map

OBJCOPY = riscv64-unknown-elf-objcopy

OBJDUMP = riscv64-unknown-elf-objdump

ELFSIZE = riscv64-unknown-elf-size

NMVIEW = riscv64-unknown-elf-nm

TARGET = main

# Define the source and object files
SRC_DIR = ./src/
OBJ_DIR = ./obj/

SRCS = start.s hal.c syscalls.c main.c
OBJS = $(patsubst %.s, $(OBJ_DIR)%.o, $(filter %.s, $(SRCS))) $(patsubst %.c, $(OBJ_DIR)%.o, $(filter %.c, $(SRCS)))

# Default rule
all: $(TARGET).bin
	@$(ELFSIZE) $(TARGET).elf --format=sysv --radix=16
	@hexdump -v -e '"@%04_ax " 1/1 "%02x\n"' $(TARGET).bin > readmemfmt.hex
	@python3 main.py > image.hex
	@echo "DONE"
#@$(NMVIEW) -S $(TARGET).elf > symbols.txt
#@$(OBJDUMP) -DS $(TARGET).elf > main_symbols_dump.S


# Rule to build the .bin file
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# Rule to build the .elf file
$(TARGET).elf: $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

# Rule to link the object files into the final executable
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS)  $(LDFLAGS) -o $(TARGET) $(OBJS)

# Rule to compile C source files into object files
$(OBJ_DIR)%.o: $(SRC_DIR)%.c
	$(CC) $(CFLAGS) -c $< -o $@

# Rule to compile assembly source files into object files
$(OBJ_DIR)%.o: $(SRC_DIR)%.s
	$(CC) $(CFLAGS) -c $< -o $@

# Clean up generated files
clean:
	rm -f $(OBJ_DIR)*.o $(TARGET).elf $(TARGET).hex $(TARGET).bin image.hex readmemfmt.hex
