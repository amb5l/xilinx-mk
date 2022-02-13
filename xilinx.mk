################################################################################
# xilinx.mk - makefile support for Xilinx designs
#
# To use, include at the end of a makefile that defines the following...
#	XILINX_MK				path to vivado_mk.tcl and vitis_mk.tcl
#	VIVADO_PROJ				Vivado project name
#	VIVADO_LANG				Vivado project language (VHDL or Verilog)
#	FPGA_PART				FPGA part number
#	VIVADO_DSN_TOP			top entity name for synthesis and implementation
# ...one or more of the following...
#	VIVADO_DSN_VHDL			design sources - VHDL (.vhd)
#	VIVADO_DSN_VHDL_2008	design sources - VHDL-2008 (.vhd)
#	VIVADO_DSN_IP_TCL		IP core creation TCL scripts (.tcl)
#	VIVADO_DSN_BD_TCL		block diagram creation TCL scripts (.tcl)
# ...and optionally one of more of the following...
#	VIVADO_DSN_XDC			design constraints (.xdc) (synthesis and implementation)
#	VIVADO_DSN_XDC_SYNTH	design constraints (.xdc) (synthesis only)
#	VIVADO_DSN_XDC_IMPL		design constraints (.xdc) (implementation only)
#	VIVADO_DSN_PROC_INST	processor instance name
#	VIVADO_DSN_PROC_REF		processor module reference (block diagram name)
#	VIVADO_DSN_ELF_CFG		build configuration for processor ELF file for implementation
#
# To include simulation support, define the following...
#	VIVADO_SIM_TOP			top entity name for simulation
# ...and one or more of the following...
#	VIVADO_SIM_VHDL			simulation sources - VHDL (.vhd)
#	VIVADO_SIM_VHDL_2008	simulation sources - VHDL-2008 (.vhd)
# ...and optionally one or more of the following...
#	VIVADO_SIM_IP_VHDL		IP simulation models (.vhd)
#	VIVADO_SIM_ELF_CFG		build configuration for processor ELF file for simulation
#
# If the design includes a CPU in an IP integrator block diagram,
# the following should be defined...
#	VITIS_APP				app name
#	VITIS_SRC				sources (.c, .h etc)
# ...and optionally one or more of the following...
#	VITIS_INCLUDE			include paths (Release and Debug configurations)
#	VITIS_INCLUDE_RELEASE	include paths (Release configuration only)
#	VITIS_INCLUDE_DEBUG		include paths (Debug configuration only)
#	VITIS_SYMBOLS			symbols (Release and Debug configurations)
#	VITIS_SYMBOLS_RELEASE	symbols (Release configuration only)
#	VITIS_SYMBOLS_DEBUG		symbols (Debug configuration only)
#
# to do: support synthesis and implementation strategies
################################################################################
# Vitis variables

ifdef VITIS_APP

VITIS_DIR=vitis
VITIS_MK=xsct $(XILINX_MK)/vitis_mk.tcl $(VITIS_DIR) $(VITIS_APP)
VITIS_PROJ_FILE=$(VITIS_DIR)/$(VITIS_APP)/$(VITIS_APP).prj
VITIS_ELF_RELEASE=$(VITIS_DIR)/$(VITIS_APP)/Release/$(VITIS_APP).elf
VITIS_ELF_DEBUG=$(VITIS_DIR)/$(VITIS_APP)/Debug/$(VITIS_APP).elf

endif

################################################################################
# Vivado variables

# override this on the make command line
VIVADO_JOBS=4

