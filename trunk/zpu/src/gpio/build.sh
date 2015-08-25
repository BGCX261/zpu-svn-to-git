zpu-elf-gcc -g -Os -Wall -phi gpio.c -o gpio.elf -Wl,--relax -Wl,--gc-sections
zpu-elf-objdump -d -S >horselight.dis gpio.elf
zpu-elf-objcopy -O binary gpio.elf gpio.bin
cat >../zpurom.vhd zpurom.vhd_header
./a gpio.bin >>../zpurom.vhd
cat >>../zpurom.vhd zpurom.vhd_footer
