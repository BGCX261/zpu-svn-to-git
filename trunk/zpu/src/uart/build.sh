zpu-elf-gcc -g -Os -Wall -phi uart.c -o uart.elf -Wl,--relax -Wl,--gc-sections
zpu-elf-objdump --disassemble-all -S >uart.dis uart.elf
zpu-elf-objcopy -O binary uart.elf uart.bin
cat >../zpurom.vhd zpurom.vhd_header
./a uart.bin >>../zpurom.vhd
cat >>../zpurom.vhd zpurom.vhd_footer