VIVADO_DIR=vivado
VIVADO_MK=vivado -mode tcl -notrace -nolog -nojournal -source $(XILINX_MK)/vivado_mk.tcl -tclargs $(VIVADO_DIR) $(VIVADO_PROJ)
VIVADO_PROJ_FILE=$(VIVADO_DIR)/$(VIVADO_PROJ).xpr
VIVADO_BIT_FILE=$(VIVADO_DIR)/$(VIVADO_DSN_TOP).bit
VIVADO_IMPL_FILE=$(VIVADO_DIR)/$(VIVADO_PROJ).runs/impl_1/$(VIVADO_DSN_TOP)_routed.dcp
VIVADO_SYNTH_FILE=$(VIVADO_DIR)/$(VIVADO_PROJ).runs/synth_1/$(VIVADO_DSN_TOP).dcp
VIVADO_XSA_FILE=$(VIVADO_DIR)/$(VIVADO_DSN_TOP).xsa
VIVADO_DSN_IP_PATH=$(VIVADO_DIR)/$(VIVADO_PROJ).srcs/sources_1/ip
VIVADO_BD_PATH=$(VIVADO_DIR)/$(VIVADO_PROJ).srcs/sources_1/bd
VIVADO_BD_HWDEF_PATH=$(VIVADO_DIR)/$(VIVADO_PROJ).gen/sources_1/bd
VIVADO_SIM_PATH=$(VIVADO_DIR)/$(VIVADO_PROJ).sim/sim_1/behav/xsim
VIVADO_SIM_IP_PATH=$(VIVADO_DIR)/$(VIVADO_PROJ).gen/sources_1/ip
VIVADO_DSN_ELF=$(VITIS_DIR)/$(VITIS_APP)/$(VIVADO_DSN_ELF_CFG)/$(VITIS_APP).elf
VIVADO_SIM_ELF=$(VITIS_DIR)/$(VITIS_APP)/$(VIVADO_SIM_ELF_CFG)/$(VITIS_APP).elf

# related file lists
VIVADO_DSN_IP_XCI=$(foreach X,$(basename $(notdir $(VIVADO_DSN_IP_TCL))),$(VIVADO_DSN_IP_PATH)/$X/$X.xci)
VIVADO_DSN_BD=$(foreach X,$(basename $(notdir $(VIVADO_DSN_BD_TCL))),$(VIVADO_BD_PATH)/$X/$X.bd)
VIVADO_DSN_BD_HWDEF=$(foreach X,$(basename $(notdir $(VIVADO_DSN_BD_TCL))),$(VIVADO_BD_HWDEF_PATH)/$X/synth/$X.hwdef)
VIVADO_UPD_BD_TCL=$(VIVADO_DSN_BD_TCL:.tcl=_updated.tcl)
VIVADO_UPD_BD_SVG=$(VIVADO_DSN_BD_TCL:.tcl=_updated.svg)
VIVADO_SIM_IP_FILES=$(foreach X,$(basename $(notdir $(VIVADO_DSN_IP_TCL))),$(addprefix $(VIVADO_SIM_IP_PATH)/,$(VIVADO_SIM_IP_$X)))

################################################################################
# runtime rules

# build IP core XCI files and simulation models from TCL scripts
define RR_VIVADO_IP_XCI
$(1) $(foreach X,$(VIVADO_SIM_IP_$(basename $(notdir $(2)))),$(VIVADO_SIM_IP_PATH)/$X) &: $(2) | $(VIVADO_PROJ_FILE)
	$(VIVADO_MK) build ip ../$(1) $(2) $(foreach X,$(VIVADO_SIM_IP_$(basename $(notdir $(2)))),../$(VIVADO_SIM_IP_PATH)/$X)
endef

# build BD hardware definitions from BD files
define RR_VIVADO_BD_HWDEF
$(1): $(2) | $(VIVADO_PROJ_FILE)
	$(VIVADO_MK) build hwdef ../$(2)
endef

# build BD files from BD TCL scripts
define RR_VIVADO_BD
$(1): $(2) | $(VIVADO_PROJ_FILE)
	$(VIVADO_MK) build bd ../$(1) $(2)
endef

# build updated BD TCL scripts from BD files
define RR_VIVADO_BD_TCL
$(1): $(2)| $(VIVADO_PROJ_FILE)
	$(VIVADO_MK) build bd_tcl $$@
