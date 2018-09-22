--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        busTTY_ascii2hex.vhd
-- @note        VHDL'93
--
-- @brief       ASCII to hex number
-- @details     converts a ASCII encoded 8bit input hexadecimal character
--              into the corresponding hexadecimal number
--
-- @date        2018-09-22
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- busTTY_ascii2hex: converts from ASCII encoded hex to hex numbers
entity busTTY_ascii2hex is
port    (
            CHAR        : in    std_logic_vector(7 downto 0);   --! ASCII encoded 8bit hexadecimal character
            HEX         : out   std_logic_vector(3 downto 0);   --! hexadecimal number
            NOHEXCHAR   : out   std_logic                       --! provided character is not a hexadecimal character
        );
end entity busTTY_ascii2hex;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of busTTY_ascii2hex is
begin

    ----------------------------------------------
    -- character to hex
    with to_integer(to_01(unsigned(CHAR))) select HEX <=
        -- decimal numbers
        x"0"    when character'pos('0'),
        x"1"    when character'pos('1'),
        x"2"    when character'pos('2'),
        x"3"    when character'pos('3'),
        x"4"    when character'pos('4'),
        x"5"    when character'pos('5'),
        x"6"    when character'pos('6'),
        x"7"    when character'pos('7'),
        x"8"    when character'pos('8'),
        x"9"    when character'pos('9'),
        -- lower case hex numbers
        x"A"    when character'pos('a'),
        x"B"    when character'pos('b'),
        x"C"    when character'pos('c'),
        x"D"    when character'pos('d'),
        x"E"    when character'pos('e'),
        x"F"    when character'pos('f'),
        -- upper case hex numbers
        x"A"    when character'pos('A'),
        x"B"    when character'pos('B'),
        x"C"    when character'pos('C'),
        x"D"    when character'pos('D'),
        x"E"    when character'pos('E'),
        x"F"    when character'pos('F'),
        -- non hexadecimal ASCII number
        x"0"    when others;
    ----------------------------------------------


    ----------------------------------------------
    -- non ASCII hexadecimal flag
    with to_integer(to_01(unsigned(CHAR))) select NOHEXCHAR <=
        -- decimal numbers
        '0'     when character'pos('0'),
        '0'     when character'pos('1'),
        '0'     when character'pos('2'),
        '0'     when character'pos('3'),
        '0'     when character'pos('4'),
        '0'     when character'pos('5'),
        '0'     when character'pos('6'),
        '0'     when character'pos('7'),
        '0'     when character'pos('8'),
        '0'     when character'pos('9'),
        -- lower case hex numbers
        '0'     when character'pos('a'),
        '0'     when character'pos('b'),
        '0'     when character'pos('c'),
        '0'     when character'pos('d'),
        '0'     when character'pos('e'),
        '0'     when character'pos('f'),
        -- upper case hex numbers
        '0'     when character'pos('A'),
        '0'     when character'pos('B'),
        '0'     when character'pos('C'),
        '0'     when character'pos('D'),
        '0'     when character'pos('E'),
        '0'     when character'pos('F'),
        -- non hexadecimal ASCII number
        '1'     when others;
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
