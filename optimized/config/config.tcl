set ::env(DESIGN_NAME) "mac8_dadda_pipeline"

set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_NET) "clk"

# Assignment target: 4 ns = 250 MHz
set ::env(CLOCK_PERIOD) "4.0"

set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"

# Same values as baseline for fair comparison
set ::env(FP_CORE_UTIL) "35"
set ::env(PL_TARGET_DENSITY) "0.45"

# Timing-oriented synthesis experiment
set ::env(SYNTH_STRATEGY) "DELAY 2"
set ::env(SYNTH_SIZING) 0
set ::env(SYNTH_BUFFERING) 1

# Same SDC used for friend-style pipelined MAC
set ::env(BASE_SDC_FILE) "$::env(DESIGN_DIR)/constraints.sdc"

# Same physical settings
set ::env(FP_CORE_UTIL) "35"
set ::env(PL_TARGET_DENSITY) "0.45"

# Timing-oriented synthesis
set ::env(SYNTH_STRATEGY) "DELAY 2"
set ::env(SYNTH_SIZING) 0
set ::env(SYNTH_BUFFERING) 1
