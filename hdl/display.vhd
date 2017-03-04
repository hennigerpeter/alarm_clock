----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 04/23/2015 04:42:12 PM
-- Design Name:
-- Module Name: display - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.numeric_std.ALL;
USE work.common.ALL;


ENTITY display IS
    PORT(
        i_mins, i_secs, i_wmins : IN  integer RANGE 0 TO 59;
        i_hours, i_whours       : IN  integer RANGE 0 TO 23;
        state                   : IN  std_logic_vector(1 downto 0);
        alarm                   : IN  std_logic;
        alarm_s                 : IN  std_logic;
        sw_err                  : IN  std_logic;

        CS                      : OUT std_logic;
        OLED_SDIN               : OUT std_logic;
        OLED_SCLK               : OUT std_logic;
        OLED_DC                 : OUT std_logic;
        OLED_RES                : OUT std_logic;
        OLED_VBAT               : OUT std_logic;
        OLED_VDD                : OUT std_logic;

        dclk                    : IN  std_logic;
        rst                     : IN  std_logic);
END ENTITY display;

ARCHITECTURE behavioral OF display IS

    COMPONENT PmodOLEDCtrl IS
        PORT (
            clk      : IN  std_logic;
            rst      : IN std_logic;


            CS          : OUT std_logic;
            OLED_SDIN : OUT std_logic;
            OLED_SCLK : OUT std_logic;
            OLED_DC  : OUT std_logic;
            OLED_RES : OUT std_logic;
            OLED_VBAT : OUT std_logic;
            OLED_VDD : OUT std_logic;
            -- Alarm Clock Sate
            i_blink     : IN  std_logic;
            i_oled_mem  : IN  OledMem
        );
    END COMPONENT PmodOLEDCtrl;

    COMPONENT int2bcd IS
        PORT ( i_number : IN  integer RANGE 0 TO 59;
               o_bcd0   : OUT integer RANGE 0 TO 9;
               o_bcd1   : OUT integer RANGE 0 TO 9);
    END COMPONENT int2bcd;

    COMPONENT int2ascii IS
        Port ( i_number   : IN  integer RANGE 0 TO 59;
               o_ascii0   : OUT std_logic_vector(7 downto 0);
               o_ascii1   : OUT std_logic_vector(7 downto 0));
    END COMPONENT int2ascii;

    COMPONENT trigger_gen IS
        GENERIC (Delta : integer);
        PORT    (clk     : IN  std_logic;
                 reset   : IN  std_logic;
                 trigger : OUT std_logic);
    END COMPONENT trigger_gen;

    -- Time:  00:00:00
    -- Alarm: 00:00 ON --OFF
    -- WAKE UP!!
    -- (O)_(O)   -.-zZz
    SIGNAL clock_screen : OledMem:= ((X"54",X"69",X"6D",X"65",X"20",X"20",X"3A",X"30",X"30",X"3A",X"30",X"30",X"3A",X"30",X"30",X"20"),
                                     (X"41",X"6C",X"61",X"72",X"6D",X"20",X"3A",X"30",X"30",X"3A",X"30",X"30",X"20",X"5A",X"20",X"20"),
                                     (X"57",X"41",X"4B",X"45",X"20",X"55",X"50",X"21",X"21",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                     (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                     --(X"28",X"4F",X"29",X"5F",X"28",X"4F",X"29",X"20",X"20",X"20",X"2D",X"2E",X"2D",X"7A",X"5A",X"7A"));

    SIGNAL hours1, hours0, mins1, mins0, secs1, secs0, whours1, whours0, wmins1, wmins0 : integer RANGE 0 TO 9;

    SIGNAL init_rst : std_logic := '0';
    SIGNAL trigger  : std_logic;

begin

    trig : trigger_gen
    GENERIC MAP(20)
    PORT MAP(dclk, rst, trigger);

    inital_reset: PROCESS(trigger)
        VARIABLE v_stop : std_logic := '0';
    BEGIN
        IF  rising_edge(trigger) THEN
            init_rst <= '0';
            IF (v_stop = '0') THEN
                v_stop := '1';
                init_rst <= '1';
            END IF;
        END IF;
    END PROCESS;

    oled: PmodOLEDCtrl
        PORT MAP( dclk, init_rst or rst, cs, oled_sdin, oled_sclk, oled_dc, oled_res, oled_vbat, oled_vdd, alarm, clock_screen);

--  c_hours:  int2bcd PORT MAP(i_hours, hours0, hours1);
--  c_mins:   int2bcd PORT MAP(i_mins, mins0, mins1);
--  c_secs:   int2bcd PORT MAP(i_secs, secs0, secs1);
--  c_whours: int2bcd PORT MAP(i_whours, whours0, whours1);
--  c_wmins:  int2bcd PORT MAP(i_wmins, wmins0, wmins1);

    c_hours  : int2ascii PORT MAP(i_hours,  clock_screen(0,8),  clock_screen(0,7));
    c_mins   : int2ascii PORT MAP(i_mins,   clock_screen(0,11), clock_screen(0,10));
    c_secs   : int2ascii PORT MAP(i_secs,   clock_screen(0,14), clock_screen(0,13));
    c_whours : int2ascii PORT MAP(i_whours, clock_screen(1,8),  clock_screen(1,7));
    c_wmins  : int2ascii PORT MAP(i_wmins,  clock_screen(1,11), clock_screen(1,10));

    -- Write Time and Alarm on Screen
--  clock_screen(0,7)  <= std_logic_vector(to_unsigned(hours1 +48, 8));
--  clock_screen(0,8)  <= std_logic_vector(to_unsigned(hours0 +48, 8));
--  clock_screen(0,10) <= std_logic_vector(to_unsigned(mins1  +48, 8));
--  clock_screen(0,11) <= std_logic_vector(to_unsigned(mins0  +48, 8));
--  clock_screen(0,13) <= std_logic_vector(to_unsigned(secs1  +48, 8));
--  clock_screen(0,14) <= std_logic_vector(to_unsigned(secs0  +48, 8));
--  clock_screen(1,7)  <= std_logic_vector(to_unsigned(whours1+48, 8));
--  clock_screen(1,8)  <= std_logic_vector(to_unsigned(whours0+48, 8));
--  clock_screen(1,10) <= std_logic_vector(to_unsigned(wmins1 +48, 8));
--  clock_screen(1,11) <= std_logic_vector(to_unsigned(wmins0 +48, 8));

    -- Alarm ON/OFF
    clock_screen(1,13) <= X"4F" WHEN alarm_s = '0' ELSE
                          X"4F" WHEN alarm_s = '1' ELSE
                          X"45";
    clock_screen(1,14) <= X"46" WHEN alarm_s = '0' ELSE
                          X"4E" WHEN alarm_s = '1' ELSE
                          X"52";
    clock_screen(1,15) <= X"46" WHEN alarm_s = '0' ELSE
                          X"20" WHEN alarm_s = '1' ELSE
                          X"52";


    -- WAKE UP!!!
    clock_screen(2,0) <=  X"57" WHEN alarm   = '1' ELSE
                          X"20";
    clock_screen(2,1) <=  X"41" WHEN alarm   = '1' ELSE
                          X"20";
    clock_screen(2,2) <=  X"4B" WHEN alarm   = '1' ELSE
                          X"20";
    clock_screen(2,3) <=  X"45" WHEN alarm   = '1' ELSE
                          X"20";
    clock_screen(2,5) <=  X"55" WHEN alarm   = '1' ELSE
                          X"20";
    clock_screen(2,6) <=  X"50" WHEN alarm   = '1' ELSE
                          X"20";
    clock_screen(2,7) <=  X"21" WHEN alarm   = '1' ELSE
                          X"20";
    clock_screen(2,8) <=  X"21" WHEN alarm   = '1' ELSE
                          X"20";


    -- state output
    clock_screen(3,0) <=  X"4E" WHEN state = "00" ELSE
                          X"53" WHEN state = "01" ELSE
                          X"53" WHEN state = "10" ELSE
                          X"49";

    clock_screen(3,1) <=  X"54" WHEN state = "00" ELSE
                          X"54" WHEN state = "01" ELSE
                          X"41" WHEN state = "10" ELSE
                          X"4E";

    clock_screen(3,2) <=  X"49" WHEN state = "00" ELSE
                          X"49" WHEN state = "01" ELSE
                          X"4C" WHEN state = "10" ELSE
                          X"56";

    clock_screen(3,3) <=  X"4D" WHEN state = "00" ELSE
                          X"4D" WHEN state = "01" ELSE
                          X"41" WHEN state = "10" ELSE
                          X"20";

    clock_screen(3,4) <=  X"45" WHEN state = "00" ELSE
                          X"45" WHEN state = "01" ELSE
                          X"52" WHEN state = "10" ELSE
                          X"20";

    clock_screen(3,5) <=  X"20" WHEN state = "00" ELSE
                          X"20" WHEN state = "01" ELSE
                          X"4D" WHEN state = "10" ELSE
                          X"20";

    -- Smileys
    -- (_8(|)
    --(O)_(O)
    -- -.-zZz
    -- 3:D
    clock_screen(3,9) <=  X"53" WHEN sw_err = '1' ELSE
                          X"20" WHEN alarm_s = '0' ELSE
                          X"20" WHEN alarm   = '0' ELSE
                          X"28" WHEN alarm   = '1' ELSE
                          X"20";
    clock_screen(3,10) <= X"57" WHEN sw_err = '1' ELSE
                          X"28" WHEN alarm_s = '0' ELSE
                          X"2D" WHEN alarm   = '0' ELSE
                          X"4F" WHEN alarm   = '1' ELSE
                          X"20";
    clock_screen(3,11) <= X"5F" WHEN sw_err = '1' ELSE
                          X"5F" WHEN alarm_s = '0' ELSE
                          X"2E" WHEN alarm   = '0' ELSE
                          X"29" WHEN alarm   = '1' ELSE
                          X"28";
    clock_screen(3,12) <= X"45" WHEN sw_err = '1' ELSE
                          X"38" WHEN alarm_s = '0' ELSE
                          X"2D" WHEN alarm   = '0' ELSE
                          X"5F" WHEN alarm   = '1' ELSE
                          X"2E";
    clock_screen(3,13) <= X"52" WHEN sw_err = '1' ELSE
                          X"28" WHEN alarm_s = '0' ELSE
                          X"7A" WHEN alarm   = '0' ELSE
                          X"28" WHEN alarm   = '1' ELSE
                          X"59";
    clock_screen(3,14) <= X"52" WHEN sw_err = '1' ELSE
                          X"7C" WHEN alarm_s = '0' ELSE
                          X"5A" WHEN alarm   = '0' ELSE
                          X"4F" WHEN alarm   = '1' ELSE
                          X"2E";
    clock_screen(3,15) <= X"20" WHEN sw_err = '1' ELSE
                          X"29" WHEN alarm_s = '0' ELSE
                          X"7A" WHEN alarm   = '0' ELSE
                          X"29" WHEN alarm   = '1' ELSE
                          X"29";


    -- Software Error
--  clock_screen(3,0) <=  X"53" WHEN sw_err = '1' ELSE
--                        X"20";
--  clock_screen(3,1) <=  X"57" WHEN sw_err = '1' ELSE
--                        X"20";
--  clock_screen(3,2) <=  X"5F" WHEN sw_err = '1' ELSE
--                        X"20";
--  clock_screen(3,3) <=  X"45" WHEN sw_err = '1' ELSE
--                        X"20";
--  clock_screen(3,4) <=  X"52" WHEN sw_err = '1' ELSE
--                        X"20";
--  clock_screen(3,5) <=  X"52" WHEN sw_err = '1' ELSE
--                        X"20";
--  clock_screen(3,6) <=  X"51" WHEN sw_err = '1' ELSE
--                        X"20";
--  clock_screen(3,7) <=  X"52" WHEN sw_err = '1' ELSE
--                        X"20";
--  clock_screen(3,8) <=  X"21" WHEN sw_err = '1' ELSE
--                        X"20";

end ARCHITECTURE Behavioral;
