onerror {resume}

add wave -noupdate -divider top
add wave -noupdate /tb_top/clk
add wave -noupdate /tb_top/rst
add wave -noupdate /tb_top/rx_i
add wave -noupdate /tb_top/tx_o

add wave -noupdate -divider uart_rx
add wave -noupdate -radix hexadecimal /tb_top/dut/rx_data
add wave -noupdate /tb_top/dut/rx_valid

add wave -noupdate -divider msg_rx
add wave -noupdate /tb_top/dut/u_msg_rx/state
add wave -noupdate -radix decimal /tb_top/dut/num1
add wave -noupdate -radix decimal /tb_top/dut/num2
add wave -noupdate -radix hexadecimal /tb_top/dut/opcode
add wave -noupdate /tb_top/dut/msg_valid

add wave -noupdate -divider alu
add wave -noupdate -radix decimal /tb_top/dut/result
add wave -noupdate /tb_top/dut/result_valid

add wave -noupdate -divider msg_tx
add wave -noupdate -radix hexadecimal /tb_top/dut/tx_data
add wave -noupdate /tb_top/dut/tx_valid
add wave -noupdate /tb_top/dut/tx_ready

add wave -noupdate -divider tb
add wave -noupdate -radix unsigned /tb_top/resp_count

configure wave -timelineunits us
update
