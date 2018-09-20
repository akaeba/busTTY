--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        busTTY.vhd
-- @note        VHDL'93
--
-- @brief       TTY to memory mapped interface
-- @details     provides a small instruction set to to perform
--              read and write operations an a memory-mapped
--              data bus via an simple teletype terminal over UART
--             
-- @date        2018-09-07
-- @version     0.1
--************************************************************************



--
-- Important Hints:
-- ================
--
--	Instruction
--	-----------
--	 * read data
--	 * write data
--	 * read xreg
--	 * write xreg
-- 



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- bus teletype terminal (buyTTY)
entity busTTY is
generic (
            AWIDTH	: positive				:= 8;			--! address width									[integer]
			DWIDTH	: positive				:= 8;			--! data width										[integer]
			DATDLY	: positive				:= 1;			--! delay in clock cycles address assert to data	[integer]
			CLKHZ	: positive				:= 50_000_000;	--! Clock rate										[Hz]
			BPS		: positive				:= 115200; 		--! UART baud rate									[bps]
			STOPBIT	: integer range 1 to 2	:= 1;			--! UART number of stop bit							[integer]
			PARITY	: integer range 0 to 2	:= 0;			--! UART Parity, 0: none, 1: odd, 2: even			[integer]
			XREGRST	: integer				:= 16#00#		--! XREGO reset value, max 32Bit supported			[hexadecimal]
		);
port	(
			-- Clock/Reset
			R		: in    std_logic;		--! asynchrony reset
			C		: in    std_logic;		--! clock, rising edge
			-- serial UART Interface
			TXD		: out   std_logic;		--! transmit data;  LSB first
			RXD		: in    std_logic;		--! receive data;   LSB first
			-- parallel
			CE		: out	std_logic;								--! interface enable
			WR		: out	std_logic;								--! write enable
			ADR		: out	std_logic_vector(AWIDTH-1 downto 0);	--! address
			DI		: in	std_logic_vector(DWIDTH-1 downto 0);	--! input data
			DO		: out	std_logic_vector(DWIDTH-1 downto 0);	--! output data
			-- register
			XREGI	: in	std_logic_vector(DWIDTH-1 downto 0);	--! status register input
			XREGO	: out	std_logic_vector(DWIDTH-1 downto 0)		--! status register output
		);
end entity busTTY;
--------------------------------------------------------------------------



