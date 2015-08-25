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
library work;
use work.alzpu.all;

package alzpu_ethernet is

type eth_mii_in_type is record
  Rx_clk            : std_logic;
  Tx_clk            : std_logic;

  Rx_er             : std_logic;
  Rx_dv             : std_logic;
  Rxd               : std_logic_vector(7 downto 0);
  Crs               : std_logic;
  Col               : std_logic;
  Mdi               : std_logic;
end record;

type eth_mii_out_type is record
  Mdc               : std_logic;
  Tx_er             : std_logic;
  Tx_en             : std_logic;
  Txd               : std_logic_vector(7 downto 0);
  Mdo               : std_logic;
  MdoEn             : std_logic;
end record;

component alzpu_eth_mii_mac is
  port (
  slave_in          : in zpu_slave_in_type;
  slave_out         : out zpu_slave_out_type;

  interrupt         : out std_logic;

  eth_mii_in        : in eth_mii_in_type;
  eth_mii_out       : out eth_mii_out_type
);
end component;

end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;

use work.zpupkg.all;
use work.zpu_config.all;
use work.txt_util.all;
use work.alzpu.all;
use work.alzpu_config.all;
use work.alzpu_slaveselect.all;
use work.alzpu_wishbone.all;
use work.alzpu_ethernet.all;
use work.tech_generic.all;

entity alzpu_eth_mii_mac is
  port (
  slave_in          : in zpu_slave_in_type;
  slave_out         : out zpu_slave_out_type;

  interrupt         : out std_logic;

  eth_mii_in        : in eth_mii_in_type;
  eth_mii_out       : out eth_mii_out_type
);

end alzpu_eth_mii_mac;

architecture behave of alzpu_eth_mii_mac is

component MAC_top is
port (
  Reset             : in std_logic;
  Clk_125M          : in std_logic;
  Clk_user          : in std_logic;
  Clk_reg           : in std_logic;
  Speed             : out std_logic_vector(2 downto 0);

  --user interface

  Rx_mac_ra         : out std_logic;
  Rx_mac_rd         : in std_logic;
  Rx_mac_data       : out std_logic_vector(31 downto 0);
  Rx_mac_BE         : out std_logic_vector(1 downto 0);
  Rx_mac_pa         : out std_logic;
  Rx_mac_sop        : out std_logic;
  Rx_mac_eop        : out std_logic;

  -- user interface

  Tx_mac_wa         : out std_logic;
  Tx_mac_wr         : in std_logic;
  Tx_mac_data       : in std_logic_vector(31 downto 0);
  Tx_mac_BE         : in std_logic_vector(1 downto 0);
  Tx_mac_sop        : in std_logic;
  Tx_mac_eop        : in std_logic;

   -- pkg_lgth fifo

  Pkg_lgth_fifo_rd  : in std_logic;
  Pkg_lgth_fifo_ra  : out std_logic;
  Pkg_lgth_fifo_data: out std_logic_vector(15 downto 0);

  -- Phy interface

  Gtx_clk           : out std_logic;
  Rx_clk            : in std_logic;
  Tx_clk            : in std_logic;
  Tx_er             : out std_logic;
  Tx_en             : out std_logic;
  Txd               : out std_logic_vector(7 downto 0);
  Rx_er             : in std_logic;
  Rx_dv             : in std_logic;
  Rxd               : in std_logic_vector(7 downto 0);
  Crs               : in std_logic;
  Col               : in std_logic;

  -- host interface

  CSB               : in std_logic;
  WRB               : in std_logic;
  CD_in             : in std_logic_vector(15 downto 0);
  CD_out            : out std_logic_vector(15 downto 0);
  CA                : in std_logic_vector(7 downto 0);

  -- mdx

  Mdo               : out std_logic;
  MdoEn             : out std_logic;
  Mdi               : in std_logic;
  Mdc               : out std_logic
);
end component;


signal s_rx_mac_ra         : std_logic;
signal s_rx_mac_rd         : std_logic;
signal s_rx_mac_data       : std_logic_vector(31 downto 0);
signal s_rx_mac_be         : std_logic_vector(1 downto 0);
signal s_rx_mac_pa         : std_logic;
signal s_rx_mac_sop        : std_logic;
signal s_rx_mac_eop        : std_logic;

