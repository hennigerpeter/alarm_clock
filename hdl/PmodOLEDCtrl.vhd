----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
--
-- Create Date:    14:35:33 10/10/2011
-- Module Name:    PmodOLEDCtrl - Behavioral
-- Project Name:   PmodOLED Demo
-- Tool versions:  ISE 13.2
-- Description:    Top level controller that controls the PmodOLED blocks
--
-- Revision: 1.1
-- Revision 0.01 - File Created
-- Revision 0.02 - Modified alightly to adapt to the Zynq board, Nov. 5, 2012
--                 By Farhad Abdolian (fabdolian@seemaconsulting.com)
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.std_logic_arith.ALL;

USE work.Common.all;

ENTITY PmodOLEDCtrl IS
    PORT (
        CLK         : IN  std_logic;
        RST         : IN  std_logic;


        CS          : OUT std_logic;
        OLED_SDIN   : OUT std_logic;
        OLED_SCLK   : OUT std_logic;
        OLED_DC     : OUT std_logic;
        OLED_RES    : OUT std_logic;
        OLED_VBAT   : OUT std_logic;
        OLED_VDD    : OUT std_logic;

        i_blink     : IN  std_logic;
        i_oled_mem  : IN  OledMem
    );
END PmodOLEDCtrl;

ARCHITECTURE Behavioral OF PmodOLEDCtrl IS

    COMPONENT OledInit IS
        PORT (  CLK  : IN  std_logic;
            RST  : IN  std_logic;
            EN  : IN  std_logic;
            CS   : OUT std_logic;
            SDO     : OUT std_logic;
            SCLK : OUT std_logic;
            DC  : OUT std_logic;
            RES     : OUT std_logic;
            VBAT : OUT std_logic;
            VDD     : OUT std_logic;
            FIN     : OUT std_logic);
    END COMPONENT;
    
    COMPONENT OledEx IS
        PORT (
            CLK         : IN  std_logic;
            RST         : IN  std_logic;
            EN          : IN  std_logic;
            CS          : OUT std_logic;
            SDO         : OUT std_logic;
            SCLK        : OUT std_logic;
            DC          : OUT std_logic;
            FIN         : OUT std_logic;
            i_blink     : IN  std_logic;
            i_oled_mem  : IN  OledMem
        );
    END COMPONENT;
    
    TYPE states IS (Idle,
        OledInitialize,
        OledExample,
        Done);
    
    SIGNAL current_state  : states := Idle;
    
    SIGNAL init_en    : std_logic := '0';
    SIGNAL init_done  : std_logic;
    SIGNAL init_cs    : std_logic;
    SIGNAL init_sdo   : std_logic;
    SIGNAL init_sclk  : std_logic;
    SIGNAL init_dc    : std_logic;
    
    SIGNAL example_en   : std_logic := '0';
    SIGNAL example_cs   : std_logic;
    SIGNAL example_sdo  : std_logic;
    SIGNAL example_sclk : std_logic;
    SIGNAL example_dc   : std_logic;
    SIGNAL example_done : std_logic;

-- Since we do not have a CS on the Synq board, we have to have this temp signal to make
-- it work with minimum amout of modification of the desgin. /Farhad Abdolian Nov. 5, 2012
--SIGNAL CS    : std_logic;

BEGIN

    Init: OledInit
        PORT MAP(
            CLK => CLK,
            RST => RST,
            EN => init_en,
            CS => init_cs,
            SDO => init_sdo,
            SCLK => init_sclk,
            DC => init_dc,
            RES => OLED_RES,
            VBAT => OLED_VBAT,
            VDD => OLED_VDD,
            FIN => init_done);
    Example: OledEx
        PORT MAP(
            CLK => CLK,
            RST => RST,
            EN => example_en,
            CS => example_cs,
            SDO => example_sdo,
            SCLK => example_sclk,
            DC => example_dc,
            FIN => example_done,
            i_blink => i_blink,
            i_oled_mem => i_oled_mem);

    --MUXes to indicate which outputs are routed out depending on which block is enabled
    CS        <= init_cs WHEN (current_state = OledInitialize) ELSE
                 example_cs;
    OLED_SDIN <= init_sdo WHEN (current_state = OledInitialize) ELSE
                 example_sdo;
    OLED_SCLK <= init_sclk WHEN (current_state = OledInitialize) ELSE
                 example_sclk;
    OLED_DC   <= init_dc WHEN (current_state = OledInitialize) ELSE
                 example_dc;
    --END output MUXes

    --MUXes that enable blocks when in the proper states
    init_en    <= '1' WHEN (current_state = OledInitialize) ELSE
                  '0';
    example_en <= '1' WHEN (current_state = OledExample) ELSE
                  '0';
    --END enable MUXes

    PROCESS(CLK)
    BEGIN
        IF(rising_edge(CLK)) THEN
            IF(RST = '1') THEN
                current_state <= Idle;
            ELSE
                CASE(current_state) IS
                    WHEN Idle =>
                        current_state <= OledInitialize;
                    --Go through the initialization sequence
                    WHEN OledInitialize =>
                        IF(init_done = '1') THEN
                            current_state <= OledExample;
                        END IF;
                    --Do example and Do nothing when finished
                    WHEN OledExample =>
                        IF(example_done = '1') THEN
                            current_state <= Done;
                        END IF;
                    --Do Nothing
                    WHEN Done =>
                        current_state <= Done;
                    WHEN others =>
                        current_state <= Idle;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE Behavioral;