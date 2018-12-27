onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Misc
add wave -noupdate /bustty_fsm_tb/R
add wave -noupdate /bustty_fsm_tb/C
add wave -noupdate -divider FSM
add wave -noupdate -radix hexadecimal /bustty_fsm_tb/DUT/FSM
add wave -noupdate /bustty_fsm_tb/DUT/current_state
add wave -noupdate /bustty_fsm_tb/DUT/next_state
add wave -noupdate /bustty_fsm_tb/DUT/operation
add wave -noupdate /bustty_fsm_tb/DUT/operation_dec
add wave -noupdate /bustty_fsm_tb/DUT/operation_nxt
add wave -noupdate /bustty_fsm_tb/DUT/char_escape
add wave -noupdate /bustty_fsm_tb/DUT/char_enter
add wave -noupdate /bustty_fsm_tb/DUT/char_blank
add wave -noupdate -radix unsigned /bustty_fsm_tb/DUT/char_cntr_cnt
add wave -noupdate -radix unsigned /bustty_fsm_tb/DUT/char_cntr_nxt
add wave -noupdate -radix unsigned /bustty_fsm_tb/DUT/char_cntr_set_rd_wr
add wave -noupdate -radix unsigned /bustty_fsm_tb/DUT/tiout_cntr_cnt
add wave -noupdate -radix unsigned /bustty_fsm_tb/DUT/tiout_cntr_nxt
add wave -noupdate -divider UART
add wave -noupdate -radix ascii /bustty_fsm_tb/DUT/UART_RX_CHR
add wave -noupdate /bustty_fsm_tb/DUT/UART_RX_NEW
add wave -noupdate /bustty_fsm_tb/DUT/UART_RX_ERO
add wave -noupdate /bustty_fsm_tb/DUT/UART_RX_NOHEX
add wave -noupdate /bustty_fsm_tb/DUT/UART_TX_EMPTY
add wave -noupdate /bustty_fsm_tb/DUT/UART_TX_MUX
add wave -noupdate /bustty_fsm_tb/DUT/UART_TX_NEW
add wave -noupdate -divider {Message ROM}
add wave -noupdate -radix unsigned /bustty_fsm_tb/MSG_ADR
add wave -noupdate /bustty_fsm_tb/MSG_END
add wave -noupdate -divider UART_TX
add wave -noupdate -radix ascii /bustty_fsm_tb/uartTX
add wave -noupdate /bustty_fsm_tb/uartTXstart
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {22941728 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 274
configure wave -valuecolwidth 57
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {41640992 ps}
