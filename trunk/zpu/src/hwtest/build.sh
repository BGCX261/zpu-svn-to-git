zpu-elf-gcc -nostdlib test.S -o test.elf
#zpu-elf-objdump --disassemble-all -S >test.dis test.elf
zpu-elf-objcopy -O binary test.elf test.bin
cat >../zpurom.vhd zpurom.vhd_header
./a test.bin >>../zpurom.vhd
cat >>../zpurom.vhd zpurom.vhd_footer