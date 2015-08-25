# Xilinx WebPack modelsim script
#
# 
# cd C:/workspace/zpu/zpu_sim
# do simzpu.do
#


set BreakOnAssertion 1
vlib work

vcom -93 -explicit  ../src/zpu_config.vhd
vcom -93 -explicit  ../zpu4/core/zpupkg.vhd
vcom -93 -explicit  ../zpu4/core/zpu_core_small.vhd
vcom -93 -explicit  ../zpu4/src/txt_util.vhd
vcom -93 -explicit  ../zpu4/src/timer.vhd
vcom -93 -explicit  ../zpu4/src/io.vhd
vcom -93 -explicit  ../zpu4/src/trace.vhd

vcom -93 -explicit  ../alzpu/alzpu_config.vhd
vcom -93 -explicit  ../alzpu/alzpu.vhd
vcom -93 -explicit  ../alzpu/alzpu_slaveselect.vhd
vcom -93 -explicit  ../alzpu/alzpu_io.vhd
vcom -93 -explicit  ../alzpu/alzpu_gpio.vhd
vcom -93 -explicit  ../soc/zpu_top.vhd
vcom -93 -explicit  ../soc/zpu_top_tb.vhd

vcom -93 -explicit  ../soc/alzpu_uart.vhd
vcom -93 -explicit  ../soc/miniUART/uart_lib.vhd
vcom -93 -explicit  ../soc/miniUART/clkUnit.vhd
vcom -93 -explicit  ../soc/miniUART/miniUART.vhd
vcom -93 -explicit  ../soc/miniUART/RxUnit.vhd
vcom -93 -explicit  ../soc/miniUART/TxUnit.vhd
vcom -93 -explicit  ../soc/miniUART/UARTtest.vhd

vcom -93 -explicit  ../src/zpurom.vhd

# run ZPU
vsim zpu_top_tb
view wave
#add wave -recursive zpu_top_tb/zpu/*
add wave -recursive zpu_top_tb/*
view structure
#view signals

# Enough to run tiny programs
run 5 ms
