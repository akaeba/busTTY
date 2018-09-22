##************************************************************************
## @copyright   LGPLv3
## @author      akae
##
## @file        busTTY_ascii2hex_runsim.tcl
##
## @brief       compile script
## @details
##
## @date        2018-07-29
## @version     0.1
##************************************************************************



# path setting
#
set path_tb "../02_tb"
set path_src "../01_src"
#



# Compile Design
#
vcom -93 $path_src/busTTY_ascii2hex.vhd
#


# Compile TB
#
vcom -93 $path_tb/busTTY_ascii2hex_tb.vhd
#
