--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        busTTY_quadSR.vhd
-- @note        VHDL'93
--
-- @brief       quadruple shift register
-- @details     shift register with parallel in/out and a quadruple
--              (4bit) serial input and shift forward/backward (up/down)
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
-- busTTY_quadSR: quadruple shift register
entity busTTY_quadSR is
generic (
            STAGES  : positive := 2     --! number of quadruple stages
        );
port    (
            -- Clock/Reset
            R       : in    std_logic;      --! asynchrony reset
            C       : in    std_logic;      --! clock, rising edge
            -- Control
            UP      : in    std_logic;      --! shift direction; 1: up (from lower QUAD to upper QUAD), 0: down (from upper QUAD to lower QUAD)
            EN      : in    std_logic;      --! enable shift
            LD      : in    std_logic;      --! load shift register, dominant over enable
            -- data
            QUAD    : in    std_logic_vector(3 downto 0);           --! serial input in quadruples
            D       : in    std_logic_vector(STAGES*4-1 downto 0);  --! parallel data input
            Q       : out   std_logic_vector(STAGES*4-1 downto 0)   --! parallel data output
        );
end entity busTTY_quadSR;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of busTTY_quadSR is

    -----------------------------
    -- Types
    type t_quadSR is array (0 to STAGES-1) of std_logic_vector(3 downto 0);
    -----------------------------

    -----------------------------
    -- Signals
    signal shift_reg : t_quadSR;    --! define shift register
    -----------------------------

begin

    ----------------------------------------------
    -- shift register
    p_sreg : process ( R, C )
    begin
        if ( R = '1' ) then
            shift_reg   <= (others => (others => '0'));     --! reset registers
        elsif( rising_edge(C) ) then
            if ( LD = '1' ) then
                for i in 0 to STAGES-1 loop
                    shift_reg(i) <= D(i*4+3 downto i*4);    --! assign to shift register
                end loop;
            elsif ( EN = '1' ) then
                if ( UP = '1' ) then
                    for i in STAGES-1 downto 1 loop
                        shift_reg(i) <= shift_reg(i-1);     --! shift up
                    end loop;
                    shift_reg(0) <= QUAD;                   --! fill new data in
                else
                    for i in 0 to STAGES-2 loop
                        shift_reg(i) <= shift_reg(i+1);     --! shift down
                    end loop;
                    shift_reg(STAGES-1) <= (others => '0'); --! pad with zero
                end if;
            end if;
        end if;
    end process p_sreg;
    ----------------------------------------------

    ----------------------------------------------
    -- Output
    g_Q : for i in 0 to STAGES-1 generate
        Q(i*4+3 downto i*4) <= shift_reg(i);
    end generate g_Q;
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