endef

# build updated BD SVG files from BD files
define RR_VIVADO_BD_SVG
$(1): $(2) | $(VIVADO_PROJ_FILE)
	$(VIVADO_MK) build bd_svg $$@
endef

################################################################################
# basic checks

ifndef VIVADO_PROJ
$(error VIVADO_PROJ is not set)
endif
ifndef VIVADO_LANG
$(error VIVADO_LANG is not set)
endif
ifndef FPGA_PART
$(error FPGA_PART is not set)
endif
ifndef VIVADO_DSN_TOP
$(error VIVADO_DSN_TOP is not set)
endif

################################################################################

# cannot open the same project in multiple instances of Vivado or Vitis
.NOTPARALLEL:

################################################################################
# Vivado rules and recipes

# program FPGA
prog: $(VIVADO_BIT_FILE)
	$(VIVADO_MK) prog $<

# bit file depends on implementation file
bit: $(VIVADO_BIT_FILE)
$(VIVADO_BIT_FILE): $(VIVADO_IMPL_FILE)
	$(VIVADO_MK) build bit ../$@

# implementation file depends on synthesis file, ELF file, and relevant constraints (and existence of project)
$(VIVADO_IMPL_FILE): $(VIVADO_SYNTH_FILE) $(VIVADO_DSN_ELF) $(VIVADO_DSN_XDC_IMPL) $(VIVADO_DSN_XDC) | $(VIVADO_PROJ_FILE)
	$(VIVADO_MK) build impl $(VIVADO_JOBS) $(VIVADO_DSN_PROC_INST) $(VIVADO_DSN_PROC_REF) ../$(VIVADO_DSN_ELF)

# synthesis file depends design sources and relevant constraints (and existence of project)
$(VIVADO_SYNTH_FILE): $(VIVADO_DSN_IP_XCI) $(VIVADO_DSN_BD_HWDEF) $(VIVADO_DSN_VHDL) $(VIVADO_DSN_VHDL_2008) $(VIVADO_DSN_XDC_SYNTH) $(VIVADO_DSN_XDC) | $(VIVADO_PROJ_FILE)
	$(VIVADO_MK) build synth $(VIVADO_JOBS)

# IP XCI files and simulation models depend on IP TCL scripts (and existence of project)
$(foreach X,$(VIVADO_DSN_IP_TCL),$(eval $(call RR_VIVADO_IP_XCI,$(VIVADO_DSN_IP_PATH)/$(basename $(notdir $X))/$(basename $(notdir $X)).xci,$X)))

# hardware handoff (XSA) file depends on BD hwdef(s) (and existence of project)
$(VIVADO_XSA_FILE): $(VIVADO_DSN_BD_HWDEF) | $(VIVADO_PROJ_FILE)
	$(VIVADO_MK) build xsa

# BD hardware definitions depend on BD files (and existence of project)
$(foreach X,$(VIVADO_DSN_BD_TCL),$(eval $(call RR_VIVADO_BD_HWDEF,$(VIVADO_BD_HWDEF_PATH)/$(basename $(notdir $X))/synth/$(basename $(notdir $X)).hwdef,$(VIVADO_BD_PATH)/$(basename $(notdir $X))/$(basename $(notdir $X)).bd)))

# BD files depend on BD TCL scripts (and existence of project)
$(foreach X,$(VIVADO_DSN_BD_TCL),$(eval $(call RR_VIVADO_BD,$(VIVADO_BD_PATH)/$(basename $(notdir $X))/$(basename $(notdir $X)).bd,$X)))