signal s_tx_mac_wa         : std_logic;
signal s_Tx_mac_wr         : std_logic;
signal s_Tx_mac_data       : std_logic_vector(31 downto 0);
signal s_Tx_mac_BE         : std_logic_vector(1 downto 0);
signal s_Tx_mac_sop        : std_logic;
signal s_Tx_mac_eop        : std_logic;

signal host_CSB            : std_logic;
signal host_WRB            : std_logic;
signal host_CD_in          : std_logic_vector(15 downto 0);
signal host_CD_out         : std_logic_vector(15 downto 0);
signal host_CA             : std_logic_vector(7 downto 0);


signal eth_ram_wren: std_logic;
signal eth_ram_read: std_logic_vector(31 downto 0);
signal eth_tx_ram_wren: std_logic;
signal eth_tx_ram_a: std_logic_vector(10 downto 0);
signal eth_rx_ram_data: std_logic_vector(31 downto 0);
signal eth_tx_ram_data: std_logic_vector(31 downto 0);

signal control_out: std_logic_vector(31 downto 0);

signal tx_buffer_size: integer;
signal tx_extra_bytes: std_logic_vector(1 downto 0);
signal tx_buffer_offset: integer;

signal tx_buffer_transmitting: std_logic;
signal eth_do_transmit_buffer: boolean;
signal eth_do_transmit_buffer_dly: boolean;
signal eth_start_xmit:  std_logic;

signal sel_registers : boolean;
signal sel_control : boolean;
signal sel_ram : boolean;
signal sel_ram_rx : boolean;

signal rx_ram_ready: std_logic;
signal eth_rx_ram_wren: std_logic;
signal eth_rx_write_data: std_logic_vector(31 downto 0);
signal eth_rx_write_addr: integer;
signal eth_rx_write_addr_v: std_logic_vector(9 downto 0);
signal eth_rx_packet_ready: std_logic;
signal packet_ready_q: std_logic;
signal rx_int_en: std_logic;



begin

my_mac_top: mac_top
  port map (
  Reset             => slave_in.rst,
  Clk_125M          => '0',
  Clk_user          => slave_in.clk,
  Clk_reg           => slave_in.clk,
  Speed             => open,

  --user interface

  Rx_mac_ra         => s_rx_mac_ra,
  Rx_mac_rd         => s_rx_mac_rd,
  Rx_mac_data       => s_rx_mac_data,
  Rx_mac_BE         => s_rx_mac_be,
  Rx_mac_pa         => s_rx_mac_pa,
  Rx_mac_sop        => s_rx_mac_sop,
  Rx_mac_eop        => s_rx_mac_eop,
                                 
  -- user interface

  Tx_mac_wa         => s_tx_mac_wa,
  Tx_mac_wr         => s_tx_mac_wr,
  Tx_mac_data       => s_tx_mac_data,
  Tx_mac_BE         => s_tx_mac_be,
  Tx_mac_sop        => s_tx_mac_sop,
  Tx_mac_eop        => s_tx_mac_eop,

   -- pkg_lgth fifo

  Pkg_lgth_fifo_rd  => '0',
  Pkg_lgth_fifo_ra  => open,
  Pkg_lgth_fifo_data=> open,

  -- Phy interface

  Gtx_clk           => open,
  Rx_clk            => eth_mii_in.Rx_clk,
  Tx_clk            => eth_mii_in.Tx_clk,
  Tx_er             => eth_mii_out.Tx_er,
  Tx_en             => eth_mii_out.Tx_en,
  Txd               => eth_mii_out.Txd,
  Rx_er             => eth_mii_in.Rx_er,
  Rx_dv             => eth_mii_in.Rx_dv,
  Rxd               => eth_mii_in.Rxd,
  Crs               => eth_mii_in.Crs,
  Col               => eth_mii_in.Col,

  -- host interface

  CSB               => host_csb,
  WRB               => host_wrb,
  CD_in             => host_cd_in,
  CD_out            => host_cd_out,
  CA                => host_ca,

  -- mdx

  Mdo               => eth_mii_out.Mdo,
  MdoEn             => eth_mii_out.MdoEn,
  Mdi               => eth_mii_in.Mdi,
  Mdc               => eth_mii_out.Mdc
);



