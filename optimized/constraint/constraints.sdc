###############################################################################
# Assignment-2 Timing Constraints
# Target Clock = 4 ns = 250 MHz
###############################################################################

create_clock -name clk -period 4.000 [get_ports clk]

# Clock
set_clock_uncertainty 0.200 [get_clocks clk]
set_clock_transition  0.150 [get_clocks clk]

# Input delays
set_input_delay -max 0.800 -clock clk [get_ports reset]
set_input_delay -max 0.800 -clock clk [get_ports enable]
set_input_delay -max 0.800 -clock clk [get_ports {A[*]}]
set_input_delay -max 0.800 -clock clk [get_ports {B[*]}]

set_input_delay -min 0.200 -clock clk [get_ports reset]
set_input_delay -min 0.200 -clock clk [get_ports enable]
set_input_delay -min 0.200 -clock clk [get_ports {A[*]}]
set_input_delay -min 0.200 -clock clk [get_ports {B[*]}]

# Output delays
set_output_delay -max 0.800 -clock clk [get_ports {Y[*]}]
set_output_delay -min 0.100 -clock clk [get_ports {Y[*]}]

# Output load
set_load -pin_load 0.035 [get_ports {Y[*]}]

# Input driver
set_driving_cell \
    -lib_cell sky130_fd_sc_hd__buf_2 \
    [get_ports {reset enable A[*] B[*]}]
