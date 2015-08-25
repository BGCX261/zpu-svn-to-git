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

entity alzpu_lcdctrl is
  generic (
    lcd_setup_clocks: positive := 10;
    lcd_hold_clocks:  positive := 45;
    lcd_nhold_clocks: positive := 10
  );
  port (
    clk   : in std_logic;
    rst   : in std_logic;
    addr  : in std_logic_vector(4 downto 0);
    dati  : in std_logic_vector(31 downto 0);
    rd_en : in std_logic;
    wr_en : in std_logic;
    dato  : out std_logic_vector(31 downto 0);
    busy  : out std_logic;

    LCD_E : out std_logic;
    LCD_RS: out std_logic;
    LCD_RW: out std_logic;
    LCD_D : inout std_logic_vector(7 downto 0)
);
end alzpu_lcdctrl;


architecture behave of alzpu_lcdctrl is

type state_type is (
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

-- Configuration register
signal lcd_config_fourbitmode: std_logic;
--signal lcd_config_intenabled: std_logic;
signal lcd_config_busycheck: std_logic;
signal state: state_type;


signal lcd_w_data : std_logic_vector(7 downto 0);
signal lcd_r_data : std_logic_vector(7 downto 0);

signal lcd_w_rs   : std_logic;
signal lcd_w_rw   : std_logic;
signal lcd_write  : std_logic;

signal setup_dly  : positive range 0 to lcd_setup_clocks;
signal setup_dly_load : std_logic;
signal hold_dly   : positive range 0 to lcd_hold_clocks;
signal hold_dly_load : std_logic;
signal low_dly    : positive range 0 to lcd_nhold_clocks;
signal low_dly_load : std_logic;

signal write_high: std_logic;
signal busy_int : std_logic;

subtype lbv3 is std_logic_vector(2 downto 0);

begin

busy <= wr_en or rd_en or busy_int;

process(clk,rst)
  variable en: std_logic;
begin

  en := wr_en or rd_en;

  if clk'event and clk='1' then

    setup_dly_load <= '0';
    hold_dly_load <= '0';
    low_dly_load <= '0';


    if rst='1' then 
      state <= STATE_INIT;
      lcd_w_rw <= '1';
      LCD_E <= '0';
      LCD_RS <= '0';
      lcd_config_fourbitmode <= '0';
      --lcd_config_intenabled <= 0;
      lcd_config_busycheck <= '0';
      --interrupt <= 0;
      write_high <= '0';
      busy_int <= '0';
    else
      case (state) is
        when STATE_INIT =>
          state <= STATE_IDLE;
        when STATE_IDLE =>
          if en = '1' then
            lcd_write <= wr_en;
            case addr(4) is
              when '1' =>
                --  Read/Write register
                if wr_en = '1' then
                  lcd_config_fourbitmode <= dati(0);
                  lcd_config_busycheck <= dati(2);
                end if;

                state <= STATE_NOP;
                     
              when '0' =>
                -- LCD access
                state <= STATE_SETUP_DATA;

                lcd_w_data <= dati(7 downto 0);
                LCD_RS <= dati(8);
                write_high <= '0';

                if wr_en = '1' then
                  lcd_w_rw <= '0';
                  busy_int <= '0';
                end if;

            end case;
          end if;
        when STATE_NOP =>
          state <= STATE_IDLE;

        when STATE_SETUP_DATA =>
					LCD_E <= '0';
          setup_dly_load <= '1';
          state <= STATE_HOLD_HIGH;

        when STATE_HOLD_HIGH=>
          if setup_dly = 0 then
            LCD_E <= '1';
            state <= STATE_HOLD_LOW;
            hold_dly_load <= '1';
          end if;

        when STATE_HOLD_LOW =>
          if hold_dly=0 then
            LCD_E <= '0';
            if lcd_write='0' then
               	
              if lcd_config_fourbitmode = '1' then
                if write_high = '1' then
                  lcd_r_data(3 downto 0) <= LCD_D(7 downto 4);
                  busy_int <= '0';
                else
                  lcd_r_data(7 downto 4) <= LCD_D(7 downto 4);
                end if;
              else
                lcd_r_data <= LCD_D;
                busy_int <= '0';
              end if;
            end if;

            state <= STATE_FINISH;
            low_dly_load <= '1';
          end if;

        when STATE_FINISH =>
          if low_dly=0 then
            if lcd_config_fourbitmode='1' and write_high='0' then
              write_high <= '1';
              state <= STATE_SETUP_DATA;
            else
              lcd_w_rw <= '1';
              state <= STATE_IDLE;
            end if;
          end if;
      end case;
    end if;
  end if;
end process;

lcdbitgenlow: for lcdbit in 0 to 3 generate
   LCD_D(lcdbit) <= 'Z' when lcd_w_rw='1' else lcd_w_data(lcdbit);
end generate lcdbitgenlow;

LCD_RW <= lcd_w_rw;


-- Upper 4 bits - muxed
lcdbitgenhigh: for lcdbit in 4 to 7 generate
  process ( lcd_w_rw, lcd_config_fourbitmode, write_high)
  begin
    case lbv3'(lcd_w_rw, lcd_config_fourbitmode, write_high) is
      when "1XX" =>
        LCD_D(lcdbit) <= 'Z';
      when "00X" =>
        LCD_D(lcdbit) <= lcd_w_data(lcdbit);
      when "010" =>
        LCD_D(lcdbit) <= lcd_w_data(lcdbit);
      when "011" =>
        LCD_D(lcdbit) <= lcd_w_data(lcdbit - 4);
    end case;
  end process;
end generate lcdbitgenhigh;

process(clk,setup_dly_load)
begin
  if clk'event and clk='1' then
    if setup_dly_load='1' then
      setup_dly <= LCD_SETUP_CLOCKS;
    else
      setup_dly <= setup_dly-1;
    end if;
  end if;
end process;

process(clk,hold_dly_load)
begin
  if clk'event and clk='1' then
    if hold_dly_load='1' then
      hold_dly <= LCD_HOLD_CLOCKS;
    else
      hold_dly <= hold_dly-1;
    end if;
  end if;
end process;

process(clk,low_dly_load)
begin
  if clk'event and clk='1' then
    if low_dly_load='1' then
      low_dly <= LCD_NHOLD_CLOCKS;
    else
      low_dly <= low_dly-1;
    end if;
  end if;
end process;

dato <= lcd_r_data;

end behave;

