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
library work;
use work.alzpu.all;
use work.zpupkg.all;
use work.txt_util.all;

package alzpu_slaveselect is

component alzpu_slaveselect4 is
  generic (
    address_bits: natural;
    slave0_address_size: natural := 27;
    slave1_address_size: natural := 27;
    slave2_address_size: natural := 27;
    slave3_address_size: natural := 27
  );
  port (
    master_in   : in zpu_slave_in_type;
    master_out  : out zpu_slave_out_type;

    slave_in_0  : out zpu_slave_in_type;
    slave_out_0 : in zpu_slave_out_type;
    slave_in_1  : out zpu_slave_in_type;
    slave_out_1 : in zpu_slave_out_type;
    slave_in_2  : out zpu_slave_in_type;
    slave_out_2 : in zpu_slave_out_type;
    slave_in_3  : out zpu_slave_in_type;
    slave_out_3 : in zpu_slave_out_type
  );
end component;

component alzpu_slave_none is
  port (
  --  slave_in  : in zpu_slave_in_type;
    slave_out : out zpu_slave_out_type
  );
end component;

end package;
library work;
use work.alzpu_slaveselect.all;
use work.alzpu.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity alzpu_slaveselect4 is
  generic (
    address_bits: natural := 32;
    slave0_address_size: natural := 32;
    slave1_address_size: natural := 32;
    slave2_address_size: natural := 32;
    slave3_address_size: natural := 32
  );
  port (
    master_in   : in zpu_slave_in_type;
    master_out  : out zpu_slave_out_type;

    slave_in_0  : out zpu_slave_in_type;
    slave_out_0 : in zpu_slave_out_type;
    slave_in_1  : out zpu_slave_in_type;
    slave_out_1 : in zpu_slave_out_type;
    slave_in_2  : out zpu_slave_in_type;
    slave_out_2 : in zpu_slave_out_type;
    slave_in_3  : out zpu_slave_in_type;
    slave_out_3 : in zpu_slave_out_type
  );
end alzpu_slaveselect4;

architecture behave of alzpu_slaveselect4 is

  subtype sel_type is std_logic_vector(2 downto 0);

  signal slave_sel: std_logic_vector(2 downto 0);
  signal slave_sel_q: std_logic_vector(2 downto 0);
  signal slave_sel_int: std_logic_vector(2 downto 0);

  signal address: std_logic_vector(1 downto 0);
  signal busy_q: std_logic;
  signal busy_int: std_logic;

  signal slave_en: std_logic_vector(3 downto 0);
  signal slave_rd_en: std_logic_vector(3 downto 0);
  signal slave_wr_en: std_logic_vector(3 downto 0);

begin

  slave_sel <= master_in.addr(27 downto 25);
    
  busy_int <= '1' when
    slave_out_0.busy='1' or
    slave_out_1.busy='1' or
    slave_out_2.busy='1' or
    slave_out_3.busy='1'
    else '0';

  master_out.busy <= busy_int;

  slave_sel_int <= slave_sel when busy_q='0' else slave_sel_q;

  process( master_in.clk, master_in.rst)
  begin
    if master_in.clk'event and master_in.clk='1' then
      if master_in.rst='1' then
        slave_sel_q <= (others => '0');
        busy_q <= '0';
--		  master_out.dato <= x"00000000";
--        master_out.busy <= '0';
      else
        if master_in.rd_en='1' or master_in.wr_en='1' then
          slave_sel_q <= slave_sel;
          busy_q <= busy_int;
        end if;
      end if;
    end if;
  end process;

  slavesel: with sel_type'(slave_sel_int) select
    master_out.dato <=
      slave_out_0.dato when "110",
      slave_out_1.dato when "101",
      slave_out_2.dato when "100",
      slave_out_3.dato when "111",
      x"00000000" when others;

  -- Slave enable

  slave_en(0) <= '1' when slave_sel = "110" else '0';
  slave_en(1) <= '1' when slave_sel = "101" else '0';
  slave_en(2) <= '1' when slave_sel = "100" else '0';
  slave_en(3) <= '1' when slave_sel = "111" else '0';

  -- Slave read signals
  rdsiggen: for slv in 0 to 3 generate
    slave_rd_en(slv) <= '1' when slave_en(slv)='1'
      and master_in.rd_en='1' else '0';
  end generate;

  -- Slave write signals
  wrsiggen: for slv in 0 to 3 generate
    slave_wr_en(slv) <= '1' when slave_en(slv)='1'
      and master_in.wr_en='1' else '0';
  end generate;

  -- Slave interconnection

  slave_in_0.clk <= master_in.clk;
  slave_in_0.rst <= master_in.rst;
  slave_in_0.addr(slave0_address_size-1 downto 0) <= master_in.addr(slave0_address_size-1 downto 0);
  slave_in_0.dati <= master_in.dati;
  slave_in_0.rd_en <= slave_rd_en(0);
  slave_in_0.wr_en <= slave_wr_en(0);

  slave_in_1.clk <= master_in.clk;
  slave_in_1.rst <= master_in.rst;
  slave_in_1.addr(slave1_address_size-1 downto 0) <= master_in.addr(slave1_address_size-1 downto 0);
  slave_in_1.dati <= master_in.dati;
  slave_in_1.rd_en <= slave_rd_en(1);
  slave_in_1.wr_en <= slave_wr_en(1);

  slave_in_2.clk <= master_in.clk;
  slave_in_2.rst <= master_in.rst;
  slave_in_2.addr(slave2_address_size-1 downto 0) <= master_in.addr(slave2_address_size-1 downto 0);
  slave_in_2.dati <= master_in.dati;
  slave_in_2.rd_en <= slave_rd_en(2);
  slave_in_2.wr_en <= slave_wr_en(2);

  slave_in_3.clk <= master_in.clk;
  slave_in_3.rst <= master_in.rst;
  slave_in_3.addr(slave3_address_size-1 downto 0) <= master_in.addr(slave3_address_size-1 downto 0);
  slave_in_3.dati <= master_in.dati;
  slave_in_3.rd_en <= slave_rd_en(3);
  slave_in_3.wr_en <= slave_wr_en(3);
  
end behave;

library work;
use work.alzpu_slaveselect.all;
use work.alzpu.all;
use work.txt_util.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity alzpu_slave_none is
  port (
  --  slave_in  : in zpu_slave_in_type;
    slave_out : out zpu_slave_out_type
  );
end alzpu_slave_none;

architecture behave of alzpu_slave_none is
begin

slave_out.dato <= x"00000000";
slave_out.busy <= '0';

--process(slave_in.clk)
--begin
--  if slave_in.clk'event and slave_in.clk='1' then
--    if slave_in.rd_en='1' or slave_in.wr_en='1' then
--      report "Invalid access to unconnected slave, address " & hstr(slave_in.addr)  severity failure;
--    end if;
--  end if;
--end process;

end behave;
