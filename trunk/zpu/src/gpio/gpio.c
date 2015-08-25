#include<stdio.h>
volatile int * volatile const dbg_addr = (volatile int * volatile const )0x0c000000;
volatile int * volatile const dbg_dir_addr = (volatile int * volatile const )0x0c000004;

int main()
{
	*dbg_dir_addr = 0x00000001;
	*dbg_addr = 0x00000001<<0;
	while(1)
	{
		if(((*dbg_addr) & 0x00000001))
			*dbg_addr = 0x00000001<<1;
		else
			*dbg_addr = 0x00000001<<2;
	}
}

