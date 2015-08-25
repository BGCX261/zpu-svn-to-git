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
use IEEE.STD_LOGIC_ARITH.all;

library work;
use work.zpupkg.all;
use work.zpu_config.all;
use work.alzpu.all;
use work.alzpu_config.all;
use work.alzpu_ethernet.all;


entity alzpu_top is
port (
  clk : in std_logic;
  rst : in std_logic;
  LED : inout std_logic_vector(7 downto 0);
--  spi_mosi_pad: out std_logic;
--  spi_miso_pad: in std_logic;
--  spi_clk_pad : out std_logic;
--  spi_seln_pad: out std_logic;
--  sdout_pad: out std_logic;

  -- Ethernet connections
  e_col   :   in std_logic;
  e_crs   :   in std_logic;
  e_mdc   :   out std_logic;
  e_mdio  :   inout std_logic;
  e_rx_clk:   in std_logic;
  e_rx_dv :   in std_logic;
  e_rxd  :   in std_logic_vector(4 downto 0);
  e_tx_clk:   in std_logic;
  e_tx_en :   out std_logic;
  e_txd  :   out std_logic_vector(4 downto 0)
);

end alzpu_top;

architecture behave of alzpu_top is

signal read_data : std_logic_vector(wordSize-1 downto 0);
signal busy : std_logic;
signal write_data : std_logic_vector(wordSize-1 downto 0);
signal addr : std_logic_vector(MaxAddrBitIncIO downto 0);
signal read_en : std_logic;
signal write_en : std_logic;

signal eth_mii_in: eth_mii_in_type;
signal eth_mii_out: eth_mii_out_type;


component zpu_core is
    Port ( clk : in std_logic;
	 		  areset : in std_logic;
	 		  enable : in std_logic; 
	 		  in_mem_busy : in std_logic; 
	 		  mem_read : in std_logic_vector(wordSize-1 downto 0);
	 		  mem_write : out std_logic_vector(wordSize-1 downto 0);			  
	 		  out_mem_addr : out std_logic_vector(maxAddrBitIncIO downto 0);
			  out_mem_writeEnable : out std_logic; 
			  out_mem_readEnable : out std_logic;
	 		  mem_writeMask: out std_logic_vector(wordBytes-1 downto 0);
	 		  interrupt : in std_logic;
	 		  break : out std_logic
    );
end component;

component alzpu_mctrl is
  port(
    slave_in  : in zpu_slave_in_type;
    slave_out : out zpu_slave_out_type;
    interrupt : out std_logic;
    -- GPIO connections
    gpio_pad    : inout std_logic_vector(alzpu_gpio_num-1 downto 0);
    -- SPI connections
    spi_mosi_pad: out std_logic;
    spi_miso_pad: in std_logic;
    spi_clk_pad : out std_logic;
    spi_seln_pad: out std_logic;

    sdout_pad: out std_logic;

    -- Ethernet

    eth_mii_in: in eth_mii_in_type;
    eth_mii_out: out eth_mii_out_type

  );
end component alzpu_mctrl;


signal slave_in: zpu_slave_in_type;
signal slave_out: zpu_slave_out_type;
signal zpu_int: std_logic;

begin

memoryctrl : alzpu_mctrl
	port map(
    slave_in  => slave_in,
    slave_out => slave_out,
    interrupt => zpu_int,
    gpio_pad  => LED,
    sdout_pad => open,--sdout_pad,
    spi_mosi_pad  => open,--spi_mosi_pad,
    spi_miso_pad  => '0',--spi_miso_pad,
    spi_clk_pad   => open,--spi_clk_pad,
    spi_seln_pad  => open,--spi_seln_pad,
    eth_mii_in => eth_mii_in,
    eth_mii_out => eth_mii_out
);

-- Ethernet MII interconnection

ethmiiconn: if alzpu_use_ethernet generate

  eth_mii_in.Col <= e_col;
  eth_mii_in.Crs <= e_crs;
  e_mdc <= eth_mii_out.Mdc;

  e_mdio  <= eth_mii_out.Mdo when eth_mii_out.MdoEn='1' else 'Z';

  eth_mii_in.Rx_clk <= e_rx_clk;
  eth_mii_in.Rx_dv  <= e_rx_dv;
  eth_mii_in.Rx_er  <= '0';

--  e_mdio  <= :   inout std_logic;
--  e_rx_clk:   in std_logic;
--  e_rx_dv :   in std_logic;
  eth_mii_in.Rxd(4 downto 0) <= e_rxd;
--  e_rx_d  :   in std_logic_vector(7 downto 0);
  eth_mii_in.Tx_clk <= e_tx_clk;
--  e_tx_clk:   in std_logic;
--  eth_mii_out.Tx_en <= e_tx_en;
  e_tx_en <= eth_mii_out.Tx_en;
--  e_tx_en :   out std_logic;
  e_txd <= eth_mii_out.Txd(4 downto 0);
  --  e_tx_d  :   out std_logic_vector(7 downto 0);
end generate;


slave_in.clk <= clk;
slave_in.rst <= rst;

zpu:
    zpu_core port map (
    areset          => rst,
    clk             => clk,
    enable          => '1',
    interrupt       => zpu_int,
    in_mem_busy     => slave_out.busy,
	 	mem_read        => slave_out.dato,
	 	mem_write       => slave_in.dati,
	 	out_mem_addr    => slave_in.addr,
    out_mem_writeEnable => slave_in.wr_en,
		out_mem_readEnable  => slave_in.rd_en,
	 	mem_writeMask   => open,
	 	break           => open
);



end behave;
