-- vim: set syntax=vhdl ts=8 sts=2 sw=2 et:

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY clock_div IS
    PORT(
        I : IN  std_logic;
        O : OUT std_logic);
END clock_div;

ARCHITECTURE Behavioral OF clock_div IS
    SIGNAL clkdiv : integer RANGE 0 TO 6102;
    SIGNAL clk    : std_logic := '0';

BEGIN
    PROCESS(I)
    BEGIN
        -- clock_div teilt die 125 MHz vom FPGA-Board auf 2^13 Hz runter
        IF I'event AND I = '1' THEN
            IF clkdiv = 0 THEN
                clkdiv <= 7628; --3051;
                clk    <= NOT clk;
            ELSE
                clkdiv <= clkdiv - 1;
            END IF;
        END IF;
    END PROCESS;

    O <= clk;

END Behavioral;