#include<stdio.h>
volatile int * volatile const uart = (volatile int * volatile const )0x08000000;
volatile int * volatile const uart_reg = (volatile int * volatile const )0x08000001;
volatile int * volatile const dbg_addr = (volatile int * volatile const )0x0c000000;
volatile int * volatile const dbg_dir_addr = (volatile int * volatile const )0x0c000004;

//functions
int uart_space();
void write_uart( int val);
int uart_avail();
int read_uart();

//main function
int main()
{
	//unsigned int n=0;
	unsigned int temp;
	*dbg_dir_addr = 0x00000001;
	*dbg_addr = 0x00000001<<0;
	while(1)
	{
		/*if(((*dbg_addr) & 0x00000001))
			*dbg_addr = 0x00000001<<6;
		else
			*dbg_addr = 0x00000001<<7;*/
		/*temp = (*uart_reg) & 0x00000008;
		if(temp ==0x0000008)
		{
			*uart = 'a';
			*dbg_addr = 0x00000001<<2;
		}*/
		/*else
		{
			*dbg_addr = 0x00000001<<1;
			*uart = 0x00000001<<1;
		}*/
		/*do{
  		temp = (*uart_reg) & 0x00000008;
  	}while (temp !=0x0000008);
  	*uart = 'a';
		*dbg_addr = 0x00000001<<2;
		*/
		do{
			temp = read_uart();
			*dbg_addr = temp;
		}while(temp != 'a');
		write_uart('a');
		temp = 0;
  }
}

int uart_space() {
	unsigned int temp;// I don't know why. :(
  do{
  	temp = (*uart_reg) & 0x00000008;
  }while (temp !=0x0000008);
  return 1;
}

void write_uart( int val ) {
  if(uart_space())
  	*uart = val & 0xFF;
}

int uart_avail() { //Check to see if data is available
	unsigned int temp;
	do{
		temp = (*uart_reg) & 0x00000004;
	}while(temp != 0x00000004);
	return 1;
}

int read_uart() {
  if(uart_avail()){
  	return *uart;
  }
  else
  	return 0;
}
