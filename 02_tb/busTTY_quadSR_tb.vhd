--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        busTTY_quadSR_tb.vhd
-- @note        VHDL'93
--
-- @brief       testbench
-- @details
--
-- @date        2018-09-23
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;             --! for UNIFORM, TRUNC
    use ieee.std_logic_misc.or_reduce;
library work;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- testbench
entity busTTY_quadSR_tb is
generic (
            DO_ALL_TEST : boolean   := false        --! switch for enabling all tests
        );
end entity busTTY_quadSR_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of busTTY_quadSR_tb is

    -----------------------------
    -- Constant
        -- DUT
        constant STAGES : positive := 4;    --! 16bit data bus

        -- Clock
        constant tclk   : time  := 20 ns;   --! 50MHz clock
        constant tskew  : time  := 1 ns;    --! data skew

        -- Test
        constant loop_iter  : integer := 20;    --! number of test loop iteration
        constant do_test_0  : boolean := true;  --! test0: check parallel load
        constant do_test_1  : boolean := true;  --! test1: check flag for non hexadecimal number ASCII input
        constant do_test_2  : boolean := true;  --! test2: check down shift
    -----------------------------


    -----------------------------
    -- Signals
        -- DUT
        signal R    : std_logic;
        signal C    : std_logic;
        signal UP   : std_logic;
        signal EN   : std_logic;
        signal LD   : std_logic;
        signal SI4  : std_logic_vector(3 downto 0);
        signal SO4  : std_logic_vector(3 downto 0);
        signal D    : std_logic_vector(STAGES*4-1 downto 0);
        signal Q    : std_logic_vector(STAGES*4-1 downto 0);
    -----------------------------

begin

    ----------------------------------------------
    -- DUT
    DUT : entity work.busTTY_quadSR
        generic map (
                        STAGES => STAGES
                    )
        port map    (
                        R   => R,
                        C   => C,
                        UP  => UP,
                        EN  => EN,
                        LD  => LD,
                        SI4 => SI4,
                        SO4 => SO4,
                        D   => D,
                        Q   => Q
                    );
    ----------------------------------------------


    ----------------------------------------------
    -- stimuli
    p_stimuli_process : process
        -- tb help variables
            variable good   : boolean := true;
            variable tmp    : std_logic_vector(D'range)  := (others => '0');
        -- variables for random number generator
            variable seed1, seed2   : positive;
            variable rand           : real;
    begin

        -------------------------
        -- Init
        -------------------------
            Report "Init...";
            R       <= '1';
            UP      <= '1';
            EN      <= '0';
            LD      <= '0';
            SI4     <= (others => '0');
            D       <= (others => '0');
            wait for 5*tclk;
            wait until rising_edge(C); wait for tskew;
            R   <=  '0';
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
        -------------------------


        -------------------------
        -- Test0: check parallel load
        -------------------------
        if ( DO_ALL_TEST or do_test_0 ) then
            Report "Test0: check parallel load";
            wait until rising_edge(C); wait for tskew;
            UNIFORM(seed1, seed2, rand);    --! dummy read, otherwise first rand is zero
            for i in 0 to loop_iter-1 loop
                UNIFORM(seed1, seed2, rand);
                tmp := std_logic_vector(to_unsigned(integer(round(rand*(2.0**tmp'length-1.0))), tmp'length));
                D   <= tmp;
                LD  <= '1';
                wait until rising_edge(C); wait for tskew;
                LD  <= '0';
                assert ( Q = tmp ) report "  Error: Parallel load fails" severity warning;
                if not ( Q = tmp ) then good := false; end if;
            end loop;
        end if;
        -------------------------


        -------------------------
        -- Test1: check serial quad data input
        -------------------------
        if ( DO_ALL_TEST or do_test_1 ) then
            Report "Test1: check serial quad data input";
            wait until rising_edge(C); wait for tskew;
            UNIFORM(seed1, seed2, rand);    --! dummy read, otherwise first rand is zero
            D   <= (others => '0');
            for i in 0 to loop_iter-1 loop
                UNIFORM(seed1, seed2, rand);    --! new random number
                tmp := std_logic_vector(to_unsigned(integer(round(rand*(2.0**tmp'length-1.0))), tmp'length));
                for j in STAGES-1 downto 0 loop
                    SI4     <= tmp(j*4+3 downto j*4);
                    EN      <= '1';
                    UP      <= '1';
                    wait until rising_edge(C); wait for tskew;
                end loop;
                EN  <= '0';
                assert ( Q = tmp ) report "  Error: Serial input failed" severity warning;
                if not ( Q = tmp ) then good := false; end if;
                wait until rising_edge(C); wait for tskew;
            end loop;
        end if;
        -------------------------


        -------------------------
        -- Test2: check down shift
        -------------------------
        if ( DO_ALL_TEST or do_test_2 ) then
            Report "Test2: check down shift";
            wait until rising_edge(C); wait for tskew;
            UNIFORM(seed1, seed2, rand);    --! dummy read, otherwise first rand is zero
            for i in 0 to loop_iter-1 loop
                UNIFORM(seed1, seed2, rand);    --! new random number
                tmp := std_logic_vector(to_unsigned(integer(round(rand*(2.0**tmp'length-1.0))), tmp'length));
                D   <= tmp;
                LD  <= '1';
                UP  <= '0';
                SI4 <= (others => '0');
                wait until rising_edge(C); wait for tskew;
                LD  <= '0';
                for j in 0 to STAGES loop
                    if ( j = 0 ) then
                        assert ( Q = tmp ) report "  Error: Down Shift failed; shift=" & integer'image(j) & ";" severity warning;
                        if not ( Q = tmp ) then good := false; end if;
                    elsif ( j = STAGES ) then
                        assert ( or_reduce(Q) = '0' ) report "  Error: Down Shift failed; shift=" & integer'image(j) & ";" severity warning;
                        if not ( or_reduce(Q) = '0' ) then good := false; end if;
                    else
                        -- data
                        assert ( Q(Q'length-j*4-1 downto 0) = tmp(tmp'length-1 downto j*4) ) report "  Error: Down Shift failed; shift=" & integer'image(j) & ";" severity warning;
                        if not ( Q(Q'length-j*4-1 downto 0) = tmp(tmp'length-1 downto j*4) ) then good := false; end if;
                        -- zero
                        assert ( or_reduce(Q(Q'length-1 downto Q'length-j*4)) = '0' ) report "  Error: Down Shift failed; shift=" & integer'image(j) & ";" severity warning;
                        if not ( or_reduce(Q(Q'length-1 downto Q'length-j*4)) = '0' ) then good := false; end if;
                    end if;
                    EN  <= '1';
                    wait until rising_edge(C); wait for tskew;
                    EN  <= '0';
                    wait until rising_edge(C); wait for tskew;
                end loop;
            end loop;
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


    ----------------------------------------------
    -- clock
    p_clk : process
        variable clk : std_logic := '0';
    begin
        while true loop
            C   <= clk;
            clk := not clk;
            wait for tclk/2;
            end loop;
    end process p_clk;
    ----------------------------------------------

end architecture sim;
--------------------------------------------------------------------------