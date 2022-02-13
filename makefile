################################################################################
# template makefile for driving Xilinx Vivado and Vitis
################################################################################

# suggestion:
# 1. Add xilinx-mk to your repo as a submodule.
# 2. Copy this makefile to your build directory (this is where the Vivado and
#    Vitis project will be created) and edit it to add your sources etc.
# 3. Use the following definitions:

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

################################################################################

# primary target
all: bit

################################################################################
# Vivado section

# project name
VIVADO_PROJ=fpga

# project language
VIVADO_LANG=VHDL

# FPGA part number
FPGA_PART=xc7a200tsbg484-1

# top entity names
VIVADO_DSN_TOP=top
VIVADO_SIM_TOP=tb_top

# design sources: VHDL
VIVADO_DSN_VHDL=
VIVADO_DSN_VHDL_2008=

# design sources: TCL scripts to create IP cores (TCL filename should match IP core name)
VIVADO_DSN_IP_TCL=

# design sources: TCL scripts to create block diagrams (TCL filename should match BD name)
VIVADO_DSN_BD_TCL=

# design constraints (synthesis and implementation)
VIVADO_DSN_XDC=

# design constraints (synthesis only)
VIVADO_DSN_XDC_SYNTH=

# design constraints (implementation only)
VIVADO_DSN_XDC_IMPL=

# processor instance name
VIVADO_DSN_PROC_INST=cpu

# block diagram name (module reference) that contains processor instance 
VIVADO_DSN_PROC_REF=microblaze

# build configuration of ELF file for implementation (Release or Debug)
VIVADO_DSN_ELF_CFG=Release

# simulation output file
VIVADO_SIM_FILE=simulate.log

# simulation sources: VHDL testbenches, models etc
VIVADO_SIM_VHDL=
VIVADO_SIM_VHDL_2008=

# IP core simulation models (suffix = IP core name e.g. ddr3)
# NOTE: these paths are relative to $(VIVADO_PROJ).gen/sources_1/ip
#VIVADO_SIM_IP_suffix=

# build configuration of ELF file for simulation (Release or Debug)
VIVADO_SIM_ELF_CFG=Debug

################################################################################
# Vitis section

# app name
VITIS_APP=

# Vitis app sources
VITIS_SRC=
	
# Vitis app include paths (Release and Debug configurations)
VITIS_INCLUDE=

# Vitis app include paths (Release configuration only)
VITIS_INCLUDE_RELEASE=

# Vitis app include paths (Debug configuration only)
VITIS_INCLUDE_DEBUG=

# Vitis app symbols (Release and Debug configurations)
VITIS_SYMBOL=

# Vitis app symbols (Release configuration only)
VITIS_SYMBOL_RELEASE=

# Vitis app symbols (Debug configuration only)
VITIS_SYMBOL_DEBUG=

################################################################################

include $(XILINX_MK)/xilinx.mk
