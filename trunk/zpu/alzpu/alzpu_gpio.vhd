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
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.alzpu.all;
use work.alzpu_config.all;

entity alzpu_gpio is
  port(
    slave_in: in zpu_slave_in_type;
    slave_out: out zpu_slave_out_type;
    gpio_pad: inout std_logic_vector(alzpu_gpio_num-1 downto 0) -- GPIO connections (bidirectional)
);
end alzpu_gpio;


architecture behave of alzpu_gpio is

type TRISTATE_TYPE is array (alzpu_gpio_num-1 downto 0) of boolean;
signal dat_q : std_logic_vector(alzpu_gpio_num-1 downto 0);
signal tris_q : TRISTATE_TYPE;
signal ack_q  : std_logic;

begin

buffs: for tr in 0 to alzpu_gpio_num-1 generate
begin
  gpio_pad(tr) <= 'Z' when tris_q(tr) else dat_q(tr);
end generate buffs;


process(slave_in.clk,slave_in.rst,ack_q)
begin
  if (slave_in.rst = '1') then
    for n in 0 to alzpu_gpio_num-1 loop
      tris_q(n) <= true;
    end loop;
    dat_q <= (others=>'0');

  elsif (slave_in.clk'event and slave_in.clk = '1') then
    if ( slave_in.wr_en='1'  or slave_in.rd_en ='1') then
      if ( slave_in.addr(2) = '1' ) then
        for n in 0 to alzpu_gpio_num-1 loop
          if slave_in.dati(n) = '1' then
            tris_q(n) <= true;
          else
            tris_q(n) <= false;
          end if;
        end loop;
      else
        if slave_in.wr_en = '1' then
          dat_q <= slave_in.dati(alzpu_gpio_num-1 downto 0);
        else 
          slave_out.dato(alzpu_gpio_num-1 downto 0) <= GPIO_PAD;
        end if;
      end if;
    end if;
  end if;
end process;

slave_out.busy <= slave_in.rd_en;

end behave;
