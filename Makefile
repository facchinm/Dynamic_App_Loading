
#################### CONFIGURABLE SECTION ###########################
# Target can be anything you want. It will create an elf and bin file
# with this name
TARGET = main

# The following three item are the most important to change
# Change this based on chip architecture
MCU = STM32F429xx
MCU_DIR = ./include/STM32F4xx/
MCU_SPEC  = cortex-m4
FLOAT_SPEC = -mfloat-abi=hard -mfpu=fpv4-sp-d16

# Set the Highspeed external clock value (HSE)
HSE_VAL = 8000000

# Enable ARM Semihosting support
ENABLE_SEMIHOSTING ?= 0

# Define the linker script location
LD_SCRIPT = linker.ld

# set the path to FreeRTOS package
RTOS_DIR 		= ./components/FreeRTOS-Kernel
# Modify this to the path where your micrcontroller specific port is
RTOS_DIR_MCU 	= $(RTOS_DIR)/portable/GCC/ARM_CM4F
RTOS_HEAP 		= $(RTOS_DIR)/portable/MemMang/heap_4.c

# Dont need to change this if MCU is defined correctly
# It will add for eg: startup_stm2f429xx.s file to the $(ASM_SOURCES)
STARTUP_FILE = $(MCU_DIR)/Source/Templates/gcc/startup_$(shell echo "$(MCU)" | awk '{print tolower($$0)}').s

# Select 1 if STM32 HAL library is to be used. This will add -DUSE_HAL_DRIVER=1 to the CFLAGS
# If enabled then set the correct path of the HAL Driver folder
USE_HAL = 1
ifeq (1,$(USE_HAL))
	HAL_SRC = ./components/STM32F4xx_HAL_Driver/Src
	HAL_INC = ./components/STM32F4xx_HAL_Driver/Inc
endif
# Add assembler and C files to this
AS_SRC_DIR    = src
C_SRC_DIR     = src
INCLUDE_DIR   = include $(RTOS_DIR)/include $(RTOS_DIR_MCU) $(CMSIS_DIR)/Core/Include $(MCU_DIR)/Include $(HAL_INC)
LIBS_SRC_DIR  = $(RTOS_DIR) $(RTOS_DIR_MCU) $(MCU_DIR)/Source/Templates $(HAL_SRC)
USR_LIB_DIR   = lib
# Dynamic lib sources
DLIB_SRC_DIR  = 

# Toolchain definitions (ARM bare metal defaults)
# Set the TOOLCHAIN_PATH variable to the path where it is installed
# If it is accessible globally. ie it is in your system path ($PATH)
# then leave it blank. A slash at the end of the path is required
# eg: TOOLCHAIN_PATH = /usr/local/bin/
TOOLCHAIN_PATH = 
TOOLCHAIN = $(TOOLCHAIN_PATH)arm-none-eabi-
CC 	= $(TOOLCHAIN)gcc
AS 	= $(TOOLCHAIN)as
AR  =$(TOOLCHAIN)ar
LD 	= $(TOOLCHAIN)gcc
OC 	= $(TOOLCHAIN)objcopy
OD 	= $(TOOLCHAIN)objdump
OS 	= $(TOOLCHAIN)size
GDB = $(TOOLCHAIN)gdb-py

# System utilities
# Remove file and folders
RM 		= rm -rf
# Remove file
MKDIR 	= mkdir -p
# TTY for GDB Dashboard
GDB_TTY?=
######################################################################
.DELETE_ON_ERROR:

######################################################################
# Various sources files and objects
######################################################################
CMSIS_DIR = ./components/CMSIS/CMSIS/
TARGET_DIR = target
BUILD_DIR  = build

