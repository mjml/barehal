TARGET=squeezer
HAL=1
CPPSRC=$(shell ls *.cpp)
CSRC=$(shell ls *.c)
CPP=arm-none-eabi-g++
CC=arm-none-eabi-gcc
AS=arm-none-eabi-gcc -x assembler-with-cpp
LD=arm-none-eabi-ld
CP=arm-none-eabi-objcopy
SZ=arm-none-eabi-size
HEX=$(CP) -O ihex
BIN=$(CP) -O binary -S
CUBE=cubeF1
BUILDDIR=build

# Names: 1st used for startup.s files, 2nd for driver directory, 3rd for specific system_stm32fxxxyz.c file and HAL device header file
arch_short=stm32f1xx
ARCH_short=STM32F1xx
arch_specific=stm32f103xb
MCU=-mcpu=cortex-m4 -mthumb
DEFS = -DSTM32F103xB
OPT = -Og

INCLUDE= -I. -I$(CUBE)/Drivers/CMSIS/Device/ST/$(ARCH_short)/Include -I$(CUBE)/Drivers/CMSIS/Core/Include -I$(CUBE)/Drivers/CMSIS/Include
ifeq ($(HAL),1)
HALDIR=$(CUBE)/Drivers/$(ARCH_short)_HAL_Driver
HALINCLDIR=$(HALDIR)/Inc
HALSRCDIR=$(HALDIR)/Src
INCLUDE += -I$(HALINCLDIR)
HALMODULES = cortex tim tim_ex gpio dac dma rcc 
HALOBJS = $(arch_short)_hal.o $(patsubst %,$(arch_short)_hal_%.o,$(HALMODULES))
endif


ASFLAGS=$(MCU) -c -Wall -fdata-sections -ffunction-sections
CFLAGS=$(MCU) $(OPT) $(INCLUDE) $(DEFS)
ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif
# I don't bother adding the fine-grained dependencies
#CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"
CPPFLAGS=$(CFLAGS)

OBJS=$(CPPSRC:.cpp=.obj) $(CSRC:.c=.o) startup_$(arch_specific).o system_$(arch_short).o $(HALOBJS)
BUILDOBJS=$(patsubst %,$(BUILDDIR)/%,$(OBJS))

LDSCRIPT = STM32F103XB_FLASH.ld
LIBS=-lc -lm -lnosys
LIBDIR=
LDFLAGS=$(MCU) -specs=nosys.specs -T$(LDSCRIPT) $(LIBDIR) $(LIBS) -Wl,-Map=$(TARGET).map,--cref

all: $(TARGET).bin

clean:
	$(RM) -rf *.d *.o *.obj *.map $(TARGET).elf $(TARGET).hex $(TARGET).bin build/*

flash:
	$(FLASH) write $(TARGET).elf 0x8000000

$(TARGET).hex: $(TARGET).elf
	$(HEX) $< $@

$(TARGET).bin: $(TARGET).elf
	$(BIN) $< $@

$(TARGET).elf: $(BUILDOBJS)
	$(CC) $(LDFLAGS) -o $@ $^
	$(SZ) $@

$(BUILDDIR)/%.obj: %.cpp 
	$(CPP) $(CPPFLAGS) -o $@ -c $<

$(BUILDDIR)/%.o: %.c
	$(CC) $(CFLAGS) -o $@ -c $<

$(BUILDDIR)/%.o: %.s
	$(AS) $(ASFLAGS) -o $@ -c $<

$(BUILDDIR)/%.o: $(HALSRCDIR)/%.c
	$(CC) $(CFLAGS) -o $@ -c $<

.PHONY: clean all flash

