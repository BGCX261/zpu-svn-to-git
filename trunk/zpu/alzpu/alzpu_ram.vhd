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
use work.tech_generic.all;
use work.txt_util.all;
use work.zpupkg.all;
use work.alzpu_config.all;
use work.alzpu.all;

entity alzpu_ram is
  port(
    slave_in  : in zpu_slave_in_type;
    slave_out : out zpu_slave_out_type
  );
end alzpu_ram;
 
architecture behave of alzpu_ram is
begin

  slave_out.busy <= slave_in.rd_en;

  u1:  generic_ram
    generic map(
      dbits   => wordSize,
      abits   => alzpu_ram_num_bits
	  )
    port map(
      di     => slave_in.dati,
      a      => slave_in.addr(alzpu_ram_num_bits-1 downto 0),
      we     => slave_in.wr_en,
      do     => slave_out.dato,
      clk    => slave_in.clk
    );


-- synthesis translate_off

--process( slave_in.clk )
--begin
--    if rising_edge(slave_in.clk) then
--      if slave_in.wr_en='1' then
--        report "RAM Write to address " & hstr(slave_in.addr) & ", value " & hstr(slave_in.dati) severity note;
--      end if;
--      if slave_in.rd_en='1' then
--        report "RAM Read from address " & hstr(slave_in.addr);
--      end if;
--    end if;
--end process;

-- synthesis translate_on

end behave;
