--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        busTTY_ascii2hex_tb.vhd
-- @note        VHDL'93
--
-- @brief       testbench
-- @details
--
-- @date        2018-09-22
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use ieee.math_real.all;         --! for UNIFORM, TRUNC
library work;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- testbench
entity busTTY_ascii2hex_tb is
generic (
            DO_ALL_TEST : boolean   := false        --! switch for enabling all tests
        );
end entity busTTY_ascii2hex_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of busTTY_ascii2hex_tb is

    -----------------------------
    -- Constant
        -- DUT

        -- Clock
        constant tclk   : time  := 20 ns;   --! 50MHz clock
        constant tskew  : time  := 1 ns;    --! data skew

        -- Test
        constant do_test_0  : boolean := true;  --! test0: check conversion
        constant do_test_1  : boolean := true;  --! test1: check flag for non hexadecimal number ASCII input
    -----------------------------

    -----------------------------
    -- Signals
        -- DUT
        signal CHAR         : std_logic_vector(7 downto 0);
        signal HEX          : std_logic_vector(3 downto 0);
        signal NOHEXCHAR    : std_logic;
    -----------------------------

begin

    ----------------------------------------------
    -- DUT
    DUT : entity work.busTTY_ascii2hex
        port map    (
                        CHAR        => CHAR,
                        HEX         => HEX,
                        NOHEXCHAR   => NOHEXCHAR
                    );
    ----------------------------------------------


    ----------------------------------------------
    -- stimuli
    p_stimuli_process : process
        -- tb help variables
            variable good   : boolean := true;
    begin

        -------------------------
        -- Init
        -------------------------
            Report "Init...";
            CHAR    <= (others => '0');
            wait for 5*tclk;
        -------------------------


        -------------------------
        -- Test0: check conversion
        -------------------------
        if ( DO_ALL_TEST or do_test_0 ) then
            Report "Test0: check conversion";
            wait for tclk;          -- works combinatoric
            -- number 0 to 9
            for i in 0 to 9 loop
                CHAR    <= std_logic_vector(to_unsigned(character'pos('0')+i, CHAR'length));
                wait for tclk;
                assert ( i = to_integer(unsigned(HEX)) ) report "  Error: loop=" & integer'image(i) & "; conversion failed" severity warning;
                if not ( i = to_integer(unsigned(HEX)) ) then good := false; end if;
                assert ( NOHEXCHAR = '0' ) report "  Error: flag wrong" severity warning;
                if not ( NOHEXCHAR = '0' ) then good := false; end if;
            end loop;
            wait for tclk;
            -- lower case hex numbers
            for i in 10 to 15 loop
                CHAR    <= std_logic_vector(to_unsigned(character'pos('a')+i-10, CHAR'length));
                wait for tclk;
                assert ( i = to_integer(unsigned(HEX)) ) report "  Error: loop=" & integer'image(i) & "; conversion failed" severity warning;
                if not ( i = to_integer(unsigned(HEX)) ) then good := false; end if;
                assert ( NOHEXCHAR = '0' ) report "  Error: flag wrong" severity warning;
                if not ( NOHEXCHAR = '0' ) then good := false; end if;
            end loop;
            -- upper case hex numbers
            for i in 10 to 15 loop
                CHAR    <= std_logic_vector(to_unsigned(character'pos('A')+i-10, CHAR'length));
                wait for tclk;
                assert ( i = to_integer(unsigned(HEX)) ) report "  Error: loop=" & integer'image(i) & "; conversion failed" severity warning;
                if not ( i = to_integer(unsigned(HEX)) ) then good := false; end if;
                assert ( NOHEXCHAR = '0' ) report "  Error: flag wrong" severity warning;
                if not ( NOHEXCHAR = '0' ) then good := false; end if;
            end loop;
            wait for tclk;
            CHAR    <= (others => '0');
            wait for tclk;
        end if;
        -------------------------


        -------------------------
        -- Test1: check flag for non hexadecimal number ASCII input
        -------------------------
        if ( DO_ALL_TEST or do_test_1 ) then
            Report "Test0: check flag for non hexadecimal number ASCII input";
            for i in character'pos('g') to character'pos('z') loop
                CHAR    <= std_logic_vector(to_unsigned(i, CHAR'length));
                wait for tclk;
                assert ( HEX = x"0" ) report "  Error: char='" & character'val(i) & "' not converted to zero" severity warning;
                if not ( HEX = x"0"  ) then good := false; end if;
                assert ( NOHEXCHAR = '1' ) report "  Error: flag wrong" severity warning;
                if not ( NOHEXCHAR = '1' ) then good := false; end if;
            end loop;
            wait for tclk;
            CHAR    <= (others => '0');
            wait for tclk;
        end if;
        -------------------------


        -------------------------
        -- Report TB
        -------------------------
            Report "End TB...";     -- sim finished
            if (good) then
                Report "Test SUCCESSFUL";
            else
                Report "Test FAILED" severity error;
            end if;
            wait;                   -- stop process continuous run
        -------------------------

    end process p_stimuli_process;
    ----------------------------------------------

end architecture sim;
--------------------------------------------------------------------------
