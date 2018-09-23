##************************************************************************
## @copyright   LGPLv3
## @author      akae
##
## @file        busTTY_quadSR_compile.tcl
##
## @brief       compile script
## @details
##
## @date        2018-09-23
## @version     0.1
##************************************************************************



# path setting
#
set path_tb "../02_tb"
set path_src "../01_src"
#



# Compile Design
#
vcom -93 $path_src/busTTY_quadSR.vhd
#


# Compile TB
#
vcom -93 $path_tb/busTTY_quadSR_tb.vhd
#