-- Signals for ethernet host interface (registers)

host_csb <= '0' when ( slave_in.rd_en='1' or slave_in.wr_en='1') and sel_registers else '1';
host_wrb <= '0' when slave_in.wr_en='1' else '1';
host_cd_in <= slave_in.dati(15 downto 0);  
slave_out.busy <= slave_in.rd_en;
host_ca <= slave_in.addr(8 downto 1); -- Needed for alignment.

-- Muxer

process( slave_in.addr,host_CD_out,control_out,eth_ram_read,eth_rx_ram_data )
begin
  sel_registers <= false;
  sel_control <= false;
  sel_ram <= false;
  sel_ram_rx <= false;

  case slave_in.addr(11 downto 10) is
    when "00" => sel_registers <= true;
                 slave_out.dato(15 downto 0) <= host_cd_out;
    when "01" => sel_control <= true;
                 slave_out.dato <= (others=>DontCareValue);
                 slave_out.dato <= control_out;
    when "10" => sel_ram <= true;
                 slave_out.dato <= eth_ram_read;
    when "11" => sel_ram_rx <= true;
                 slave_out.dato <= eth_rx_ram_data;
    when others =>
  end case;
end process;


eth_ram_wren <= '1' when sel_ram and slave_in.wr_en='1' else '0';

my_dp_ram: generic_dp_ram
  generic map (
    ABITS => 11
  )
  port map (
    a_clk => slave_in.clk,
    a_we  => eth_ram_wren,
    a_a   => slave_in.addr(10 downto 0),
    a_di  => slave_in.dati,
    a_do  => eth_ram_read,

    b_clk => slave_in.clk,
    --b_we  => eth_tx_ram_wren,
    b_a   => eth_tx_ram_a,
    --b_di  => eth_rx_ram_data,
    b_do  => eth_tx_ram_data
);

-- Control process.
ctrlprocess: process( slave_in.clk, slave_in.rst )
  variable packet_size_words: std_logic_vector(13 downto 0);
begin

  packet_size_words := slave_in.dati(15 downto 2);

  if rising_edge(slave_in.clk) then
    if slave_in.rst='1' then
      eth_start_xmit <= '0';
      rx_int_en <= '0';
      rx_ram_ready <= '0';
      interrupt <= '0';
      packet_ready_q <= '0';
    else
      
      if eth_rx_packet_ready ='1' and rx_int_en='1' then
        interrupt <= '1';
      end if;

      if eth_rx_packet_ready='1' then
        rx_ram_ready <= '0';
        packet_ready_q <= '1';
      end if;

      eth_start_xmit <= '0';

      if sel_control then
        -- Control access
        if slave_in.wr_en = '1' then
          -- Packet size is lower 16 bits. This is in 32-bit words.
          case (slave_in.addr(2)) is
            when '0' =>
              report "ETH: Setting TX packet size to " & hstr(packet_size_words) severity note;
              tx_extra_bytes <= slave_in.dati(1 downto 0);
              if slave_in.dati(1 downto 0) = "00" then
                tx_buffer_size <= conv_integer(packet_size_words);
              else
                tx_buffer_size <= conv_integer(packet_size_words) + 1;
              end if;

              report "ETH: Setting TX start xmit to " & chr(slave_in.dati(16)) severity note;
              eth_start_xmit <= slave_in.dati(16);
            when '1' =>
              rx_ram_ready   <= slave_in.dati(0);
              report "ETH: Setting RX ready to " & chr(slave_in.dati(0)) severity note;
              rx_int_en      <= slave_in.dati(1);
              report "ETH: Setting RX interrupt enable to " & chr(slave_in.dati(1)) severity note;
              interrupt      <= '0';
              packet_ready_q <= '0';
            when others =>
          end case;
          --report "Access " & hstr(slave_in.addr) severity failure;
        else
          -- Read
          control_out <= (others => '0');
          control_out(10 downto 0) <= conv_std_logic_vector(eth_rx_write_addr,11);
          control_out(16) <= packet_ready_q;
          
        end if;
      end if;
    end if;
  end if;
