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
   port (
      slave_in  : in zpu_slave_in_type;
      slave_out : out zpu_slave_out_type;

      -- Wishbone slave IN

      wb_sel_i  : out std_logic;
      wb_stb_i  : out std_logic;
      wb_adr_i  : out std_logic_vector(maxAddrBitIncIO downto 0);
      wb_dat_i  : out std_logic_vector(wordSize-1 downto 0);

      -- Wishbone slave OUT

      wb_dat_o  : in std_logic_vector(wordSize-1 downto 0);
      wb_ack_o  : in std_logic

      -- Other wishbone signals are unused
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
   port (
      slave_in  : in zpu_slave_in_type;
      slave_out : out zpu_slave_out_type;
      wb_sel_i  : out std_logic;
      wb_stb_i  : out std_logic;
      wb_adr_i  : out std_logic_vector(maxAddrBitIncIO downto 0);
      wb_dat_i  : out std_logic_vector(wordSize-1 downto 0);
      wb_dat_o  : in std_logic_vector(wordSize-1 downto 0);
      wb_ack_o  : in std_logic
  );

end alzpu_wb_bridge;

architecture behave of alzpu_wb_bridge is

begin

  wb_adr_i <= slave_in.addr;
  wb_dat_i <= slave_in.dati;

end behave;
