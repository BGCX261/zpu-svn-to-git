--
--  ALZPU - IO Controller
-- 
--  Copyright 2008 Alvaro Lopes <alvieboy@alvie.com>
-- 
--  Version: 1.0
-- 
--  The FreeBSD license
--  
--  Redistribution and use in source and binary forms, with or without
--  modification, are permitted provided that the following conditions
--  are met:
--  
--  1. Redistributions of source code must retain the above copyright
--     notice, this list of conditions and the following disclaimer.
--  2. Redistributions in binary form must reproduce the above
--     copyright notice, this list of conditions and the following
--     disclaimer in the documentation and/or other materials
--     provided with the distribution.
--  
--  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
--  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
--  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
--  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
--  ZPU PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
--  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
--  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
--  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
--  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
--  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
--  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--  
-- */

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.alzpu_config.all;
use work.alzpu.all;
use work.alzpu_slaveselect.all;

entity alzpu_io is
   port (
      slave_in: in zpu_slave_in_type;
      slave_out: out zpu_slave_out_type;
      interrupt: out std_logic;
      gpio_pad: inout std_logic_vector(alzpu_gpio_num-1 downto 0);
		RxD_pad:   in std_logic;
		TxD_pad:   out std_logic
   );

end alzpu_io;

architecture behave of alzpu_io is

  component alzpu_gpio is
    port(
      slave_in: in zpu_slave_in_type;
      slave_out: out zpu_slave_out_type;
      gpio_pad: inout std_logic_vector(alzpu_gpio_num-1 downto 0) -- GPIO connections (bidirectional)
    );
  end component;
  
  --MiniUART Component
  component alzpu_uart is
	 port(
		slave_in:  in zpu_slave_in_type;
      slave_out: out zpu_slave_out_type;
      interrupt: out std_logic;
		RxD_pad:   in std_logic;
		TxD_pad:   out std_logic
	 );
  end component;

  signal gpio_conn_slave_in: zpu_slave_in_type;
  signal gpio_conn_slave_out: zpu_slave_out_type;
  
  signal uart_slave_in: zpu_slave_in_type;
  signal uart_slave_out: zpu_slave_out_type;

  signal unconnected_slave_out: zpu_slave_out_type;
  
  signal uart_interrupt: std_logic;--Tang
begin

interrupt <= uart_interrupt;

gpiogen: if alzpu_gpio_enabled generate
  my_gpio: alzpu_gpio
    port map (
      slave_in  => gpio_conn_slave_in,
      slave_out => gpio_conn_slave_out,
      GPIO_PAD => GPIO_PAD
  );
end generate;

gpionotgen: if not alzpu_gpio_enabled generate
  my_gpio: alzpu_slave_none
    port map (
      slave_out => gpio_conn_slave_out
    );
end generate;

my_uart:alzpu_uart
	port map(
		slave_in  => uart_slave_in,
      slave_out => uart_slave_out,
      interrupt => uart_interrupt,
		RxD_pad   => RxD_pad,
		TxD_pad   => TxD_pad
		);

myslaveselect: alzpu_slaveselect4
  generic map (
    address_bits => 28,
	 slave0_address_size => 28,
    slave1_address_size => 28,
    slave2_address_size => 28,
    slave3_address_size => 28
  )
  port map (
    master_in => slave_in,
    master_out => slave_out,

    slave_in_0   => gpio_conn_slave_in,
    slave_out_0  => gpio_conn_slave_out,
    slave_in_1   => open,
	 slave_out_1  => unconnected_slave_out,
	 slave_out_2  => uart_slave_out,--Tang
    slave_in_2   => uart_slave_in,--Tang
    slave_in_3   => open,
    slave_out_3  => unconnected_slave_out
  );


end behave;
