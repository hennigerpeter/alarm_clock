-- vim: set syntax=vhdl ts=8 sts=2 sw=2 et:

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_controller IS
END tb_controller;

ARCHITECTURE behavior OF tb_controller IS

  COMPONENT controller IS PORT (
    btn                     : IN  std_logic_vector(3 DOWNTO 0);
    sw                      : IN  std_logic_vector(0 DOWNTO 0);
    o_mins, o_secs, o_wmins : OUT integer RANGE 0 TO 59;
    o_hours, o_whours       : OUT integer RANGE 0 TO 23;
    alarm                   : OUT std_logic;
    clk                     : IN  std_logic;
    reset                   : IN  std_logic );
  END COMPONENT;

  SIGNAL tb_clk:     STD_LOGIC := '0';
  SIGNAL tb_BTN:     STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
  SIGNAL tb_SW:      STD_LOGIC_VECTOR(0 DOWNTO 0) := "0";
  SIGNAL tb_ring:    STD_LOGIC;
  SIGNAL tb_reset:   STD_LOGIC;
  SIGNAL tb_secs:    integer RANGE 0 to 59;
  SIGNAL tb_mins:    integer RANGE 0 to 59;
  SIGNAL tb_hours:   integer RANGE 0 to 23;
  SIGNAL tb_wmins:   integer RANGE 0 to 59;
  SIGNAL tb_whours:  integer RANGE 0 to 23;

BEGIN

  -- Generiere Wecker-Takt 2^13Hz = 8192Hz
  tb_clk <= NOT tb_clk after 61035 ns;

  -- Generiere Reset
  tb_reset <= '1', '0' after 250 us;

  -- Stellen der Uhrzeit:
  tb_BTN(0) <= '1' after 10 sec, '0' after 27 sec;  -- set time
  tb_BTN(1) <= '1' after 28 sec, '0' after 38 sec;  -- set alarm
  tb_BTN(2) <= '1' after 11 sec, '0' after 22250 ms, '1' after 29 sec, '0' after 32750 ms;  -- set Minutes
  tb_BTN(3) <= '1' after 23 sec, '0' after 26 sec, '1' after 34 sec, '0' after 37250 ms;  -- set Houres
  tb_SW(0)  <= '1' after 40 sec;  --activate alarm clock

TB : PROCESS 
BEGIN
  WAIT FOR 1 sec;
  IF (tb_ring = '1') THEN
    WAIT FOR 1 sec;
    ASSERT FALSE REPORT "Simulation completed." SEVERITY FAILURE;
  END IF;
END PROCESS;

  -- Instantiierung des Weckers IN der Testbench
  DeviceUnderTest:controller
    PORT MAP(
      clk       => tb_clk,
      btn       => tb_BTN,
      sw        => tb_SW,
      o_mins    => tb_mins,
      o_secs    => tb_secs,
      o_wmins   => tb_wmins,
      o_hours   => tb_hours,
      o_whours  => tb_whours,
      alarm     => tb_ring,
      reset     => tb_reset );

END ARCHITECTURE;
