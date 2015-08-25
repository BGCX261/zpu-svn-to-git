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

entity alzpu_lcd is
  generic (
      LCD_SETUP_CLOCKS  : positive := 10; -- Number of clocks to setup data
      LCD_HOLD_CLOCKS   : positive := 45; -- Number of clocks to hold clock high
      LCD_NHOLD_CLOCKS  : positive := 10  -- Number of clocks to hold data and clock low
  );
  port (
    clk    : in std_logic;
    rst    : in std_logic;
    addr   : in std_logic_vector(4 downto 0);
    dati   : in std_logic_vector(31 downto 0);
    en     : in std_logic;
    we     : in std_logic;
    dato   : out std_logic_vector(31 downto 0);
    busy   : out std_logic;

    -- LCD interface
    
    LCD_E  : out std_logic;
    LCD_RS : out std_logic;
    LCD_RW : out std_logic;
    LCD_D  : inout std_logic_vector(7 downto 0)
  );
end alzpu_lcd;

architecture behave of alzpu_lcd is

  type lcd_state_type is (
    STATE_INIT,
    STATE_IDLE,
    STATE_WRITE_REG,
    STATE_READ_REG,
    STATE_CHECK_BUSY,
    STATE_SETUP_DATA,
    STATE_HOLD_HIGH,
    STATE_HOLD_LOW,
    STATE_FINISH,
    STATE_NOP
  );

  -- Configuration registers
  signal lcd_config_fourbitmode : boolean;

  -- LCD controller state
  signal state: lcd_state_type;


  signal lcd_w_data : std_logic_vector(7 downto 0);
  signal lcd_r_data : std_logic_vector(7 downto 0);

  signal lcd_w_rs   : std_logic;

  signal lcd_write  : std_logic;

  signal setup_dly  : integer;
  signal setup_dly_load : boolean; -- Load setup delay

  signal hold_dly   : integer;
  signal hold_dly_load  : boolean; -- Load clk high delay

  signal low_dly    : integer;
  signal low_dly_load   : boolean; -- Load clk low delay
  
  signal write_high : boolean;  -- 4 bit mode - whether we're sending MSB or LSB

begin

  process (clk,rst)
  begin
    if clk'event and clk='1' then
      if rst='1' then
        state           <= STATE_INIT;
        LCD_RW          <= '1';
        LCD_E           <= '0';
        LCD_RS          <= '0';
        lcd_config_fourbitmode <= false;
        setup_dly_load  <= false;
        hold_dly_load   <= false;
        low_dly_load    <= false;
        write_high      <= false;
      else
        setup_dly_load  <= false;
        hold_dly_load   <= false;
        low_dly_load    <= false;

        case state is
          when STATE_INIT =>
            state <= STATE_IDLE;

          when STATE_IDLE =>
            if en='1' then
              lcd_write  <= we;

              case addr(4) is
                when '1' =>
                  -- Read/Write register
                  if we='1' then
                    lcd_config_fourbitmode <= dati(0)='1';
                  end if;
                  state <= STATE_NOP;
                  -- ack <= 1;
                  when '0' =>
                    state <= STATE_SETUP_DATA;

                    lcd_w_data <= dati(7 downto 0);
                     
                    LCD_RS <= dati(8);
                    write_high <= false;

                    if we='1' then
                      LCD_RW <= '0';
                      --ack <= 1;
                    end if;
                end case;
            end if;

          when STATE_NOP =>
            state <= STATE_IDLE;

          when STATE_SETUP_DATA=>
            begin
					LCD_E <= 0;
            	setup_dly_load <= 1;
            	state <= STATE_HOLD_HIGH;
            end
         STATE_HOLD_HIGH:
            if ( setup_dly==0 ) begin
               LCD_E <= 1;
               state <= STATE_HOLD_LOW;
               hold_dly_load <= 1;
            end

         STATE_HOLD_LOW:
            if ( hold_dly==0 ) begin
               LCD_E <= 0;
               if (!lcd_write) begin
               	
                  if ( lcd_config_fourbitmode ) begin

                     if (write_high) begin
                        
                     	lcd_r_data[3:0] = LCD_D[7:4];
								$display("%t: LCD finished read: %h", $time, lcd_r_data);
                        if ( lcd_config_intenabled )
                        	interrupt <= 1;
                        else
                        	ack <= 1;
                     end else begin
                        lcd_r_data[7:4] = LCD_D[7:4];
							end

                  end else begin

                  	lcd_r_data = LCD_D;
							if ( lcd_config_intenabled )
                     	interrupt <= 1;
                     else
                     	ack <= 1;
                  end
               end

               state <= STATE_FINISH;
               low_dly_load <= 1;
            end
         STATE_FINISH:
            begin
            if (low_dly==0) begin
               if ( lcd_config_fourbitmode && !write_high) begin
                  write_high <= 1;
                  state <= STATE_SETUP_DATA;
               end else begin
               	LCD_RW <= 1;
               	state <= STATE_IDLE;
	               //if ( !lcd_write )
						//	ack <= 1;
               end
            end
            end
      endcase
   end
end

genvar lcdbit;

generate
for ( lcdbit=0; lcdbit<4; lcdbit=lcdbit+1 )
begin: mylcdbittris
   assign LCD_D[lcdbit] = LCD_RW ? 1'bz : lcd_w_data[lcdbit];
end
endgenerate

// Upper 4 bits - muxed
generate
for ( lcdbit=4; lcdbit<8; lcdbit=lcdbit+1 )
begin: mylcdbittris2
   assign LCD_D[lcdbit] = LCD_RW ? 1'bz :
   	( lcd_config_fourbitmode ? ( write_high ? lcd_w_data[lcdbit-4] : lcd_w_data[lcdbit] )
      : lcd_w_data[lcdbit] );
end
endgenerate


//assign LCD_D = LCD_RW ? lcd_w_data;


always @(posedge clk)
begin
   if ( setup_dly_load )
      setup_dly <= LCD_SETUP_CLOCKS;
   else
      setup_dly <= setup_dly-1;
end

always @(posedge clk)
begin
   if ( hold_dly_load )
      hold_dly <= LCD_HOLD_CLOCKS;
   else
      hold_dly <= hold_dly-1;
end

always @(posedge clk)
begin
   if ( low_dly_load )
      low_dly <= LCD_NHOLD_CLOCKS;
   else
      low_dly <= low_dly-1;
end


always @(posedge clk)
begin
   if ( en ) begin
      dato <= lcd_r_data;
   end
end

endmodule
