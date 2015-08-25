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
use ieee.std_logic_unsigned.all;

library work;
use work.alzpu.all;
use work.zpu_config.all;
use work.zpupkg.all;
use work.alzpu_config.all;

package alzpu_wishbone is

component alzpu_wb_bridge is
  generic (
    address_size: natural := 32
  );
  port (
    slave_in  : in zpu_slave_in_type;
    slave_out : out zpu_slave_out_type;
    wb_sel_i  : out std_logic_vector(3 downto 0);
    wb_clk_i  : out std_logic;
    wb_rst_i  : out std_logic;
    wb_stb_i  : out std_logic;
    wb_cyc_i  : out std_logic;
    wb_we_i   : out std_logic;
    wb_adr_i  : out std_logic_vector(address_size-1 downto 0);
    wb_dat_i  : out std_logic_vector(wordSize-1 downto 0);
    wb_dat_o  : in std_logic_vector(wordSize-1 downto 0);
    wb_ack_o  : in std_logic
  );
end component;

end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.alzpu.all;
use work.zpu_config.all;
use work.zpupkg.all;
use work.alzpu_config.all;

entity alzpu_wb_bridge is
  generic (
    address_size: natural := 32
  );
  port (
      slave_in  : in zpu_slave_in_type;
      slave_out : out zpu_slave_out_type;
      wb_sel_i  : out std_logic_vector(3 downto 0);
      wb_clk_i  : out std_logic;
      wb_rst_i  : out std_logic;
      wb_stb_i  : out std_logic;
      wb_cyc_i  : out std_logic;
      wb_we_i   : out std_logic;
      wb_adr_i  : out std_logic_vector(address_size-1 downto 0);
      wb_dat_i  : out std_logic_vector(wordSize-1 downto 0);
      wb_dat_o  : in std_logic_vector(wordSize-1 downto 0);
      wb_ack_o  : in std_logic
  );

end alzpu_wb_bridge;

architecture behave of alzpu_wb_bridge is

signal addr_q   : std_logic_vector(address_size-1 downto 0);
signal data_q   : std_logic_vector(wordSize-1 downto 0);
signal enable_q : std_logic;
signal wr_q     : std_logic;
signal busy_int : std_logic;

begin

  wb_rst_i  <= slave_in.rst;
  wb_clk_i  <= slave_in.clk;
  wb_adr_i  <= addr_q;
  wb_dat_i  <= data_q;
  wb_we_i   <= wr_q;
  wb_sel_i  <= "1111";
  wb_cyc_i  <= enable_q;
  wb_stb_i  <= enable_q;


  slave_out.dato <= wb_dat_o;
  --slave_out.busy <= '1';

  slave_out.busy <= slave_in.rd_en or slave_in.wr_en or ( enable_q and not wb_ack_o);

  process( slave_in.clk, slave_in.rst )
  begin
    if slave_in.clk'event and slave_in.clk='1' then
      if slave_in.rst='1' then
        enable_q          <= '0';
        wr_q              <= '0';
      else
        if enable_q='0' then
          if slave_in.rd_en='1' or slave_in.wr_en='1' then
            enable_q          <= '1';

            addr_q            <= (others=>'0');
            addr_q(address_size-1 downto 0)  <= slave_in.addr(address_size-1 downto 0);
            data_q            <= slave_in.dati;
            wr_q              <= slave_in.wr_en;
          end if;
        else
          -- We're enabled. Check for ack.
          if wb_ack_o='1' then
            enable_q <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

end behave;
