##************************************************************************
## @copyright   LGPLv3
## @author      akae
##
## @file        busTTY_FSM_compile.tcl
##
## @brief       compile script
## @details
##
## @date        2018-12-27
## @version     0.1
##************************************************************************



# path setting
#
set path_tb "../02_tb"
set path_src "../01_src"
#



# Compile Design
#
vcom -93 $path_src/busTTYpkg.vhd
vcom -93 $path_src/busTTY_FSM.vhd
#


# Compile TB
#
vcom -93 $path_tb/busTTY_FSM_tb.vhd
#
