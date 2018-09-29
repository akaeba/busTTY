--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        busTTY_RSFF.vhd
-- @note        VHDL'93
--
-- @brief       RSFF
-- @details     Reset and Set Flip-Flop
--
-- @date        2018-09-29
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- busTTY_RSFF: Reset and Set Flip-Flop
entity busTTY_RSFF is
generic (
            RDOM    : boolean   := true;    --! Reset is dominant over Set
            RSTQ    : bit       := '0'      --! Output in case of RESET=1 or R=1
        );
port    (
            -- Clock/Reset
            R       : in    std_logic;  --! asynchrony reset;
            C       : in    std_logic;  --! clock, rising edge
            -- FF
            RESET   : in    std_logic;  --! Reset
            SET     : in    std_logic;  --! Set
            Q       : out   std_logic   --! Output
        );
end entity busTTY_RSFF;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of busTTY_RSFF is
begin

    ----------------------------------------------
    -- shift register
    p_rsff : process ( R, C )
    begin
        if ( R = '1' ) then
            Q   <= to_stdulogic(RSTQ);
        elsif( rising_edge(C) ) then
            if ( RESET = '1' and SET = '0' ) then
                Q   <= to_stdulogic(RSTQ);
            elsif ( RESET = '0' and SET = '1' ) then
                Q   <= not to_stdulogic(RSTQ);
            else
                if ( RDOM = true ) then
                    Q   <= to_stdulogic(RSTQ);
                else
                    Q   <= not to_stdulogic(RSTQ);
                end if;
            end if;
        end if;
    end process p_rsff;
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
