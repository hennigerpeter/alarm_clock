LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.all;

ENTITY int2ascii IS
    Port ( i_number : IN  integer RANGE 0 TO 59;
           o_ascii0   : OUT std_logic_vector(7 downto 0);
           o_ascii1   : OUT std_logic_vector(7 downto 0)
           );
END ENTITY int2ascii;

ARCHITECTURE behavioral OF int2ascii IS
    SIGNAL s_bcd0 : unsigned(3 DOWNTO 0);
    SIGNAL s_bcd1 : unsigned(3 DOWNTO 0);
BEGIN
    PROCESS (i_number)
        VARIABLE v_bcd0   : unsigned(3 DOWNTO 0);
        VARIABLE v_bcd1   : unsigned(3 DOWNTO 0);
        VARIABLE v_number : unsigned(7 DOWNTO 0);
    BEGIN
        v_bcd0 := "0000";
        v_bcd1 := "0000";
        v_number := to_unsigned(i_number, v_number'length);

        -- Nur einen Durchlauf machen, da v_bcd0 und v_bcd1 nicht per Loop durchlaufen werden können
        FOR i IN 0 TO 1 LOOP
            --TODO: Pseudocode umsetzen

            -- Zahl größer 4, addiere 3
            if(v_bcd0>"100") then
                v_bcd0 := v_bcd0 + 3;
            end if;
            
            -- Zahl größer 4, addiere 3
            if(v_bcd0>"100") then 
                v_bcd0 := v_bcd0 + 3;
            end if;

            -- Left Shift um 1 Bit
            v_bcd1 := shift_left(v_bcd1,1);
            v_bcd1(0) := v_bcd0(3);

            -- Left Shift um 1 Bit
            v_bcd0 := shift_left(v_bcd0,1);
            v_bcd0(0) := v_number(2-i);

        END LOOP;
        s_bcd0 <= v_bcd0;
        s_bcd1 <= v_bcd1;
    END PROCESS;
    o_ascii0(3 DOWNTO 0) <= std_logic_vector(s_bcd0);
    o_ascii0(7 DOWNTO 0) <= "0011"; -- ASCII Ziffern 0-9 entsprechen den Zahlen 30-39, es wird demnach eine 3 in der linken BCD vorangestellt
    o_ascii1 <= std_logic_vector(s_bcd1);
    o_ascii1(7 DOWNTO 0) <= "0011"; -- ASCII Ziffern 0-9 entsprechen den Zahlen 30-39, es wird demnach eine 3 in der linken BCD vorangestellt
END ARCHITECTURE behavioral;
