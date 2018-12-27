##************************************************************************
## @copyright   LGPLv3
## @author      akae
##
## @file        busTTY_FSM_runsim.tcl
## @note
##
## @brief       starts simulation
## @details
##
## @date        2018-12-27
## @version     0.1
##************************************************************************



# start simulation, disable optimization
vsim -novopt -gDO_ALL_TEST=true work.busTTY_FSM_tb

# load Waveform
do "../03_tcl/sim/busTTY_FSM/busTTY_FSM_waveform.do"

# sim until finish
#run 9.5 us
