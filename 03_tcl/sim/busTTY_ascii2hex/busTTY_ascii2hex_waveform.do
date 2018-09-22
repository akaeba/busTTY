onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix ascii /bustty_ascii2hex_tb/CHAR
add wave -noupdate -radix hexadecimal /bustty_ascii2hex_tb/HEX
add wave -noupdate /bustty_ascii2hex_tb/NOHEXCHAR
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {120000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 231
configure wave -valuecolwidth 78
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
WaveRestoreZoom {0 ps} {1245065 ps}
