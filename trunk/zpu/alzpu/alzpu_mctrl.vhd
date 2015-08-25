--
--  ALZPU 
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library work;

use work.zpupkg.all;
use work.zpu_config.all;
use work.txt_util.all;
use work.alzpu.all;
use work.alzpu_config.all;
use work.alzpu_slaveselect.all;
--use work.alzpu_wishbone.all;
--use work.alzpu_ethernet.all;

entity alzpu_mctrl is
  port(
    slave_in  : in zpu_slave_in_type;
    slave_out : out zpu_slave_out_type;
    interrupt : out std_logic;
    gpio_pad    : inout std_logic_vector(alzpu_gpio_num-1 downto 0);
	 RxD_pad:   in std_logic;
	 TxD_pad:   out std_logic;
  );

end entity alzpu_mctrl;

architecture behave of alzpu_mctrl is

component alzpu_io is
   port (
      slave_in: in zpu_slave_in_type;
      slave_out: out zpu_slave_out_type;
      interrupt: out std_logic;
      gpio_pad: inout std_logic_vector(alzpu_gpio_num-1 downto 0);
		RxD_pad:   in std_logic;
		TxD_pad:   out std_logic
   );
end component;

signal io_interrupt      : std_logic;

begin

interrupt <= io_interrupt;

my_io : alzpu_io
  port map(
    slave_in  => slave_in,
    slave_out => slave_out,
    interrupt => io_interrupt,
    gpio_pad => gpio_pad,
    sdout_pad => sdout_pad,
	 RxD_pad => RxD_pad,
	 TxD_pad => TxD_pad
);

end architecture;



