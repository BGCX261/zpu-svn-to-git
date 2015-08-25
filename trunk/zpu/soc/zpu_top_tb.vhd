library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity zpu_top_tb is
end zpu_top_tb;

architecture behave of zpu_top_tb is

signal clk     : std_logic;
signal areset	: std_logic := '1';
signal LED     : std_logic_vector(7 downto 0);
signal RxD_pad : std_logic;
signal TxD_pad : std_logic;

component zpu_top is
  port(
		clk : in std_logic;
		areset : in std_logic;
		LED    : inout std_logic_vector(7 downto 0);
		RxD_pad: in std_logic;
	   TxD_pad: out std_logic
		);
end component zpu_top;
		
begin

	myzpu_top : zpu_top
		port map(
			clk    => clk,
			areset => areset,
			LED    =>LED,
			RxD_pad => RxD_pad,
	      TxD_pad => TxD_pad
	);

	-- wiggle the clock @ 100MHz
	clock : PROCESS
		begin
				clk <= '0';
			wait for 10 ns; 
				clk <= '1';
			wait for 10 ns; 
	end PROCESS clock;
	
	areset <= '1','0' after 100 ns;
	LED(0) <= '0','1' after 200 ns;
	
	loopback : PROCESS(clk)
		begin
			RxD_pad <= TxD_pad;
	end PROCESS loopback;

end behave;