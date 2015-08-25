zpu-elf-gcc -g -Os -Wall -phi horselight.c -o horselight.elf -Wl,--relax -Wl,--gc-sections
zpu-elf-objdump --disassemble-all -S >horselight.dis horselight.elf
zpu-elf-objcopy -O binary horselight.elf horselight.bin
cat >../zpurom.vhd zpurom.vhd_header
./a hello.bin >>../zpurom.vhd
cat >>../zpurom.vhd zpurom.vhd_footer