C_SRC     = $(foreach DIR, $(basename $(C_SRC_DIR)), $(wildcard $(DIR)/*.c)) $(RTOS_HEAP)
LIB_SRC   = $(foreach DIR, $(basename $(LIBS_SRC_DIR)), $(wildcard $(DIR)/*.c))
USR_SRC   = $(foreach DIR, $(basename $(USR_LIB_DIR)), $(wildcard $(DIR)/*.c)) 
AS_SRC_S  = $(foreach DIR, $(basename $(AS_SRC_DIR)), $(wildcard $(DIR)/*.S))
AS_SRC_s  = $(foreach DIR, $(basename $(AS_SRC_DIR)), $(wildcard $(DIR)/*.s)) $(foreach DIR, $(basename $(USR_LIB_DIR)), $(wildcard $(DIR)/*.s))


C_SOURCES = $(C_SRC) $(LIB_SRC) $(USR_SRC)
ASM_SOURCES = $(STARTUP_FILE) $(AS_SRC_S) $(AS_SRC_s)
USR_SOURCES = $(USR_SRC)

OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))
USR_OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(USR_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(USR_SOURCES)))

######################################################################
# Assembly directives.
######################################################################
ASFLAGS += -O0
ASFLAGS += -mcpu=$(MCU_SPEC)
ASFLAGS += -mthumb
ASFLAGS += -mthumb-interwork
ASFLAGS += -Wall
# (Set error messages to appear on a single line.)
ASFLAGS += -fmessage-length=0
ASFLAGS += $(FLOAT_SPEC)

######################################################################
# C compilation directives
######################################################################
CFLAGS += -mcpu=$(MCU_SPEC)
CFLAGS += -mthumb
CFLAGS += -mthumb-interwork
CFLAGS += -D$(MCU)
CFLAGS += -Wall
CFLAGS += -std=gnu99
CFLAGS += -g3
CFLAGS += -fomit-frame-pointer
CFLAGS += $(FLOAT_SPEC)
# (Set error messages to appear on a single line.)
CFLAGS += -fmessage-length=0
# Create separate sections for function and data
# so it can be garbage collected by linker
CFLAGS += -ffunction-sections
CFLAGS += -fdata-sections

ifeq (1,$(KERNEL))
	# Generate dependency information
	CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"
	# Add the include folders
	CFLAGS += $(foreach x, $(basename $(INCLUDE_DIR)), -I $(x))
	# Set KERNEL macro to build kernel APIs
	CFLAGS += -DKERNEL=1

	# C macros
	CFLAGS += -DHSE_VALUE=$(HSE_VAL)
	
	ifeq (1,$(USE_HAL))
		CFLAGS += -DUSE_HAL_DRIVER=1
	endif

	ifeq (1,$(ENABLE_SEMIHOSTING))
		CFLAGS += -DENABLE_SEMIHOSTING=1
	endif
endif

######################################################################
# Linker directives
######################################################################
LSCRIPT = ./$(LD_SCRIPT)

LFLAGS += $(CFLAGS)
#~ LFLAGS += -nostdlib
LFLAGS += -T$(LSCRIPT)
LFLAGS += -Wl,-Map=$(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).map
LFLAGS += -Wl,--print-memory-usage
LFLAGS += -Wl,--gc-sections

ifeq (1,$(ENABLE_SEMIHOSTING))
	LFLAGS += --specs=rdimon.specs -lc -lrdimon
else
	LFLAGS += --specs=nosys.specs
endif

# Dynamic lib Compilation flags
DLIB_CFLAGS += -mcpu=$(MCU_SPEC)
DLIB_CFLAGS += -mthumb
DLIB_CFLAGS += -Wall
DLIB_CFLAGS += -g3
DLIB_CFLAGS += -fmessage-length=0

# Dynamic lib linker flags
DLIB_LFLAGS += $(DLIB_SRC:%.c=-l%)

# List of dynamic libs
DLIBS       += $(DLIB_SRC:%.c=lib%.so)

# The following two lines are to remove the existing so and o files
DLIBS_SO  += $(DLIB_SRC:.c=.so)
DLIBS_O   += $(DLIB_SRC:.c=.o)

######################################################################
# File targets
######################################################################

# The PHONY keyword is required so that makefile does not
# consider the rule 'all' as a file
.PHONY: all
all: debug

# There should be a tab here on the line with $(CC), 4 spaces does not work
$(BUILD_DIR)/%.o: %.S Makefile | $(BUILD_DIR) 
	@ echo "[AS] $@"
	@ $(CC) -x assembler-with-cpp $(ASFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR) 
	@ echo "[AS] $@"
	@ $(CC) -x assembler-with-cpp $(ASFLAGS) -c $< -o $@

# If -c is used then it will create a reloc file ie normal object file
$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) 
	@ echo "[CC] $@"
	@ $(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@

# and not a dynamic object. For dynamic object -shared is required.
$(BUILD_DIR)/%.so: %.c Makefile | $(BUILD_DIR) 
	@ echo "[CC] $@"
	@ $(CC) -shared $(DLIB_CFLAGS) $< -o lib$@

$(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).diss: $(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).elf | $(BUILD_DIR)
	@ echo "[OD] $@"
	@ $(OD) -Dz --source $^ > $@

$(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).elf: $(OBJECTS) | $(BUILD_DIR)
	@ echo "[LD] $@"
	$(LD) $^ $(LFLAGS) -o $@

$(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).diss | $(BUILD_DIR)
	@ echo "[OC] $@"
	@ $(OC) -S -O binary $< $@
	@ echo "[OS] $@"
	@ $(OS) $<

$(BUILD_DIR)/$(TARGET_DIR)/lib$(TARGET).a: $(USR_OBJECTS) | $(BUILD_DIR)
	@ echo "[AR] $@"
	@ $(AR) -crv $@ $^
	@ echo "[OD] $@.diss"
	@ $(OD) -Dz --source $^ > $@.diss

apps/blinky.app:
	@ echo "Building App $@"
	$(CC) $(CFLAGS) -I ./include -c apps/blinky/main.c -o apps/blinky/main.o
	$(CC) $(CFLAGS) -T ./app_base.ld -Wl,--gc-sections --specs=nosys.specs -nostdlib apps/blinky/main.o $(BUILD_DIR)/$(TARGET_DIR)/lib$(TARGET).a -o apps/blinky/blinky.elf 
	$(OD) -Dz --source apps/blinky/blinky.elf > apps/blinky/blinky.diss

$(BUILD_DIR):
	@ $(MKDIR) $@/$(TARGET_DIR)

######################################################################
# @Target release
# @Brief Build executable with optimizations
######################################################################
.PHONY: release
release:DEBUG = 0
release: $(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).bin
	@ echo "Built release build"

######################################################################
# @Target debug
# @Brief Build executable with debug flags
######################################################################
.PHONY: debug
debug:DEBUG = 1
debug: $(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).bin
	@ echo "Built debug build"

######################################################################
# @Target userlib
# @Brief Build library for user dynamic application
######################################################################
.PHONY: userlib
userlib:DEBUG = 0
userlib:INCLUDE += -I ./include
userlib: $(BUILD_DIR)/$(TARGET_DIR)/lib$(TARGET).a
	@ echo "Built userlib"

######################################################################
# @Target clean
# @Brief Remove the target output files.
######################################################################
.PHONY: clean
clean:
	$(RM) $(BUILD_DIR)

######################################################################
# @Target flash
# @Brief Start GDB, connect to server and load the elf
######################################################################
.PHONY: flash
flash:
	@ pgrep -x "openocd" || (echo "Please start openocd"; exit -1)
	@ echo "Starting GDB client"
	@ $(GDB) -ex "target extended :3333" -ex "dashboard -output $(GDB_TTY)" -ex "load $(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).elf" -ex "monitor arm semihosting enable" $(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).elf

######################################################################
# @Target debug
# @Brief Start GDB and connect to server
######################################################################
#.PHONY: flash
#flash:
#	@pgrep -x "openocd" || (echo "Please start openocd"; exit -1)
#	@echo "Starting GDB client"	
#	$(GDB) -ex "dashboard -output $$GDB_DASHBOARD_TTY" -ex "target extended :3333" -ex "load $(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).elf" -ex "monitor arm semihosting enable" $(BUILD_DIR)/$(TARGET_DIR)/$(TARGET).elf

######################################################################
# @Target Dependencies
# @Brief 
######################################################################
-include $(wildcard $(BUILD_DIR)/*.d)
