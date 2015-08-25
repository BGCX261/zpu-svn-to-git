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

package tech_generic is

component generic_ram is
   generic (
      ABITS: integer := 11;
      DBITS: integer := 32
   );
  	port (clk : in std_logic;
        	we  : in std_logic;
        	a   : in std_logic_vector(ABITS-1 downto 0);
        	di  : in std_logic_vector(DBITS-1 downto 0);  -- data input
        	do  : out std_logic_vector(DBITS-1 downto 0)); --data output
end component;

component generic_dp_ram is
   generic (
      ABITS: integer := 11;
      DBITS: integer := 32
   );
  	port (a_clk : in std_logic;
        	a_we  : in std_logic;
        	a_a   : in std_logic_vector(ABITS-1 downto 0);
        	a_di  : in std_logic_vector(DBITS-1 downto 0);  -- data input
        	a_do  : out std_logic_vector(DBITS-1 downto 0); --data output
          b_clk : in std_logic;
        	--b_we  : in std_logic;
        	b_a   : in std_logic_vector(ABITS-1 downto 0);
          --b_di  : in std_logic_vector(DBITS-1 downto 0);  -- data input
        	b_do  : out std_logic_vector(DBITS-1 downto 0) --data output
    );
end component;

end;

library ieee;  
use ieee.std_logic_1164.all;  
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


entity generic_ram is
   generic (
      ABITS: integer := 11;
      DBITS: integer := 32
   );
  	port (clk : in std_logic;
        	we  : in std_logic;
        	a   : in std_logic_vector(ABITS-1 downto 0);
        	di  : in std_logic_vector(DBITS-1 downto 0);
        	do  : out std_logic_vector(DBITS-1 downto 0));

end generic_ram;

architecture behave of generic_ram is
  type ram_type is array ( 0 to  2**(ABITS-2)-1 )
    of std_logic_vector (DBITS-1 downto 0);

  signal RAM : ram_type;
  signal read_a : std_logic_vector(ABITS-3 downto 0);

begin  

  process (clk)
    variable r_addr: std_logic_vector(ABITS-3 downto 0);
  begin
    if (clk'event and clk = '1') then
      r_addr:=a(ABITS-1 downto 2);
      if (we = '1') then  
        RAM(conv_integer(r_addr)) <= di;
      end if;  
      read_a <= r_addr; --a(ABITS-1 downto 2);
    end if;  
  end process;  

  do <= RAM(conv_integer(read_a));

end behave;


library ieee;  
use ieee.std_logic_1164.all;  
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
library work;
use work.txt_util.all;


entity generic_dp_ram is
   generic (
      ABITS: integer := 11;
      DBITS: integer := 32
   );
  	port (a_clk : in std_logic;
        	a_we  : in std_logic;
        	a_a   : in std_logic_vector(ABITS-1 downto 0);
        	a_di  : in std_logic_vector(DBITS-1 downto 0);  -- data input
        	a_do  : out std_logic_vector(DBITS-1 downto 0); --data output
          b_clk : in std_logic;
        	--b_we  : in std_logic;
        	b_a   : in std_logic_vector(ABITS-1 downto 0);
        	--b_di  : in std_logic_vector(DBITS-1 downto 0);  -- data input
        	b_do  : out std_logic_vector(DBITS-1 downto 0)
    );

end generic_dp_ram;

architecture behave of generic_dp_ram is
  type ram_type is array ( 0 to  2**(ABITS-2)-1 )
    of std_logic_vector (DBITS-1 downto 0);

  signal RAM : ram_type;
  signal read_a : std_logic_vector(ABITS-3 downto 0);
  signal read_b : std_logic_vector(ABITS-3 downto 0);

begin  

  process (a_clk)

  variable r_addr: std_logic_vector(ABITS-3 downto 0);

  begin
    if (a_clk'event and a_clk = '1') then
      r_addr := a_a(ABITS-1 downto 2);
      if (a_we = '1') then
        report "DP RAM PORTA write: linear address " & hstr(r_addr) &
          " data " & hstr(a_di);
        RAM(conv_integer(r_addr)) <= a_di;
      end if;  
      read_a <= r_addr;
    end if;  
  end process;  

  a_do <= RAM(conv_integer(read_a));

  process (b_clk)
    variable r_addr: std_logic_vector(ABITS-3 downto 0);
  begin  
    if (b_clk'event and b_clk = '1') then
      r_addr:= b_a(ABITS-1 downto 2);
      --if (b_we = '1') then
      --  RAM(conv_integer(b_a(ABITS-1 downto 2))) <= b_di;
      --end if;
      read_b <= r_addr;
    end if;  
  end process;  

  b_do <= RAM(conv_integer(read_b));

end behave;
