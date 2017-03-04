----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
--
-- Create Date:    16:05:03 10/10/2011
-- Module Name:    OledInit - Behavioral
-- Project Name:   PmodOLED Demo
-- Tool versions:  ISE 13.2
-- Description:    Runs the initialization sequence for the PmodOLED
--
-- Revision: 1.2
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY OledInit IS
    PORT (
        CLK   : IN  std_logic;  --System Clock
        RST   : IN  std_logic;  --Global Synchronous Reset
        EN    : IN  std_logic;  --Block enable pin
        CS    : OUT std_logic;  --SPI Chip Select
        SDO   : OUT std_logic;  --SPI data out
        SCLK  : OUT std_logic;  --SPI Clock
        DC    : OUT std_logic;  --Data/Command Pin
        RES   : OUT std_logic;  --PmodOLED RES
        VBAT  : OUT std_logic;  --VBAT enable
        VDD   : OUT std_logic;  --VDD enable
        FIN   : OUT std_logic);  --OledInit Finish Flag
END OledInit;

ARCHITECTURE Behavioral OF OledInit IS

    COMPONENT SpiCtrl
        PORT(
             CLK        : IN   std_logic;
             RST        : IN   std_logic;
             SPI_EN     : IN   std_logic;
             SPI_DATA   : IN   std_logic_vector(7 DOWNTO 0);
             CS         : OUT  std_logic;
             SDO        : OUT  std_logic;
             SCLK       : OUT  std_logic;
             SPI_FIN    : OUT  std_logic
            );
        END COMPONENT;

    COMPONENT Delay
        PORT(
             CLK        : IN   std_logic;
             RST        : IN   std_logic;
             DELAY_MS   : IN   std_logic_vector(11 DOWNTO 0);
             DELAY_EN   : IN   std_logic;
             DELAY_FIN  : OUT  std_logic
            );
        END COMPONENT;

    TYPE states IS (Transition1,
         Transition2,
         Transition3,
         Transition4,
         Transition5,
         Idle,
         VddOn,
         Wait1,
         DispOff,
         ResetOn,
         Wait2,
         ResetOff,

         SetClock1,
         SetClock2,
         SetMux1,
         SetMux2,
         SetOffset1,
         SetOffset2,
         SetLine,

         ChargePump1,
         ChargePump2,
         --InvertDisp1,...ComConfig2
         --DispContrast1/2
         PreCharge1,
         PreCharge2,
         VbatOn,
         Wait3,
         DispContrast1,
         DispContrast2,
         InvertDisp1,
         InvertDisp2,
         ComConfig1,
         ComConfig2,

         SetEntireOn,
         SetNormalInvDisp,


         DispOn,
         FullDisp,
         Done
         );

    SIGNAL current_state : states := Idle;
    SIGNAL after_state : states := Idle;

    SIGNAL temp_dc : std_logic := '0';
    SIGNAL temp_res : std_logic := '1';
    SIGNAL temp_vbat : std_logic := '1';
    SIGNAL temp_vdd : std_logic := '1';
    SIGNAL temp_fin : std_logic := '0';

    SIGNAL temp_delay_ms : std_logic_vector (11 DOWNTO 0) := (others => '0');
    SIGNAL temp_delay_en : std_logic := '0';
    SIGNAL temp_delay_fin : std_logic;
    SIGNAL temp_spi_en : std_logic := '0';
    SIGNAL temp_spi_data : std_logic_vector (7 DOWNTO 0) := (others => '0');
    SIGNAL temp_spi_fin : std_logic;