# Vivado project file depends on makefile, and existence of all design and simulation sources
$(VIVADO_PROJ_FILE): makefile | $(VIVADO_DSN_IP_TCL) $(VIVADO_DSN_BD_TCL) $(VIVADO_DSN_VHDL) $(VIVADO_DSN_VHDL_2008) $(VIVADO_DSN_XDC) $(VIVADO_DSN_XDC_SYNTH) $(VIVADO_DSN_XDC_IMPL) $(VIVADO_SIM_VHDL) $(VIVADO_SIM_VHDL_2008)
	$(VIVADO_MK) create $(VIVADO_LANG) $(FPGA_PART) \
		dsn_vhdl:       $(VIVADO_DSN_VHDL) \
		dsn_vhdl_2008:  $(VIVADO_DSN_VHDL_2008) \
		dsn_xdc:        $(VIVADO_DSN_XDC) \
		dsn_xdc_synth:  $(VIVADO_DSN_XDC_SYNTH) \
		dsn_xdc_impl:   $(VIVADO_DSN_XDC_IMPL) \
		dsn_top:        $(VIVADO_DSN_TOP) \
		sim_vhdl:       $(VIVADO_SIM_VHDL) \
		sim_vhdl_2008:  $(VIVADO_SIM_VHDL_2008) \
		sim_top:        $(VIVADO_SIM_TOP)

# update BD source TCL scripts and SVG files from changed BD files
update_bd: $(VIVADO_UPD_BD_TCL) $(VIVADO_UPD_BD_SVG)
$(foreach X,$(VIVADO_DSN_BD_TCL),$(eval $(call RR_VIVADO_BD_TCL,$(X:.tcl=_updated.tcl),$(VIVADO_BD_PATH)/$(basename $(notdir $X))/$(basename $(notdir $X)).bd)))
$(foreach X,$(VIVADO_DSN_BD_TCL),$(eval $(call RR_VIVADO_BD_SVG,$(X:.tcl=_updated.svg),$(VIVADO_BD_PATH)/$(basename $(notdir $X))/$(basename $(notdir $X)).bd)))

# run simulation
sim: $(VIVADO_SIM_PATH)/$(VIVADO_SIM_FILE)
$(VIVADO_SIM_PATH)/$(VIVADO_SIM_FILE): $(VIVADO_SIM_VHDL) $(VIVADO_SIM_VHDL_2008) $(VIVADO_SIM_IP_FILES) | $(VIVADO_PROJ_FILE)
	$(VIVADO_MK) simulate ../$(VIVADO_SIM_ELF) $(VIVADO_DSN_PROC_INST) $(VIVADO_DSN_PROC_REF) $(VIVADO_SIM_ELF)

################################################################################
# Vitis rules and recipes

ifdef VITIS_APP

# ELF files depend on XSA file and source (and existence of project)
elf: $(VITIS_ELF_RELEASE) $(VITIS_ELF_DEBUG)
$(VITIS_ELF_RELEASE) : $(VIVADO_XSA_FILE) $(VITIS_SRC) $(VITIS_SRC_RELEASE) | $(VITIS_PROJ_FILE)
	$(VITIS_MK) build release $(VITIS_APP)
$(VITIS_ELF_DEBUG) : $(VIVADO_XSA_FILE) $(VITIS_SRC) $(VITIS_SRC_DEBUG) | $(VITIS_PROJ_FILE)
	$(VITIS_MK) build debug $(VITIS_APP)

# Vitis project depends on makefile (and existence of XSA file)
$(VITIS_PROJ_FILE): makefile | $(VIVADO_XSA_FILE)
	$(VITIS_MK) create $(VITIS_APP) ../$(VIVADO_XSA_FILE) $(VIVADO_DSN_PROC_INST) \
		src:     $(VITIS_SRC) \
		inc:     $(VITIS_INCLUDE) \
		inc_rls: $(VITIS_INCLUDE_RELEASE) \
		inc_dbg: $(VITIS_INCLUDE_DEBUG) \
		sym:     $(VITIS_SYMBOL) \
		sym_rls: $(VITIS_SYMBOL_RELEASE) \
		sym_dbg: $(VITIS_SYMBOL_DEBUG)

endif

################################################################################
# clean up

.PHONY: clean
clean:
	rm -r $(VIVADO_DIR)
	rm -r $(VITIS_DIR)
