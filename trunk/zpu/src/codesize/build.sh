zpu-elf-gcc -Os -abel smallstd.c -o smallstd.elf -Wl,--relax -Wl,--gc-sections
zpu-elf-objdump --disassemble-all -S >smallstd.dis smallstd.elf
zpu-elf-objcopy -O binary smallstd.elf smallstd.bin
cat >../zpurom.vhd zpurom.vhd_header
./a smallstd.bin >>../zpurom.vhd
cat >>../zpurom.vhd zpurom.vhd_footer
zpu-elf-size smallstd.elf
zpu-elf-objdump -d smallstd.elf