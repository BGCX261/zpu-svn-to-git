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
use ieee.std_logic_unsigned.all;

library work;
use work.zpupkg.all;
use work.alzpu.all;
use work.alzpu_config.all;

entity alzpu_rom is
  port (
    slave_in  : in zpu_slave_in_type;
    slave_out : out zpu_slave_out_type
  );
end entity alzpu_rom;

architecture behave of alzpu_rom is

  type regs_type is array (0 to 3) of std_logic_vector(31 downto 0);

  signal internal_regs : regs_type ;

  signal remap_registers : std_logic;
  signal access_to_remap_zone : boolean; --
  signal rom_dato : std_logic_vector(31 downto 0);

  component generic_rom is
    port(
      clk   : in std_logic;
      dato  : out std_logic_vector(31 downto 0);
      addr  : in std_logic_vector (alzpu_rom_num_bits-1 downto 0)
    );
  end component;

begin

  my_prom:  generic_rom
  port map(
    addr  => slave_in.addr(alzpu_rom_num_bits-1 downto 0),
    dato  => rom_dato,
    clk   => slave_in.clk
  );

  slave_out.busy <= slave_in.rd_en;

  process(slave_in.addr)
  begin
    case conv_integer(slave_in.addr(alzpu_rom_num_bits-1 downto 4)) is
      when 0      => access_to_remap_zone <= true;
      when others => access_to_remap_zone <= false;
    end case;
  end process;

  process(slave_in.rst,slave_in.clk)
  begin
    if slave_in.rst='1' then
      remap_registers <= '0';
    elsif rising_edge(slave_in.clk) then
      if slave_in.rd_en='1' or slave_in.wr_en='1' then
        if ( slave_in.wr_en='1' and access_to_remap_zone ) then
          remap_registers <= '1';
          internal_regs(conv_integer(slave_in.addr(3 downto 2))) <= slave_in.dati;
        end if;
      end if;
    end if;
  end process;

  process( slave_in.addr, rom_dato, access_to_remap_zone, remap_registers, internal_regs)
  begin
    if (conv_integer(slave_in.addr(alzpu_rom_num_bits-1 downto 5))=0 and remap_registers='1') then
      slave_out.dato <= internal_regs(conv_integer(slave_in.addr(3 downto 2)));
    else
      slave_out.dato <= rom_dato;
    end if;
  end process;
end behave;


