SRCS = boot_code.c
ASM_SRCS = crt0.S

BUILDDIR ?= $(CURDIR)/build

BOOTCODE = $(BUILDDIR)/bootcode

#include $(RULES_DIR)/pmsis_rules.mk

# PULP rules
#PULP_CC ?= riscv32-unknown-elf-gcc -D__riscv__ -march=rv32imcxgap9 #-DARCHI_CORE_HAS_PULPV2
#PULP_LD ?= riscv32-unknown-elf-gcc -D__riscv__  -march=rv32imcxgap9

#CoreV rules
PULP_CC=riscv32-corev-elf-gcc -D__riscv__
PULP_LD=riscv32-corev-elf-gcc -D__riscv__ 

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
