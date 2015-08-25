----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:34:31 11/22/2009 
-- Design Name: 
-- Module Name:    alzpu_uart - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.alzpu.all;
use work.alzpu_config.all;
---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity alzpu_uart is
	port(
		slave_in:  in zpu_slave_in_type;
      slave_out: out zpu_slave_out_type;
      interrupt: out std_logic;
		RxD_pad:   in std_logic;
		TxD_pad:   out std_logic
	 );
end alzpu_uart;

architecture Behavioral of alzpu_uart is
	component miniUART is
	 port (
		SysClk   : in  Std_Logic;  -- System Clock
		Reset    : in  Std_Logic;  -- Reset input
--		CS_N     : in  Std_Logic;
		RD     : in  Std_Logic;
		WR     : in  Std_Logic;
		RxD      : in  Std_Logic;
		TxD      : out Std_Logic;
		IntRx_N  : out Std_Logic;  -- Receive interrupt
		IntTx_N  : out Std_Logic;  -- Transmit interrupt
		Addr     : in  Std_Logic_Vector(1 downto 0); -- 
		DataIn   : in  Std_Logic_Vector(7 downto 0); -- 
		DataOut  : out Std_Logic_Vector(7 downto 0)  --
		);
	end component;
	
	signal IntRx_N : std_logic;
	signal IntTx_N : std_logic;
	signal RD : std_logic;
	signal WR : std_logic;
	signal Reset : std_logic;
	
begin

RD <= slave_in.rd_en;
WR <= slave_in.wr_en;
Reset <= not slave_in.rst;


my_miniUART: miniUART
	port map (
		SysClk   => slave_in.clk,
		Reset    => Reset,
--		CS_N     => '0',
		RD       => RD,
		WR     => WR,
		RxD      => RxD_pad,
		TxD      => Txd_pad,
		IntRx_N  => IntRx_N,
		IntTx_N  => IntTx_N,
		Addr     => slave_in.addr(1 downto 0),
		DataIn   => slave_in.dati(7 downto 0),
		DataOut  => slave_out.dato(7 downto 0)
		);
	interrupt <= IntRx_N or IntTx_N ;
	slave_out.busy <= slave_in.rd_en;
end Behavioral;

