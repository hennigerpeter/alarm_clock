library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
  port(
    btn : in  std_logic_vector(3 downto 0);
    sw : in  std_logic_vector(0 downto 0);
    o_mins, o_secs, o_wmins : out integer range 0 to 59;
    o_hours, o_whours : out integer range 0 to 23;
    alarm : out std_logic;
    state : out std_logic_vector(1 downto 0);
    clk : in  std_logic;
    reset : in  std_logic
  );
end controller;

architecture Behavioral of controller is

  component trigger_gen is
    generic(Delta : integer);
    port(
      clk   : in std_logic;
      reset : in std_logic;
      trigger : out std_logic
    );
  end component trigger_gen;

  -- pro Viertelsekunde einen Takt lang '1'
  signal fasttrigger : std_logic;
  -- fasttrigger wird zurueckgesetzt, wenn BTN2 oder BTN3 gedrueckt werden
  signal fasttimer_reset : std_logic;
  -- pro Sekunde einen Takt lang '1'
  signal sectrigger : std_logic;

  signal hours, whours     : integer range 0 to 23;
  signal secs, mins, wmins : integer range 0 to 59;

  -- fuer Flankenerkennung der Taster
  signal btn_old : std_logic_vector(3 downto 0);
  signal btn_triggered : std_logic_vector(3 downto 0);

  type state_type is (NTIME, SET_TIME, SET_ALARM, error);
  signal current_state : state_type;

begin
  fasttimer_reset <= reset or
        btn_triggered(2) or btn_triggered(3);

  fasttimer : trigger_gen
    generic map(11)
    port map(clk, fasttimer_reset, fasttrigger);

  sectimer : trigger_gen
    generic map(13)
    port map(clk, reset, sectrigger);

  trigger : process(clk, btn)
  begin
    for i in 0 to 3 loop
      btn_triggered(i) <= not btn_old(i) and btn(i);
    end loop;
  end process;

  FSM : process(clk, reset)
    variable next_state : state_type;
  begin
    if reset = '1' then
      hours  <= 0;
      mins   <= 0;
      secs   <= 0;
      whours <= 0;
      wmins  <= 0;
      alarm  <= '0';
      current_state <= NTIME;
    elsif clk'event and clk = '1' then
      for i in 0 to 3 loop
        btn_old(i) <= btn(i);
      end loop;

      -- Eine Sekunde hochzählen
      secs <= (secs + 1) mod 60;
      -- Wenn Sekunden > 60 + 1 Minute. 
      IF secs = 0 THEN
        mins <= (mins + 1) mod 60;
        -- Wenn Minuten > 60 + 1 Stunde
        IF mins = 0 THEN
          hours <= (hours + 1) mod 24;
        END IF;
      END IF;
      
      -- Alarm ausgeben
      IF  (mins = wmins) AND (hours = whours) THEN
          alarm <= '1';
      ELSE
         -- Alarm deaktivieren
         alarm <= '0';
      END IF;
      
      case current_state is
        -- Zustand Time
        when NTIME =>
          -- BTN0' & !BTN1'
          IF (btn_triggered(0)='1') AND (NOT btn_triggered(1)='1') THEN
             next_state := SET_TIME;
          -- !BTN0' & BTN1'
          ELSIF (NOT btn_triggered(0)='1') AND btn_triggered(1)='1' THEN
             next_state := SET_ALARM;
          END IF;

        -- Zustand SetTime
        when SET_TIME =>
          -- BTN0' & !BTN1'
          IF (btn_triggered(0)='1') AND (NOT btn_triggered(1)='1') THEN
               next_state := NTIME;
          END IF;
          
          -- Minuten nach oben zaehlen BTN2
          IF (btn_triggered(2)='1') THEN
            mins <= (mins + 1) mod 60;
          END IF;
          
          -- Stunden nach oben zaehlen BTN3
          IF (btn_triggered(3)='1') THEN
            hours <= (hours + 1) mod 24;
          END IF;
        
        -- Zustand SetAlarm
        when SET_ALARM =>
          -- BTN1' & !BTN0'
          IF (btn_triggered(1)='1') AND (NOT btn_triggered(0)='1') THEN
          END IF;

          -- Minuten nach oben zaehlen BTN2
          IF (btn_triggered(2)='1') THEN
            wmins <= (wmins + 1) mod 60;
          END IF;

          -- Stunden nach oben zaehlen BTN3
          IF (btn_triggered(3)='1') THEN
            whours <= (whours + 1) mod 24;
          END IF;
        
          -- Illegale Zustaende
        when others =>
          next_state := NTIME;
      end case;

      current_state <= next_state;
    end if;
  end process FSM;

  o_hours  <= hours;
  o_mins   <= mins;
  o_secs   <= secs;
  o_whours <= whours;
  o_wmins  <= wmins;

  with current_state select
    state <= "00" when NTIME,
             "01" when SET_TIME,
             "10" when SET_ALARM,
             "11" when others;
end architecture Behavioral;