end process;


eth_tx_ram_a(10 downto 2) <= conv_std_logic_vector( tx_buffer_offset, 9);

s_tx_mac_data <= eth_tx_ram_data;

txprocess: process( slave_in.clk, slave_in.rst )
begin
  if rising_edge(slave_in.clk) then
    if slave_in.rst='1' then
      s_tx_mac_wr  <= '0';
      s_tx_mac_sop  <= '0';
      s_tx_mac_eop  <= '0';
      eth_do_transmit_buffer <= false;
      eth_do_transmit_buffer_dly <= false;
      
      tx_buffer_offset<=0;
      tx_buffer_transmitting <= '0';


      --rx_ram_ready <= '1';
    else

    s_tx_mac_be <= tx_extra_bytes;

    if eth_start_xmit = '1' then
      eth_do_transmit_buffer_dly <= true; -- One clock delay for RAM to read
      tx_buffer_offset<=0;
    end if;
    eth_do_transmit_buffer <= eth_do_transmit_buffer_dly;

    if eth_do_transmit_buffer then
      if s_tx_mac_wa='1' then
        -- Transmit
        s_tx_mac_wr  <= '1';
        s_tx_mac_sop <= not tx_buffer_transmitting; -- Start of packet

        if (tx_buffer_size=tx_buffer_offset) then
          tx_buffer_transmitting <= '0';
          eth_do_transmit_buffer_dly <= false;
          eth_do_transmit_buffer <= false; -- I don't like this. But its easier
          s_tx_mac_eop <= '1';
        else
          tx_buffer_transmitting <= '1';
          s_tx_mac_eop <= '0';
        end if;     -- End of packet

        --s_tx_mac_be  <= "11";
        tx_buffer_offset <= tx_buffer_offset + 1;
        
      else
        s_tx_mac_wr <= '0';
      end if;
    else
      s_tx_mac_wr <= '0';
      s_tx_mac_eop <= '0';
    end if;
  end if;
  end if;
end process;

-- Receive RAM


--eth_rx_ram_wren <= '1' when sel_ram_rx and slave_in.wr_en='1' else '0';

eth_rx_write_addr_v <= conv_std_logic_vector(eth_rx_write_addr,8);


my_dp_rx_ram: generic_dp_ram
  generic map (
    ABITS => 10
  )
  port map (
    a_clk => slave_in.clk,
    a_we  => eth_rx_ram_wren,
    a_a   => eth_rx_write_addr_v,
    a_di  => eth_rx_write_data,
    a_do  => open,

    b_clk => slave_in.clk,
    b_a   => slave_in.addr(9 downto 0),
    b_do  => eth_rx_ram_data
);

process(slave_in.clk, slave_in.rst)
begin
  if slave_in.clk'event and slave_in.clk='1' then
    if slave_in.rst='1' then
      eth_rx_write_addr <= 0;
      eth_rx_packet_ready <= '0';
      eth_rx_ram_wren <= '0';
    else
      s_rx_mac_rd <= '0';
      eth_rx_ram_wren <= '0';

      if rx_ram_ready='1' then
        -- We're ready to receive any packet
        s_rx_mac_rd <= '1';

        if s_rx_mac_ra='1' then
          -- Ready too.
          if s_rx_mac_pa='1' then
            -- Packet on the way
            eth_rx_ram_wren <= '1';
            eth_rx_write_data <= s_rx_mac_data;
            if s_rx_mac_sop='1' then
              -- Fisrt data of packet
              eth_rx_write_addr <= 0;
              --eth_rx_packet_size <= 1;
            else
              eth_rx_write_addr <= eth_rx_write_addr +1;
            end if;

            if s_rx_mac_eop='1' then
              eth_rx_packet_ready <= '1';
            end if;
          end if;
        end if;
      else
        -- Not ready.
        --  s_rx_mac_ra <= '0';
        eth_rx_packet_ready <= '0';
      end if;
    end if;
  end if;
end process;

end behave;

