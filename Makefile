PROJ=muse
BUILD_DIR=build/
BUILD_LOG=$(BUILD_DIR)build.log
SRCS:=$(PROJ).v hdmiController.v OBUFDS.v tmdsEncoder.v clock.v

$(BUILD_DIR)$(PROJ).svf: $(BUILD_DIR)$(PROJ).config
	source ~/fpga/oss-cad-suite/environment && ecppack --input $(BUILD_DIR)$(PROJ).config --svf $(BUILD_DIR)$(PROJ).svf >> $(BUILD_LOG)

$(BUILD_DIR)$(PROJ).config: $(BUILD_DIR)$(PROJ).json $(PROJ).lpf
	source ~/fpga/oss-cad-suite/environment && nextpnr-ecp5 --25k --package CABGA381 --json $(BUILD_DIR)$(PROJ).json --lpf $(PROJ).lpf --textcfg $(BUILD_DIR)$(PROJ).config >> $(BUILD_LOG)

$(BUILD_DIR)$(PROJ).json: $(SRCS)
	source ~/fpga/oss-cad-suite/environment && yosys -p "synth_ecp5 -top $(PROJ) -json $(BUILD_DIR)$(PROJ).json" $^ > $(BUILD_LOG)

prog:
	source ~/fpga/oss-cad-suite/environment && ~/fpga/Colorlight-FPGA-Projects/tools/dapprog $(BUILD_DIR)$(PROJ).svf

clean:
	rm build/*
