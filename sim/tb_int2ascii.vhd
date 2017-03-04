LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.all;

ENTITY tb_int2ascii IS
END ENTITY tb_int2ascii;

ARCHITECTURE behavior OF tb_int2ascii IS

  COMPONENT int2ascii IS PORT (
    i_number   : IN  integer RANGE 0 TO 59;
    o_ascii0   : OUT std_logic_vector(7 downto 0);
    o_ascii1   : OUT std_logic_vector(7 downto 0));
  END COMPONENT;

  SIGNAL s_ascii0, s_ascii1 : std_logic_vector(7 downto 0);
  SIGNAL s_number           : integer RANGE 0 TO 59;

BEGIN
  dut : int2ascii PORT MAP(s_number, s_ascii0, s_ascii1);

-- *** Test Bench - User Defined Section ***
tb : PROCESS
  VARIABLE v_ascii0, v_ascii1 : unsigned(7 downto 0) := to_unsigned(48, 8);
BEGIN
  s_number <= 0; 
  FOR i IN 0 TO 59 LOOP
    WAIT FOR 5 ns;
    s_number <= i;
    WAIT FOR 5 ns;
    ASSERT v_ascii0 = unsigned(s_ascii0) REPORT "ASCII0 Failed!" SEVERITY WARNING;
    ASSERT v_ascii1 = unsigned(s_ascii1) REPORT "ASCII1 Failed!" SEVERITY WARNING;
    IF v_ascii0 = to_unsigned(57, v_ascii0'length) THEN
      v_ascii0 := to_unsigned(48, v_ascii0'length);
      v_ascii1 := v_ascii1 + to_unsigned(1, v_ascii1'length);
    ELSE
      v_ascii0 := v_ascii0 + to_unsigned(1, v_ascii0'length);
    END IF;
  END LOOP;

  WAIT FOR 10 ns;
  ASSERT FALSE REPORT "Simulation completed." SEVERITY FAILURE;
END PROCESS;
-- *** End Test Bench - User Defined Section ***
END;
