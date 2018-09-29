onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Misc
add wave -noupdate /bustty_quadsr_tb/R
add wave -noupdate /bustty_quadsr_tb/C
add wave -noupdate -divider Data/Ctrl
add wave -noupdate /bustty_quadsr_tb/UP
add wave -noupdate /bustty_quadsr_tb/EN
add wave -noupdate /bustty_quadsr_tb/LD
add wave -noupdate -radix hexadecimal /bustty_quadsr_tb/D
add wave -noupdate -radix hexadecimal /bustty_quadsr_tb/Q
add wave -noupdate -radix hexadecimal /bustty_quadsr_tb/SI4
add wave -noupdate -radix hexadecimal /bustty_quadsr_tb/SO4
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {171000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 183
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
WaveRestoreZoom {0 ps} {7875 ns}
