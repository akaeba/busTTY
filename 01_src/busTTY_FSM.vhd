--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        busTTY_FSM.vhd
-- @note        VHDL'93
--
-- @brief       Finite State machine
-- @details     Coordinates all request and responses
--
-- @date        2018-09-29
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.ceil;
    use ieee.math_real.realmax;
    use ieee.math_real.log2;
library work;
    use work.busTTYpkg.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- busTTY_FSM: State machine
entity busTTY_FSM is
generic (
            ROM_MSG_WADR    : positive              := 5;   --! Address width message ROM
            WADR            : positive              := 16;  --! address width
            WDATA           : positive              := 8;   --! data width
            TIOUT_MEM_CYC   : positive              := 5    --! number of clock cycles to fulfill an memory request
        );
port    (
            -- Clock/Reset
            R               : in    std_logic;  --! asynchrony reset;
            C               : in    std_logic;  --! clock, rising edge
            -- Message ROM
            MSG_ADR         : out   std_logic_vector(ROM_MSG_WADR-1 downto 0 ); --! Message ROM address out
            MSG_END         : in    std_logic;                                  --! end of current message reached
            -- UART
            UART_RX_CHR     : in    std_logic_vector(7 downto 0);                   --! character data
            UART_RX_NEW     : in    std_logic;                                      --! character new
            UART_RX_ERO     : in    std_logic;                                      --! Receive Error
            UART_RX_NOHEX   : in    std_logic;                                      --! no ASCII hex provided
            UART_TX_EMPTY   : in    std_logic;                                      --! ready for new data
            UART_TX_MUX     : out   std_logic_vector(C_UART_MUX_LEN-1 downto 0);    --! UART TX input MUX
            UART_TX_NEW     : out   std_logic;                                      --! write new data to uart
            -- Quad Shift registers
            QSR_IST_ADR     : out   std_logic_vector(C_QSR_IST_LEN-1 downto 0); --! instruct ADR QSR
            QSR_IST_DAT     : out   std_logic_vector(C_QSR_IST_LEN-1 downto 0); --! instruct DATA QSR
            QSR_IST_BRST    : out   std_logic_vector(C_QSR_IST_LEN-1 downto 0); --! instruct burst length QSR
            QSR_ZCNT_BRST   : in    std_logic;                                  --! zero count reached
            -- Parallel
            MEM_EN          : out   std_logic;  --! perform access
            MEM_WR          : out   std_logic;  --! high active memory write, low active memory read
            MEM_ACK         : in    std_logic;  --! request acknowledge
            -- Debug
            FSM             : out   std_logic_vector(7 downto 0)    --! FSM Internal States
        );
