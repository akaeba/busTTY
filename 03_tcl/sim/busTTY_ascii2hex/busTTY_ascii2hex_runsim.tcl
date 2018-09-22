##************************************************************************
## @copyright   LGPLv3
## @author      akae
##
## @file        busTTY_ascii2hex_runsim.tcl
## @note
##
## @brief       starts simulation
## @details
##
## @date        2018-09-22
## @version     0.1
##************************************************************************



# start simulation, disable optimization
vsim -novopt -gDO_ALL_TEST=true work.busTTY_ascii2hex_tb

# load Waveform
do "../03_tcl/sim/busTTY_ascii2hex_tb/busTTY_ascii2hex_tb.do"

# sim until finish
run 1.5 us
