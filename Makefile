SRCS = boot_code.c
ASM_SRCS = crt0.S

BUILDDIR ?= $(CURDIR)/build

BOOTCODE = $(BUILDDIR)/bootcode

PULP_CC = riscv32-unknown-elf-gcc
PULP_LD = riscv32-unknown-elf-gcc

ifndef VERBOSE
V = @
endif

LDFLAGS += -Tlink.ld -nostdlib
CFLAGS += -Os -g -fno-jump-tables -I$(CURDIR)/include

OBJS += $(patsubst %.c,$(BUILDDIR)/%.o,$(SRCS))
OBJS += $(patsubst %.S,$(BUILDDIR)/%.o,$(ASM_SRCS))

all: $(BOOTCODE) stimuli

clean:
	rm -rf $(BUILDDIR)

$(BUILDDIR)/%.o: %.c
	@echo "CC  $<"
	$(V)mkdir -p `dirname $@`
	$(V)$(PULP_CC) -c $< -o $@ -MMD -MP $(CFLAGS)

$(BUILDDIR)/%.o: %.S
	@echo "CC  $<"
	$(V)mkdir -p `dirname $@`
	$(V)$(PULP_CC) -c $< -o $@ -MMD -MP -DLANGUAGE_ASSEMBLY $(CFLAGS)

$(BOOTCODE): $(OBJS)
	@echo "LD  $@"
	$(V)mkdir -p `dirname $@`
	$(V)$(PULP_LD) -o $@ $^ -MMD -MP $(LDFLAGS)

stimuli.gvsoc:
	./stim_utils.py  \
		--binary=$(BOOTCODE) \
		--stim-bin=rom.bin \
		--area=0x1a000000:0x01000000
		
stimuli.rtl:
	objcopy --srec-len 1 --output-target=srec $(BOOTCODE) $(BOOTCODE).s19
	./s19toboot.py $(BOOTCODE).s19 boot_code.cde pulp

stimuli: stimuli.gvsoc stimuli.rtl
