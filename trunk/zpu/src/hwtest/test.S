  ;gpio test
  
	im 0x00000001
	nop
	im 0x0c000004  ;gpio direction reg address
	store
	
_loop:
	im 0x00000060
	nop
	im 0x0c000000
	store
im _loop
	poppc 			;  loop
