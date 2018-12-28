--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        busTTYpkg.vhd
-- @note        VHDL'93
--
-- @brief       busTTY related definitions
-- @details     collects module common used definitions and
--              also configurations
--
-- @date        2018-09-30
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- busTTYpkg: common definitions
package busTTYpkg is

    -----------------------------
    -- operation: quad shift register
    constant C_QSR_IST_LEN  : integer                                       := 3;
    constant C_QSR_OP_NOP   : std_logic_vector(C_QSR_IST_LEN-1 downto 0)    := std_logic_vector(to_unsigned(0, C_QSR_IST_LEN)); --! do nothing, hold
    constant C_QSR_OP_CLR   : std_logic_vector(C_QSR_IST_LEN-1 downto 0)    := std_logic_vector(to_unsigned(1, C_QSR_IST_LEN)); --! clear register
    constant C_QSR_OP_INC   : std_logic_vector(C_QSR_IST_LEN-1 downto 0)    := std_logic_vector(to_unsigned(2, C_QSR_IST_LEN)); --! increment
    constant C_QSR_OP_DEC   : std_logic_vector(C_QSR_IST_LEN-1 downto 0)    := std_logic_vector(to_unsigned(3, C_QSR_IST_LEN)); --! decrement
    constant C_QSR_OP_SLD   : std_logic_vector(C_QSR_IST_LEN-1 downto 0)    := std_logic_vector(to_unsigned(4, C_QSR_IST_LEN)); --! serial load
    constant C_QSR_OP_PLD   : std_logic_vector(C_QSR_IST_LEN-1 downto 0)    := std_logic_vector(to_unsigned(5, C_QSR_IST_LEN)); --! parallel load


    -----------------------------
    -- operation: UART mux
    constant C_UART_MUX_LEN     : integer                                       := 3;
    constant C_UART_MUX_NUL     : std_logic_vector(C_UART_MUX_LEN-1 downto 0)   := std_logic_vector(to_unsigned(0, C_UART_MUX_LEN));    --! do nothing
    constant C_UART_MUX_MSG     : std_logic_vector(C_UART_MUX_LEN-1 downto 0)   := std_logic_vector(to_unsigned(1, C_UART_MUX_LEN));    --! play message from ROM
    constant C_UART_MUX_QSR     : std_logic_vector(C_UART_MUX_LEN-1 downto 0)   := std_logic_vector(to_unsigned(2, C_UART_MUX_LEN));    --! release from Quad shift register
    constant C_UART_MUX_RX      : std_logic_vector(C_UART_MUX_LEN-1 downto 0)   := std_logic_vector(to_unsigned(3, C_UART_MUX_LEN));    --! loop back
    constant C_UART_MUX_BLNK    : std_logic_vector(C_UART_MUX_LEN-1 downto 0)   := std_logic_vector(to_unsigned(4, C_UART_MUX_LEN));    --! send blank


    -----------------------------
    -- ROM messages start addresses
    constant C_MSG_LOGON        : integer := 0; --! logon, TODO
    constant C_MSG_HELP         : integer := 0; --! help
    constant C_MSG_NEW_LINE     : integer := 0; --! new line
    constant C_MSG_INC_CMD      : integer := 0; --! incomplete command sent
    constant C_MSG_UNEXP_INP    : integer := 0; --! unexpected input
    constant C_MSG_MEMIF_STUCK  : integer := 0; --! stuck on memory IF


    -----------------------------
    -- ASCII Operators
    constant C_ASCII_WR_0   : integer   := character'pos('w');  --! ASCII encoded
    constant C_ASCII_WR_1   : integer   := character'pos('W');  --!
    constant C_ASCII_RD_0   : integer   := character'pos('r');  --!
    constant C_ASCII_RD_1   : integer   := character'pos('R');  --!




end package busTTYpkg;
--------------------------------------------------------------------------
