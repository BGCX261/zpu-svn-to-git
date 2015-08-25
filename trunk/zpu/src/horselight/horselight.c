#include<stdio.h>
volatile int * volatile const dbg_addr = (volatile int * volatile const )0x0c000000;
volatile int * volatile const dbg_dir_addr = (volatile int * volatile const )0x0c000004;

int main()
{
	unsigned int i,j,n=0;
	*dbg_dir_addr = 0x00000000;
	*dbg_addr = 0x00000001;
	while(1)
	{
    *dbg_addr = 0x00000001 << n++;
    if(n==8)
   	n=0;
    for(i=0;i<200;i++)
			for(j=0;j<50000;j++);
	}
}

