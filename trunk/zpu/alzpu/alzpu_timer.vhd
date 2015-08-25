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
use ieee.std_logic_arith.all;


library work;
use work.alzpu.all;
use work.alzpu_config.all;

entity alzpu_timer is
  port (
    slave_in:  in zpu_slave_in_type;
    slave_out: out zpu_slave_out_type;
    interrupt: out std_logic
  );
end alzpu_timer;

architecture behave of alzpu_timer is

  signal counter_q: unsigned(63 downto 0);

  -- Internal registers

  signal counter_init_val_q: std_logic_vector(63 downto 0);
  signal interrupt_enabled_q: std_logic;
  signal auto_restart_q: std_logic;
  signal do_restart_q: std_logic;
  signal timer_enabled_q: std_logic;
  signal counter_zero: std_logic;

begin

  slave_out.busy <= slave_in.rd_en;
  counter_zero <= '1' when counter_q=0 else '0';

  process( slave_in.clk, slave_in.rst )
  begin
    if slave_in.clk'event and slave_in.clk='1' then
      if slave_in.rst='1' then
        counter_init_val_q  <= (others=>'0');
        auto_restart_q      <= '0';
        interrupt_enabled_q <= '0';
        do_restart_q        <= '0';
        timer_enabled_q     <= '0';
      else
        do_restart_q        <= '0';



        if slave_in.rd_en='1' or slave_in.wr_en='1' then
          --
          if counter_q=0 and slave_in.wr_en='1' then
            interrupt_enabled_q <= '0';
            timer_enabled_q <= '0';
          end if;

          if slave_in.rd_en='1' then
            -- READ cycle
            case slave_in.addr(3 downto 2) is
              when "00" =>
                slave_out.dato  <= conv_std_logic_vector(counter_q(31 downto 0),32);
              when "01" =>
                slave_out.dato  <= conv_std_logic_vector(counter_q(63 downto 32),32);
              when "10" =>
                report "Reading timer registers";
                slave_out.dato  <= (others=>'0');
                slave_out.dato(3 downto 0)  <= counter_zero & do_restart_q & auto_restart_q & interrupt_enabled_q;
              when "11" =>
                slave_out.dato  <= (others=>'0');
              when others =>
            end case;
          else
            -- Write cycle
            case slave_in.addr(3 downto 2) is
              when "00" =>
                counter_init_val_q(31 downto 0) <= slave_in.dati;
                do_restart_q <= '1';
              when "01" =>
                counter_init_val_q(63 downto 32) <= slave_in.dati;
                do_restart_q <= '1';
              when "10" =>
                report "Writing timer registers";
                timer_enabled_q     <= slave_in.dati(31);
                do_restart_q        <= slave_in.dati(2);
                auto_restart_q      <= slave_in.dati(1);
                interrupt_enabled_q <= slave_in.dati(0);
              when others =>
            end case;
          end if;
        end if;
      end if;
    end if;
  end process;

  process( slave_in.clk, slave_in.rst )
  begin
    if slave_in.clk'event and slave_in.clk='1' then
      if slave_in.rst='1' then
        counter_q <= (others=>'0');
        interrupt <= '0';
      else
        if timer_enabled_q='1' then
          if counter_q=0 and do_restart_q='0' then
            interrupt <= interrupt_enabled_q;
          end if;

        if do_restart_q='1' then
          interrupt <= '0';
        end if;

        if do_restart_q='1' or (counter_q=0 and auto_restart_q='1') then
          counter_q <= unsigned(counter_init_val_q);
        else
          if counter_q /= 0 then
            counter_q <= counter_q - 1;
          end if;
        end if;
        end if;

      end if;
    end if;
  end process;

end behave;