end entity busTTY_FSM;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of busTTY_FSM is

    -----------------------------
    -- Types
        -- FSM states
    type t_busTTY_FSM is
        (
            IDLE_S,                     --! Nop:        IDLE state
            LD_LOGON_MSG_S,             --! Message:    Load counter to print logon message
            LD_HELP_MSG_S,              --! Message:    load pointer reg for help command
            LD_NL_MSG_S,                --! Message:    new line and go to idle
            LD_UNEXPIN_MSG_S,           --! Message:    unexpected input provided
            LD_MEMIF_STUCK_S,           --! Message:    load stuck memif message
            PRT_MSG_CHK_TX_S,           --! Print:      check if TX is free, otherwise wait
            PRT_MSG_TX_WR_S,            --! Print:      write new character
            PRT_MSG_FETCH_ROM_S,        --! Print:      fetch new character from ROM
            WT_TX_FREE_GO_IDLE,         --! Misc:       wait for freeing TX buffer and go to IDLE
            CMD_CAPTURE_S,              --! Command:    capture command and decode
            CMD_WT_CHK_S,               --! Command:    wait for next character and check
            ADR_SET_CHAR_CNTR_S,        --! Address:    preset character counter
            ADR_WT_CHAR_S,              --! Address:    wait for data interpreted as address
            ADR_CAP_S,                  --! Address:    move from UART to QSR
            WR_SET_CNTR_DAT_TIOUT_S,    --! Write:      Preload Character Counter and Tiout Counter
            WR_WT_CHAR_S,               --! Write:      Wait for new character and decide ongoing
            WR_CAP_S,                   --! Write:      Capture UART RX Reg value into QSR
            WR_MEMIF_S,                 --! Write:      Request Memory Access
            WR_INC_ADR_S,               --! Write:      Increment Address
            RD_SET_CNTR_BRST_TIOUT_S,   --! Read:       set character counter for burst length load
            RD_WT_CHAR_S,               --! Read:       Wait for burst length character receive
            RD_CAP_S,                   --! Read:       Capture input character
            RD_MEMIF_S,                 --! Read:       perform Read Access
            RD_SET_CHRSD_LDDAT_S,       --! Read:       Load Character counter
            RD_SEND_WT_S,               --! Read:       wait for free TX register
            RD_SEND_DAT_S,              --! Read:       load TX register
            RD_SEND_BLNK_S,             --! Read:       load TX with blank
            RD_INCADR_DECBRST_S,        --! Read:       Increment Address, Decrement Burst Counter
            ERROR_S                     --! ERO:        something went wrong

        );
        -- Operations
    type t_busTTY_OP is
        (
            OP_WRITE,   --! write
            OP_READ,    --! read
            OP_NOP      --! no operation selected
        );
    -----------------------------


    -----------------------------
    -- Constants
        constant C_WIDTH_CHAR_CNTR  : integer := integer(ceil(realmax(real(WADR), real(WDATA)) / 4.0)); --! maximum number of characters for counter
        constant C_NUM_DATA_CHARS   : integer := integer(ceil(real(WDATA) / 4.0));                      --! number of hex digits to meet data width
        constant C_NUM_ADR_CHARS    : integer := integer(ceil(real(WADR) / 4.0));                       --! number of hex digits to meet address width
        constant C_WIDTH_TIOUT_CNTR : integer := integer(ceil(log2(real(TIOUT_MEM_CYC))));              --! tiout counter width
    -----------------------------


    -----------------------------
    -- signals
        signal current_state        : t_busTTY_FSM;                                     --! latched state
        signal next_state           : t_busTTY_FSM;                                     --! combinatoric calculated state
        signal print_logon_msg      : std_logic;                                        --! flag for print logon message
        signal print_logon_msg_nxt  : std_logic;                                        --! next value
        signal message_adr          : std_logic_vector(MSG_ADR'range);                  --! address of actual character form rom
        signal message_adr_nxt      : std_logic_vector(MSG_ADR'range);                  --! address of actual character form rom
        signal operation            : t_busTTY_OP;                                      --! decoded operation
        signal operation_dec        : t_busTTY_OP;                                      --! decoded character
        signal operation_nxt        : t_busTTY_OP;                                      --! decoded character
        signal char_escape          : std_logic;                                        --! ESC received
        signal char_enter           : std_logic;                                        --! Enter received
        signal char_blank           : std_logic;                                        --! Blank received
        signal char_cntr_cnt        : std_logic_vector(C_WIDTH_CHAR_CNTR-1 downto 0);   --! character counter; figures out when all chars are captured
        signal char_cntr_nxt        : std_logic_vector(char_cntr_cnt'range);            --! next value
        signal tiout_cntr_cnt       : std_logic_vector(C_WIDTH_TIOUT_CNTR-1 downto 0);  --! registered value
        signal tiout_cntr_nxt       : std_logic_vector(tiout_cntr_cnt'range);           --! next
    -----------------------------

begin

    ----------------------------------------------
    -- next state calculation
    p_nxt_state : process   (
                                current_state,      --! actual state
                                print_logon_msg,    --! logon message printed
                                UART_TX_EMPTY,      --! ready for new char
                                MSG_END,            --! end reached
                                UART_RX_NEW,        --! new char received
                                UART_RX_NOHEX,      --! No Hex character provided
                                operation,          --! decoded request
                                char_escape,        --! escape character received
                                char_enter,         --! enter character received
                                char_blank,         --! blank character received
                                char_cntr_cnt,      --! number of characters left
                                MEM_ACK,            --! acknowledge for perform request
                                tiout_cntr_cnt,     --! checks for request time out
                                QSR_ZCNT_BRST       --! burst length register has zero count
                            )
    begin
        next_state  <=  current_state;  --! default

        -- next state calculation
        case current_state is

            -- wait for request
            when IDLE_S =>
                if ( print_logon_msg = '0' ) then
                    next_state <= LD_LOGON_MSG_S;       --! start with printing
                else
                    if ( UART_RX_NEW = '1' ) then
                        if  ( char_enter = '1' ) then
                            next_state <= IDLE_S;           --! skip additional provided characters
                        else
                            next_state  <= CMD_CAPTURE_S;
                        end if;
                    end if;
                end if;

            -- Message: load pointer reg for print message
            when LD_LOGON_MSG_S =>
                next_state  <= PRT_MSG_CHK_TX_S;

            -- Message: load help message
            when LD_HELP_MSG_S =>
                next_state <= PRT_MSG_CHK_TX_S;

            -- Message: unexpected input
            when LD_UNEXPIN_MSG_S =>
                next_state <= PRT_MSG_CHK_TX_S;

            -- Message: new line
            when LD_NL_MSG_S =>
                next_state <= PRT_MSG_CHK_TX_S;

            -- Message: Load Stuck on MEMIF message
            when LD_MEMIF_STUCK_S =>
                next_state <= PRT_MSG_CHK_TX_S;

            -- Print: check if transmit buffer is empty, otherwise wait
            when PRT_MSG_CHK_TX_S =>
                if ( MSG_END = '1' ) then
                    next_state <= WT_TX_FREE_GO_IDLE;
                else
                    if ( UART_TX_EMPTY = '1' ) then
                        next_state  <= PRT_MSG_TX_WR_S;
                    else
                        next_state  <= PRT_MSG_CHK_TX_S;
                    end if;
                end if;

            -- Free TX and go to idle
            when WT_TX_FREE_GO_IDLE =>
                if ( UART_TX_EMPTY = '1' ) then
                    next_state <= IDLE_S;
                else
                    next_state <= WT_TX_FREE_GO_IDLE;
                end if;

            -- write character to UART
            when PRT_MSG_TX_WR_S =>
                next_state <= PRT_MSG_FETCH_ROM_S;

            -- fetch new character
            when PRT_MSG_FETCH_ROM_S =>
                next_state <= PRT_MSG_CHK_TX_S;

            -- capture and decode command
            when CMD_CAPTURE_S =>
                next_state <= CMD_WT_CHK_S;

            -- evaluate command
            when CMD_WT_CHK_S =>
                if ( operation = OP_NOP ) then
                    next_state  <= LD_HELP_MSG_S;
                else
                    if ( UART_RX_NEW = '1' ) then
                        if ( char_escape = '1' ) then       --! escape requested
                            next_state <= LD_NL_MSG_S;
                        else
                            next_state <= ADR_SET_CHAR_CNTR_S;
                        end if;
                    else
                        next_state <= CMD_WT_CHK_S;
                    end if;
                end if;

            -- Address Capture: Preset Character Counter
            when ADR_SET_CHAR_CNTR_S =>
                next_state <= ADR_WT_CHAR_S;

            -- Address: Wait for characters
            when ADR_WT_CHAR_S =>
                if ( UART_RX_NEW = '1' ) then
                    if ( char_escape = '1' ) then               --! escape requested
                        next_state <= LD_NL_MSG_S;
                    elsif ( char_blank = '1' ) then             --! all data collected, go on on next stage
                        if ( operation = OP_READ ) then
                            next_state <= RD_SET_CNTR_BRST_TIOUT_S; --! go on with FSM Read part
                        elsif ( operation = OP_WRITE ) then
                            next_state <= WR_SET_CNTR_DAT_TIOUT_S;  --! go on with write Part of FSM
                        else
                            next_state <= ERROR_S;
                        end if;
                    elsif ( UART_RX_NOHEX = '0' ) then
                        if ( to_integer(to_01(unsigned(char_cntr_cnt))) > 0 ) then  -- capture only address if space is left
                            next_state <= ADR_CAP_S;
                        else
                            next_state <= ADR_WT_CHAR_S;
                        end if;
                    else
                        next_state <= LD_UNEXPIN_MSG_S;     --! no suitable input, print no suitable input message with help
                    end if;
                else
                    next_state <= ADR_WT_CHAR_S;
                end if;

            -- Address: Capture QSR address register shift forward
            when ADR_CAP_S =>
                next_state <= ADR_WT_CHAR_S;

            -- Write: Preload Character Counter and Tiout Counter
            when WR_SET_CNTR_DAT_TIOUT_S =>
                next_state <= WR_WT_CHAR_S;

            -- Write: Wait for new character and decide ongoing
            when WR_WT_CHAR_S =>
                if ( UART_RX_NEW = '1' ) then
                    if ( char_escape = '1' ) then       --! end of read/write requested
                        next_state <= LD_NL_MSG_S;
                    elsif ( char_blank = '1' or char_enter = '1' ) then --! all data collected, write goes on after
                        next_state <= WR_MEMIF_S;
                    elsif ( UART_RX_NOHEX = '0' ) then
                        if ( to_integer(to_01(unsigned(char_cntr_cnt))) > 0 ) then  -- capture only address if space is left
                            next_state <= WR_CAP_S;
                        else
                            next_state <= WR_WT_CHAR_S;
                        end if;
                    else
                        next_state <= LD_UNEXPIN_MSG_S;     --! no suitable input, print no suitable input message with help
                    end if;
                else
                    next_state <= WR_WT_CHAR_S;
                end if;

            -- Write: Capture UART RX Reg value into QSR
            when WR_CAP_S =>
                next_state <= WR_WT_CHAR_S;

            -- Write: Request Memory Access
            when WR_MEMIF_S =>
                if ( to_integer(to_01(unsigned(tiout_cntr_cnt))) = 0 ) then
                    next_state <= LD_MEMIF_STUCK_S;
                elsif ( MEM_ACK = '1' ) then
                    if ( char_enter = '1' ) then
                        next_state <= LD_NL_MSG_S;
                    else
                        next_state <= WR_INC_ADR_S; --! increment address
                    end if;
                else
                    next_state <= WR_MEMIF_S;
                end if;

            -- Write: Increment Address
            when WR_INC_ADR_S =>
                next_state <= WR_SET_CNTR_DAT_TIOUT_S;

            -- Read: set character counter for burst length load
            when RD_SET_CNTR_BRST_TIOUT_S =>
                next_state <= RD_WT_CHAR_S;

            -- Read: Wait for burst length character receive
            when RD_WT_CHAR_S =>
                if ( UART_RX_NEW = '1' ) then
                    if ( char_escape = '1' ) then       --! end of read/write requested
                        next_state <= LD_NL_MSG_S;
                    elsif ( char_enter = '1' ) then
                        next_state <= RD_MEMIF_S;
                    elsif ( UART_RX_NOHEX = '0' ) then
                        if ( to_integer(to_01(unsigned(char_cntr_cnt))) > 0 ) then  -- capture only address if space is left
                            next_state <= RD_CAP_S;
                        else
                            next_state <= RD_WT_CHAR_S;
                        end if;
                    else
                        next_state <= LD_UNEXPIN_MSG_S;     --! no suitable input, print no suitable input message with help
                    end if;
                else
                    next_state <= RD_WT_CHAR_S;
                end if;

            -- Read: Capture input character
            when RD_CAP_S =>
                next_state <= RD_WT_CHAR_S;

            -- Read: perform Read Access
            when RD_MEMIF_S =>
                if ( to_integer(to_01(unsigned(tiout_cntr_cnt))) = 0 ) then
                    next_state <= LD_MEMIF_STUCK_S;
                elsif ( MEM_ACK = '1' ) then
                    next_state <= RD_SET_CHRSD_LDDAT_S;
                else
                    next_state <= RD_MEMIF_S;
                end if;

            -- Read: Load Counter for characters to send, load QSR with MEMIF data
            when RD_SET_CHRSD_LDDAT_S =>
                next_state <= RD_SEND_WT_S;

            -- Read: Wait for free TX Line, allow escape sequence
            when RD_SEND_WT_S =>
                if ( UART_TX_EMPTY = '1' ) then
                    if ( to_integer(to_01(unsigned(char_cntr_cnt))) = 0 ) then
                        if ( QSR_ZCNT_BRST = '1' ) then
                            next_state <= LD_NL_MSG_S;
                        else
                            next_state <= RD_SEND_BLNK_S;
                        end if;
                    else
                        next_state <= RD_SEND_DAT_S;
                    end if;
                elsif ( UART_RX_NEW = '1' ) then    --! process Escape request
                    if ( char_escape = '1' ) then
                        next_state <= LD_NL_MSG_S;
                    else
                        next_state <= RD_SEND_WT_S;
                    end if;
                else
                    next_state <= RD_SEND_WT_S;
                end if;

            -- Read: Send characters of data out
            when RD_SEND_DAT_S =>
                next_state <= RD_SEND_WT_S;

            -- Read: Send blank to separate data from previous/next read
            when RD_SEND_BLNK_S =>
                next_state <= RD_INCADR_DECBRST_S;

            -- Read: Increment Address, Decrement Burst Counter
            when RD_INCADR_DECBRST_S =>
                next_state <= RD_MEMIF_S;

            -- Misc: Go Idle
            when others =>
                next_state <= IDLE_S;

        end case;
    end process p_nxt_state;
    ---------------------------------------------


    ----------------------------------------------
    -- registers
    p_register : process ( R, C )
    begin
        if ( R = '1' ) then
            current_state   <= IDLE_S;          --! assign reset state
            print_logon_msg <= '0';             --! no logon message yet printed
            message_adr     <= (others => '0'); --! init
            operation       <= OP_NOP;          --!
            char_cntr_cnt   <= (others => '0'); --! reset
            tiout_cntr_cnt  <= (others => '0'); --!

        elsif ( rising_edge(C) ) then
            current_state   <= next_state;          --! state update
            message_adr     <= message_adr_nxt;     --! latch
            print_logon_msg <= print_logon_msg_nxt; --!
            operation       <= operation_nxt;       --!
            char_cntr_cnt   <= char_cntr_nxt;       --!
            tiout_cntr_cnt  <= tiout_cntr_nxt;      --!

        end if;
    end process p_register;
    ----------------------------------------------


    ----------------------------------------------
    -- FSM related
        -- load message address register
    with current_state select message_adr_nxt <=
        std_logic_vector(to_unsigned(C_MSG_LOGON,       message_adr_nxt'length))    when LD_LOGON_MSG_S,        --! logon
        std_logic_vector(to_unsigned(C_MSG_HELP,        message_adr_nxt'length))    when LD_HELP_MSG_S,         --! print help
        std_logic_vector(to_unsigned(C_MSG_NEW_LINE,    message_adr_nxt'length))    when LD_NL_MSG_S,           --! new line
        std_logic_vector(to_unsigned(C_MSG_UNEXP_INP,   message_adr_nxt'length))    when LD_UNEXPIN_MSG_S,      --! unexpected input
        std_logic_vector(to_unsigned(C_MSG_MEMIF_STUCK, message_adr_nxt'length))    when LD_MEMIF_STUCK_S,      --! load message for stuck on MEMIF
        std_logic_vector(unsigned(message_adr) + 1)                                 when PRT_MSG_FETCH_ROM_S,   --! increment ROM adr
        message_adr                                                                 when others;                --! do nothing

        -- set logon flag
    with current_state select print_logon_msg_nxt <=
        '1'             when LD_LOGON_MSG_S,    --! set flag
        print_logon_msg when others;            --! hold

        -- register decoded command
    with current_state select operation_nxt <=
        operation_dec   when CMD_CAPTURE_S,
        operation       when others;

        -- character counter count control
    with current_state select char_cntr_nxt <=
        std_logic_vector(unsigned(char_cntr_cnt) - 1)                           when ADR_CAP_S,                 --! decrement, cause new character was captured
        std_logic_vector(to_unsigned(C_NUM_ADR_CHARS, char_cntr_nxt'length))    when ADR_SET_CHAR_CNTR_S,       --! preset for char count to meet address width
        std_logic_vector(unsigned(char_cntr_cnt) - 1)                           when WR_CAP_S,                  --! decrement, cause new character was captured
        std_logic_vector(to_unsigned(C_NUM_DATA_CHARS, char_cntr_nxt'length))   when WR_SET_CNTR_DAT_TIOUT_S,   --! preload character counter
        std_logic_vector(to_unsigned(C_NUM_ADR_CHARS, char_cntr_nxt'length))    when RD_SET_CNTR_BRST_TIOUT_S,  --! preload character counter for burst capture register
        std_logic_vector(to_unsigned(C_NUM_DATA_CHARS, char_cntr_nxt'length))   when RD_SET_CHRSD_LDDAT_S,      --! preset for char count to send all data
        std_logic_vector(unsigned(char_cntr_cnt) - 1)                           when RD_SEND_DAT_S,             --! decrement, char was sent
        char_cntr_cnt                                                           when others;                    --! hold

        -- time out counter to detect memory IF stuck
    with current_state select tiout_cntr_nxt <=
        std_logic_vector(to_unsigned(TIOUT_MEM_CYC, tiout_cntr_nxt'length)) when RD_SET_CNTR_BRST_TIOUT_S,  --! init counter for first entry in memory access and request respond loop
        std_logic_vector(to_unsigned(TIOUT_MEM_CYC, tiout_cntr_nxt'length)) when WR_SET_CNTR_DAT_TIOUT_S,   --!
        std_logic_vector(to_unsigned(TIOUT_MEM_CYC, tiout_cntr_nxt'length)) when RD_INCADR_DECBRST_S,       --! read loop
        std_logic_vector(unsigned(tiout_cntr_cnt) - 1)                      when RD_MEMIF_S,                --! decrement to run in tiout
        std_logic_vector(unsigned(tiout_cntr_cnt) - 1)                      when WR_MEMIF_S,                --! decrement to detect stuck
        tiout_cntr_cnt                                                      when others;                    --! on hold

    ----------------------------------------------


    ----------------------------------------------
    -- ASCII decoders
        -- request
    with to_integer(to_01(unsigned(UART_RX_CHR))) select operation_dec <=
        OP_WRITE    when C_ASCII_WR_0,      --! write
        OP_WRITE    when C_ASCII_WR_1,      --!
        OP_READ     when C_ASCII_RD_0,      --! read
        OP_READ     when C_ASCII_RD_1,      --!
        OP_NOP      when others;

        -- escape
    with to_integer(to_01(unsigned(UART_RX_CHR))) select char_escape <=
        '1' when character'pos(ESC),    --! user request escape sequence
        '0' when others;

        -- enter
    with to_integer(to_01(unsigned(UART_RX_CHR))) select char_enter <=
        '1' when character'pos(LF),     --! part of enter
        '1' when character'pos(CR),     --! part of enter
        '0' when others;

        -- blank
    with to_integer(to_01(unsigned(UART_RX_CHR))) select char_blank <=
        '1' when character'pos(' '),    --! blank received
        '0' when others;
    ----------------------------------------------


    ----------------------------------------------
    -- UART IF
        -- TX Control
    with current_state select UART_TX_NEW <=
        UART_RX_NEW when IDLE_S,            --! mirror operator back to user
        '1'         when RD_CAP_S,          --! send captured character back to user
        '1'         when WR_CAP_S,          --! send captured character back to user
        '1'         when RD_SEND_BLNK_S,    --! send blank to separate
        '1'         when PRT_MSG_TX_WR_S,   --! write new character to UART
        '1'         when RD_SEND_DAT_S,     --! send data out
        '0'         when others;

        -- TX Data MUX
    with current_state select UART_TX_MUX <=
        C_UART_MUX_RX   when IDLE_S,            --! mirror operator back to user
        C_UART_MUX_RX   when RD_CAP_S,          --! send captured character back to user
        C_UART_MUX_RX   when WR_CAP_S,          --! send captured character back to user
        C_UART_MUX_MSG  when PRT_MSG_TX_WR_S,   --! ROM connected to UART
        C_UART_MUX_BLNK when RD_SEND_BLNK_S,    --! send blank to separate
        C_UART_MUX_DATO when RD_SEND_DAT_S,     --! send QSR datao
        C_UART_MUX_NUL  when others;            --! do nothing

    ----------------------------------------------


    ----------------------------------------------
    -- DATA IF
        -- memory write
    with current_state select MEM_WR <=
        '1'     when WR_MEMIF_S,    --! enable for write
        '0'     when others;

    -- memory enable
    with current_state select MEM_EN <=
        '1'     when WR_MEMIF_S,            --! write
        '1'     when RD_MEMIF_S,            --! read
        '1'     when RD_SET_CHRSD_LDDAT_S,  --! read, allow latch
        '0'     when others;
    ----------------------------------------------


    ----------------------------------------------
    -- QSR IF
        -- address shift register
    with current_state select QSR_IST_ADR <=
        C_QSR_OP_CLR    when CMD_CAPTURE_S,     --! clear address register
        C_QSR_OP_SFW    when ADR_CAP_S,         --! serial load address
        C_QSR_OP_INC    when WR_INC_ADR_S,      --! increment address for next read
        C_QSR_OP_NOP    when others;            --! do nothing

        -- data shift register
    with current_state select QSR_IST_DAT <=
        C_QSR_OP_CLR    when CMD_CAPTURE_S,         --! clear all shift register
        C_QSR_OP_SFW    when WR_CAP_S,              --! shift forward
        C_QSR_OP_PLD    when RD_SET_CHRSD_LDDAT_S,  --! PLD/NOP based on operation to perform
        C_QSR_OP_CLR    when RD_INCADR_DECBRST_S,   --! increment address for next read
        C_QSR_OP_SFW    when RD_SEND_DAT_S,         --! shift forward to bring next quadruple on send position
        C_QSR_OP_NOP    when others;                --! do nothing

        -- read length register (burst)
    with current_state select QSR_IST_BRST <=
        C_QSR_OP_CLR    when CMD_CAPTURE_S,         --! clear all shift register
        C_QSR_OP_SFW    when RD_CAP_S,              --! serial load in case of read, otherwise nop
        C_QSR_OP_DEC    when RD_INCADR_DECBRST_S,   --! decrement burst counter register
        C_QSR_OP_NOP    when others;                --! do nothing
    ---------------------------------------------


    ----------------------------------------------
    -- Assignments
    MSG_ADR <= message_adr;
    ----------------------------------------------


    ----------------------------------------------
    -- FSM debug output
    with current_state select FSM <=
         std_logic_vector(to_unsigned(00, FSM'length))  when IDLE_S,    --! IDLE
                                                                        --! TODO!
         (others => '1')                                when others;    --! default assignment
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
