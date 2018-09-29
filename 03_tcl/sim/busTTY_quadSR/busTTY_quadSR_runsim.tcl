##************************************************************************
## @copyright   LGPLv3
## @author      akae
##
## @file        busTTY_quadSR_runsim.tcl
## @note
##
## @brief       starts simulation
## @details
##
## @date        2018-09-23
## @version     0.1
##************************************************************************



# start simulation, disable optimization
vsim -novopt -gDO_ALL_TEST=true work.busTTY_quadSR_tb

# load Waveform
do "../03_tcl/sim/busTTY_quadSR/busTTY_quadSR_waveform.do"

# sim until finish
run 9.5 us
