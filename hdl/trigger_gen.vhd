LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY trigger_gen IS
    GENERIC (Delta   : integer := 13);
    PORT    (clk     : IN std_logic;
             reset   : IN std_logic;
             trigger : OUT std_logic
    );
END ENTITY trigger_gen;

ARCHITECTURE behavioral OF trigger_gen IS
    SIGNAL timer                : unsigned(Delta DOWNTO 0);
BEGIN
    sectimer : PROCESS(clk, reset)
        VARIABLE timer_msb_to_zero : unsigned(timer'RANGE);
    BEGIN
        IF reset = '1' THEN
            timer <= (others => '0');
        ELSIF clk'event and clk = '1' THEN
            timer_msb_to_zero                   := timer;
            -- set msb TO zero, the msb will be our overflow bit
            timer_msb_to_zero(timer'length - 1) := '0';
            timer                               <= timer_msb_to_zero + 1;
        END IF;
    END PROCESS sectimer;

    trigger <= timer(timer'length - 1);

END ARCHITECTURE behavioral;