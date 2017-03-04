----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
-- 
-- Create Date:    16:48:30 10/10/2011 
-- Module Name:    Delay - Behavioral 
-- Project Name:   PmodOled Demo
-- Tool versions:  ISE 13.2
-- Description:    Creates a delay of DELAY_MS ms
--
-- Revision: 1.0
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY Delay IS
    Port ( CLK 			: IN  std_logic; --System CLK
			RST 		: IN std_logic;  --Global RST (Synchronous)
			DELAY_MS 	: IN  std_logic_vector (11 DOWNTO 0); --Amount of ms to delay
			DELAY_EN 	: IN  std_logic; --Delay block enable
			DELAY_FIN 	: OUT  std_logic); --Delay finish flag
END Delay;

ARCHITECTURE Behavioral OF Delay IS

TYPE states IS (Idle,
				Hold,
				Done);
					
SIGNAL current_state : states := Idle; --Signal for state machine
SIGNAL clk_counter : std_logic_vector(16 DOWNTO 0) := (others => '0'); --Counts up on every rising edge of CLK
SIGNAL ms_counter : std_logic_vector (11 DOWNTO 0) := (others => '0'); --Counts up when clk_counter = 100,000

BEGIN
	--DELAY_FIN goes HIGH when delay is done
	DELAY_FIN <= '1' WHEN (current_state = Done and DELAY_EN = '1') ELSE
					'0';
					
	--State machine for Delay block
	STATE_MACHINE : PROCESS (CLK)
	BEGIN
		IF(rising_edge(CLK)) THEN
			IF(RST = '1') THEN --When RST is asserted switch to idle (synchronous)
				current_state <= Idle;
			ELSE
				CASE (current_state) IS
					WHEN Idle =>
						IF(DELAY_EN = '1') THEN --Start delay on DELAY_EN
							current_state <= Hold;
						END IF;
					WHEN Hold =>
						IF( ms_counter = DELAY_MS) THEN --stay until DELAY_MS has occured
							current_state <= Done;
						END IF;
					WHEN Done =>
						IF(DELAY_EN = '0') THEN --Wait til DELAY_EN is deasserted to go to IDLE
							current_state <= Idle;
						END IF;
					WHEN others =>
						current_state <= Idle;
				END CASE;
			END IF;
		END IF;
	END PROCESS;
	
	
	--Creates ms_counter that counts at 1KHz
	CLK_DIV : PROCESS (CLK)
	BEGIN
		IF(CLK'event and CLK = '1') THEN
			IF (current_state = Hold) THEN
				IF(clk_counter = "11000011010100000") THEN --100,000 
					clk_counter <= (others => '0');
					ms_counter <= ms_counter + 1; --increments at 1KHz
				ELSE
					clk_counter <= clk_counter + 1;
				END IF;
			ELSE --If not in the hold state reset counters
				clk_counter <= (others => '0');
				ms_counter <= (others => '0');
			END IF;
		END IF;
	END PROCESS;

END Behavioral;

