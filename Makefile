all : image.elf

TARGET_OUT:=image.elf
IMG_PREFIX:=img_
OBJS:=driver/uart.o \
	user/mystuff.o \
	user/ws2812.o \
	user/user_main.o

SRCS:=driver/uart.c \
	user/mystuff.c \
	user/ws2812.c \
	user/user_main.c

GCC_FOLDER:=/home/mc/esp-open-sdk/xtensa-lx106-elf
ESPTOOL_PY:=$(GCC_FOLDER)/bin/esptool.py
SDK:=/home/mc/esp-open-sdk/sdk
PORT:=/dev/ttyUSB0

XTLIB:=$(SDK)/lib
XTGCCLIB:=$(GCC_FOLDER)/lib/gcc/xtensa-lx106-elf/4.8.2
CC:=$(GCC_FOLDER)/bin/xtensa-lx106-elf-gcc

# for compiler
#	-I <dir>	Add <dir> to the end of the main include path 
# for linker:
# 	-L DIRECTORY	Add DIRECTORY to library search path
#	-T FILE		Read linker script

LIBS:= lwip ssl net80211 wpa phy main pp gcc c
CFLAGS:=-v -mlongcalls -Os -nostdinc \
-I include \
-I user \
-I $(SDK)/include \
-I $(GCC_FOLDER)/xtensa-lx106-elf/include \
-I $(XTGCCLIB)/include/ 
									 
LDFLAGS_CORE:=-nostdlib \
	-Wl,--gc-sections \
	-Wl,--relax \
	-L $(XTLIB) \
	-L $(XTGCCLIB) \
	$(addprefix -l,$(LIBS)) \
	-T $(SDK)/ld/eagle.app.v6.ld

$(TARGET_OUT): $(SRCS)
	$(CC) $(CFLAGS) $^ -flto $(LDFLAGS_CORE) -o $@

create: $(TARGET_OUT)
	@echo "Creating firmware images $@"
	esptool.py elf2image -o$(IMG_PREFIX) $(TARGET_OUT)

burn: create
	($(ESPTOOL_PY) --port $(PORT) write_flash 0x00000 $(IMG_PREFIX)0x00000.bin \
		0x40000 $(IMG_PREFIX)0x40000.bin)	||(true)

clean:
	rm -rf user/*.o driver/*.o $(TARGET_OUT) $(IMG_PREFIX)0x00000.bin $(IMG_PREFIX)0x40000.bin