BEGIN

    SPI_COMP: SpiCtrl PORT MAP (
          CLK => CLK,
          RST => RST,
          SPI_EN => temp_spi_en,
          SPI_DATA => temp_spi_data,
          CS => CS,
          SDO => SDO,
          SCLK => SCLK,
          SPI_FIN => temp_spi_fin
        );

    DELAY_COMP: Delay PORT MAP (
          CLK => CLK,
          RST => RST,
          DELAY_MS => temp_delay_ms,
          DELAY_EN => temp_delay_en,
          DELAY_FIN => temp_delay_fin
        );

    DC   <= temp_dc;
    RES  <= temp_res;
    VBAT <= temp_vbat;
    VDD  <= temp_vdd;
    FIN  <= temp_fin;

    --Delay 100 ms after VbatOn
    temp_delay_ms <= "000001100100" WHEN (after_state = DispContrast1) ELSE --100 ms
         "000000000001"; --1ms

    STATE_MACHINE : PROCESS (CLK)
    BEGIN
        IF(rising_edge(CLK)) THEN
            IF(RST = '1') THEN
                current_state <= Idle;
                temp_res <= '0';
            ELSE
                temp_res <= '1';
                CASE (current_state) IS
                    WHEN Idle    =>
                        IF(EN = '1') THEN
                            temp_dc <= '0';
                            current_state <= VddOn;
                        END IF;

                    --Initialization Sequence
                    --This should be done everytime the PmodOLED is started
                    WHEN VddOn    =>
                        temp_vdd <= '0';
                        current_state <= Wait1;
                    WHEN Wait1    =>
                        after_state <= DispOff;
                        current_state <= Transition3;
                    WHEN DispOff   =>
                        temp_spi_data <= "10101110"; --0xAE
                        after_state <= ResetOn;
                        current_state <= Transition1;
                    WHEN ResetOn  =>
                        temp_res <= '0';
                        current_state <= Wait2;
                    WHEN Wait2   =>
                        after_state <= ResetOff;
                        current_state <= Transition3;
                    WHEN ResetOff  =>
                        temp_res <= '1';
                        after_state <= ChargePump1;
                        after_state <= SetClock1;
                        current_state <= Transition3;

                    WHEN SetClock1   =>
                        temp_spi_data <= X"D5"; --0x
                        after_state <= SetClock2;
                        current_state <= Transition1;
                    WHEN SetClock2   =>
                        temp_spi_data <= X"80"; --0x
                        after_state <= SetMux1;
                        current_state <= Transition1;
                    WHEN SetMux1   =>
                        temp_spi_data <= X"A8"; --0x
                        after_state <= SetMux2;
                        current_state <= Transition1;
                    WHEN SetMux2   =>
                        temp_spi_data <= X"1F"; --0x
                        after_state <= SetOffset1;
                        current_state <= Transition1;
                    WHEN SetOffset1   =>
                        temp_spi_data <= X"D3"; --0x
                        after_state <= SetOffset2;
                        current_state <= Transition1;
                    WHEN SetOffset2   =>
                        temp_spi_data <= X"00"; --0x
                        after_state <= SetLine;
                        current_state <= Transition1;
                    WHEN SetLine   =>
                        temp_spi_data <= X"40"; --0x
                        after_state <= ChargePump1;
                        current_state <= Transition1;

                    WHEN ChargePump1 =>
                        temp_spi_data <= "10001101"; --0x8D
                        after_state <= ChargePump2;
                        current_state <= Transition1;
                    WHEN ChargePump2  =>
                        temp_spi_data <= "00010100"; --0x14
                        --after_state <= PreCharge1;
                        after_state <= InvertDisp1;
                        current_state <= Transition1;
                    WHEN PreCharge1 =>
                        temp_spi_data <= "11011001"; --0xD9
                        after_state <= PreCharge2;
                        current_state <= Transition1;
                    WHEN PreCharge2 =>
                        temp_spi_data <= "11110001"; --0xF1
                        after_state <= VbatOn;
                        current_state <= Transition1;
                    WHEN VbatOn   =>
                        temp_vbat <= '0';
                        current_state <= Wait3;
                    WHEN Wait3   =>
                        --after_state <= DispContrast1;
                        after_state <= SetEntireOn;
                        current_state <= Transition3;
                    WHEN DispContrast1=>
                        temp_spi_data <= "10000001"; --0x81
                        after_state <= DispContrast2;
                        current_state <= Transition1;
                    WHEN DispContrast2=>
                        temp_spi_data <= "00001111"; --0x0F
                        --after_state <= InvertDisp1;
                        after_state <= PreCharge1;
                        current_state <= Transition1;
                    WHEN InvertDisp1 =>
                        temp_spi_data <= "10100001"; --0xA1
                        after_state <= InvertDisp2;
                        current_state <= Transition1;
                    WHEN InvertDisp2 =>
                        temp_spi_data <= X"C8";   --"11001000"; --0xC8
                        after_state <= ComConfig1;
                        current_state <= Transition1;
                    WHEN ComConfig1 =>
                        temp_spi_data <= "11011010"; --0xDA
                        after_state <= ComConfig2;
                        current_state <= Transition1;
                    WHEN ComConfig2  =>
                        temp_spi_data <= X"02";   --"00100000"; --0x20
                        --after_state <= DispOn;
                        after_state <= DispContrast1;
                        current_state <= Transition1;

                    WHEN SetEntireOn =>
                        temp_spi_data <= X"A4"; --0x
                        after_state <= SetNormalInvDisp;
                        current_state <= Transition1;
                    WHEN SetNormalInvDisp =>
                        temp_spi_data <= X"A6"; --0x
                        after_state <= DispOn;
                        current_state <= Transition1;

                    WHEN DispOn   =>
                        temp_spi_data <= "10101111"; --0xAF
                        after_state <= Done;
                        current_state <= Transition1;
                    --END Initialization sequence

                    --Used for debugging, This command turns the entire screen on regardless of memory
                    WHEN FullDisp  =>
                        temp_spi_data <= "10100101"; --0xA5
                        after_state <= Done;
                        current_state <= Transition1;

                    --Done state
                    WHEN Done   =>
                        IF(EN = '0') THEN
                            temp_fin <= '0';
                            current_state <= Idle;
                        ELSE
                            temp_fin <= '1';
                        END IF;

                    --SPI transitions
                    --1. Set SPI_EN to 1
                    --2. Waits for SpiCtrl to finish
                    --3. Goes to clear state (Transition5)
                    WHEN Transition1 =>
                        temp_spi_en <= '1';
                        current_state <= Transition2;
                    WHEN Transition2 =>
                        IF(temp_spi_fin = '1') THEN
                            current_state <= Transition5;
                        END IF;

                    --Delay Transitions
                    --1. Set DELAY_EN to 1
                    --2. Waits for Delay to finish
                    --3. Goes to Clear state (Transition5)
                    WHEN Transition3 =>
                        temp_delay_en <= '1';
                        current_state <= Transition4;
                    WHEN Transition4 =>
                        IF(temp_delay_fin = '1') THEN
                            current_state <= Transition5;
                        END IF;

                    --Clear transition
                    --1. Sets both DELAY_EN and SPI_EN to 0
                    --2. Go to after state
                    WHEN Transition5 =>
                          temp_spi_en <= '0';
                          temp_delay_en <= '0';
                          current_state <= after_state;
                    --END SPI transitions
                    --END Delay Transitions
                    --END Clear transition

                    WHEN others   =>
                        current_state <= Idle;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE Behavioral;