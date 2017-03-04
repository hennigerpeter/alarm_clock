----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
-- 
-- Create Date:    15:14:14 10/10/2011 
-- Module Name:    SpiCtrl - Behavioral 
-- Project Name:   PmodOled Demo
-- Tool versions:  ISE 13.2
-- Description:    Spi block that sends SPI data formatted SCLK active low with
--					SDO changing on the falling edge
--
-- Revision: 1.0 - SPI completed
-- Revision 0.01 - File Created 
--
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY SpiCtrl IS
    PORT ( CLK 		: IN  std_logic; --System CLK (100MHz)
		   RST 		: IN  std_logic; --Global RST (Synchronous)
		   SPI_EN 	: IN  std_logic; --SPI block enable pin
		   SPI_DATA : IN  std_logic_vector (7 DOWNTO 0); --Byte to be sent
		   CS		: OUT std_logic; --Chip Select
           SDO 		: OUT std_logic; --SPI data out
           SCLK 	: OUT std_logic; --SPI clock
		   SPI_FIN	: OUT std_logic);--SPI finish flag
END SpiCtrl;

ARCHITECTURE Behavioral OF SpiCtrl IS

TYPE states IS (Idle,
				Send,
				Hold1,
				Hold2,
				Hold3,
				Hold4,
				Done);
					
SIGNAL current_state : states := Idle; --Signal for state machine

SIGNAL shift_register	: std_logic_vector(7 DOWNTO 0); --Shift register to shift out SPI_DATA saved when SPI_EN was set
SIGNAL shift_counter 	: std_logic_vector(3 DOWNTO 0); --Keeps track how many bits were sent
SIGNAL clk_divided 		: std_logic := '1'; --Used as SCLK
SIGNAL counter 			: std_logic_vector(4 DOWNTO 0) := (others => '0'); --Count clocks to be used to divide CLK
SIGNAL temp_sdo			: std_logic := '1'; --Tied to SDO

SIGNAL falling : std_logic := '0'; --signal indicating that the clk has just fell
BEGIN
	clk_divided <= not counter(4); --SCLK = CLK / 32
	SCLK <= clk_divided;
	SDO <= temp_sdo;
	CS <= '1' WHEN (current_state = Idle and SPI_EN = '0') ELSE
		'0';
	SPI_FIN <= '1' WHEN (current_state = Done) ELSE
			'0';
	
	STATE_MACHINE : PROCESS (CLK)
	BEGIN
		IF(rising_edge(CLK)) THEN
			IF(RST = '1') THEN --Synchronous RST
				current_state <= Idle;
			ELSE
				case (current_state) IS
					WHEN Idle => --Wait for SPI_EN to go high
						IF(SPI_EN = '1') THEN
							current_state <= Send;
						END IF;
					WHEN Send => --Start sending bits, transition out when all bits are sent and SCLK is high
						IF(shift_counter = "1000" and falling = '0') THEN
							current_state <= Hold1;
						END IF;
					WHEN Hold1 => --Hold CS low for a bit
						current_state <= Hold2;
					WHEN Hold2 => --Hold CS low for a bit
						current_state <= Hold3;
					WHEN Hold3 => --Hold CS low for a bit
						current_state <= Hold4;
					WHEN Hold4 => --Hold CS low for a bit
						current_state <= Done;
					WHEN Done => --Finish SPI transimission wait for SPI_EN to go low
						IF(SPI_EN = '0') THEN
							current_state <= Idle;
						END IF;
					WHEN others =>
						current_state <= Idle;
				END case;
			END IF;
		END IF;
	END PROCESS;
	
	CLK_DIV : PROCESS (CLK)
	BEGIN
		IF(rising_edge(CLK)) THEN
			IF (current_state = Send) THEN --start clock counter when in send state
				counter <= counter + 1;
			ELSE --reset clock counter when not in send state
				counter <= (others => '0');
			END IF;
		END IF;
	END PROCESS;
	
	SPI_SEND_BYTE : PROCESS (CLK) --sends SPI data formatted SCLK active low with SDO changing on the falling edge
	BEGIN
		IF(CLK'event and CLK = '1') THEN
			IF(current_state = Idle) THEN
				shift_counter <= (others => '0');
				shift_register <= SPI_DATA; --keeps placing SPI_DATA into shift_register so that when state goes to send it has the latest SPI_DATA
				temp_sdo <= '1';
			ELSIF(current_state = Send) THEN
				IF( clk_divided = '0' and falling = '0') THEN --if on the falling edge of Clk_divided
					falling <= '1'; --Indicate that it is passed the falling edge
					temp_sdo <= shift_register(7); --send out the MSB
					shift_register <= shift_register(6 DOWNTO 0) & '0'; --Shift through SPI_DATA
					shift_counter <= shift_counter + 1; --Keep track of what bit it is on
				ELSIF(clk_divided = '1') THEN --on SCLK high reset the falling flag
					falling <= '0';
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
END Behavioral;

