----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
--
-- Create Date:    11:50:03 10/24/2011
-- Module Name:    OledExample - Behavioral
-- Project Name:   PmodOLED Demo
-- Tool versions:  ISE 13.2
-- Description: Demo for the PmodOLED.  First displays the alphabet for ~4 seconds and then
--    Clears the display, waits for a ~1 second and then displays "This is Digilent's
--    PmodOLED"
--
-- Revision: 1.2
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

use work.Common.all;

entity OledEx IS
    PORT (
        CLK         : IN  std_logic; --System CLK
        RST         : IN  std_logic; --Synchronous Reset
        EN          : IN  std_logic; --Example block enable pin
        CS          : OUT std_logic; --SPI Chip Select
        SDO         : OUT std_logic; --SPI Data out
        SCLK        : OUT std_logic; --SPI Clock
        DC          : OUT std_logic; --Data/Command Controller
        FIN         : OUT std_logic; --Finish flag for example block

        i_blink     : IN std_logic;
        i_oled_mem  : IN OledMem);
END OledEx;

ARCHITECTURE Behavioral OF OledEx IS

--SPI Controller Component
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

    --Delay Controller Component
    COMPONENT Delay
        PORT(
             CLK        : IN   std_logic;
             RST        : IN   std_logic;
             DELAY_MS   : IN   std_logic_vector(11 DOWNTO 0);
             DELAY_EN   : IN   std_logic;
             DELAY_FIN  : OUT  std_logic
            );
        END COMPONENT;

    --Character Library, Latency = 1
    COMPONENT charLib
      PORT (
        clka  : IN std_logic; --Attach System Clock to it
        addra : IN std_logic_vector(10 DOWNTO 0); --First 8 bits is the ASCII value of the character the last 3 bits are the parts of the char
        douta : OUT std_logic_vector(7 DOWNTO 0) --Data byte out
      );
    END COMPONENT;






    --States for state machine
    TYPE states IS (Idle,
        ClearDC,
        SetPage,
        PageNum,
        LeftColumn1,
        LeftColumn2,
        SetDC,

        ReadScreen,
        WaitS,
        BClearDC,
        BInvDisp,
        BSetDC,
        WaitA,
        UpdateScreen,

        SendChar1,
        SendChar2,
        SendChar3,
        SendChar4,
        SendChar5,
        SendChar6,
        SendChar7,
        SendChar8,
        ReadMem,
        ReadMem2,
        Done,
        Transition1,
        Transition2,
        Transition3,    --Only Delay...
        Transition4,
        Transition5
         );
    --type OledMem is array(0 to 3, 0 to 15) of STD_LOGIC_VECTOR(7 downto 0);

    --Variable that contains what the screen will be after the next UpdateScreen state
    SIGNAL current_screen : OledMem;

    --Current overall state of the state machine
    SIGNAL current_state : states := Idle;
    --State to go to after the SPI transmission is finished
    SIGNAL after_state : states;
    --State to go to after the set page sequence
    SIGNAL after_page_state : states;
    --State to go to after sending the character sequence
    SIGNAL after_char_state : states;
    --State to go to after the UpdateScreen is finished
    SIGNAL after_update_state : states;

    --Contains the value to be outputted to DC
    SIGNAL temp_dc : std_logic := '0';

    --Variables used in the Delay Controller Block
    SIGNAL temp_delay_ms : std_logic_vector (11 DOWNTO 0); --amount of ms to delay
    SIGNAL temp_delay_en : std_logic := '0'; --Enable signal for the delay block
    SIGNAL temp_delay_fin : std_logic; --Finish signal for the delay block

    --Variables used in the SPI controller block
    SIGNAL temp_spi_en : std_logic := '0'; --Enable signal for the SPI block
    SIGNAL temp_spi_data : std_logic_vector (7 DOWNTO 0) := (others => '0'); --Data to be sent out on SPI
    SIGNAL temp_spi_fin : std_logic; --Finish signal for the SPI block

    SIGNAL temp_char : std_logic_vector (7 DOWNTO 0) := (others => '0'); --Contains ASCII value for character
    SIGNAL temp_addr : std_logic_vector (10 DOWNTO 0) := (others => '0'); --Contains address to BYTE needed in memory
    SIGNAL temp_dout : std_logic_vector (7 DOWNTO 0); --Contains byte outputted from memory
    SIGNAL temp_page : std_logic_vector (1 DOWNTO 0) := (others => '0'); --Current page
    SIGNAL temp_index : integer range 0 to 15 := 0; --Current character on page


    SIGNAL timer      : unsigned(15 DOWNTO 0);
    SIGNAL sectrigger : std_logic;
    SIGNAL sec        : std_logic;

BEGIN

    DC <= temp_dc;
    --Example finish flag only high when in done state
    FIN <= '1' WHEN (current_state = Done) ELSE
           '0';
    --Instantiate SPI Block
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
    --Instantiate Delay Block
    DELAY_COMP: Delay PORT MAP (
        CLK => CLK,
        RST => RST,
        DELAY_MS => temp_delay_ms,
        DELAY_EN => temp_delay_en,
        DELAY_FIN => temp_delay_fin
    );
    --Instantiate Memory Block
    CHAR_LIB_COMP : charLib
        PORT MAP (
            clka => CLK,
            addra => temp_addr,
            douta => temp_dout
        );
    --   -- BRAM_SINGLE_MACRO: Single Port RAM
    --    --                    Kintex-7
    --    -- Xilinx HDL Language Template, version 2014.4

    --    -- Note -  This Unimacro model assumes the port directions to be "downto".
    --    --         Simulation of this model with "to" in the port directions could lead to erroneous results.

    --    ---------------------------------------------------------------------
    --    --  READ_WIDTH | BRAM_SIZE | READ Depth  | ADDR Width |            --
    --    -- WRITE_WIDTH |           | WRITE Depth |            |  WE Width  --
    --    -- ============|===========|=============|============|============--
    --    --    37-72    |  "36Kb"   |      512    |    9-bit   |    8-bit   --
    --    --    19-36    |  "36Kb"   |     1024    |   10-bit   |    4-bit   --
    --    --    19-36    |  "18Kb"   |      512    |    9-bit   |    4-bit   --
    --    --    10-18    |  "36Kb"   |     2048    |   11-bit   |    2-bit   --
    --    --    10-18    |  "18Kb"   |     1024    |   10-bit   |    2-bit   --
    --    --     5-9     |  "36Kb"   |     4096    |   12-bit   |    1-bit   --
    --    --     5-9     |  "18Kb"   |     2048    |   11-bit   |    1-bit   --
    --    --     3-4     |  "36Kb"   |     8192    |   13-bit   |    1-bit   --
    --    --     3-4     |  "18Kb"   |     4096    |   12-bit   |    1-bit   --
    --    --       2     |  "36Kb"   |    16384    |   14-bit   |    1-bit   --
    --    --       2     |  "18Kb"   |     8192    |   13-bit   |    1-bit   --
    --    --       1     |  "36Kb"   |    32768    |   15-bit   |    1-bit   --
    --    --       1     |  "18Kb"   |    16384    |   14-bit   |    1-bit   --
    --    ---------------------------------------------------------------------

    --    CHAR_LIB_COMP : BRAM_SINGLE_MACRO
    --    generic map (
    --       BRAM_SIZE => "18Kb", -- Target BRAM, "18Kb" or "36Kb"
    --       DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "7SERIES", "VIRTEX6, "SPARTAN6"
    --       DO_REG => 0, -- Optional output register (0 or 1)
    --       INIT => X"000000000000000000",   --  Initial values on output port
    --       --INIT_FILE => "/scratch-local/hem/gti/git/alarm_clock_audio_zybo_14/alarm_clock_audio_zybo_14.srcs/sources_1/imports/new/charLib.coe",
    --       WRITE_WIDTH => 8,   -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
    --       READ_WIDTH => 8,   -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
    --       SRVAL => X"000000000000000000",   -- Set/Reset value for port output
    --       WRITE_MODE => "WRITE_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
    --      -- The following INIT_xx declarations specify the initial contents of the RAM
    ----       INIT_00 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_01 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_02 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_03 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_04 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_05 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_06 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_07 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_08 => X"00000000 00000000 0000005f 00000000 00000300 03000000 643c2664 3c262400",
    ----       INIT_09 => X"2649497f 49493200 42251208 24522100 20504e55 22582800 00000003 00000000",
    ----       INIT_0A => X"00001c22 41000000 00000041 221c0000 0015150e 0e151500 0008083e 08080000",
    ----       INIT_0B => X"00000050 30000000 00080808 08080000 00000040 00000000 40201008 04020100",
    ----       INIT_0C => X"003e4141 413e0000 0000417f 40000000 00426151 496e0000 00224149 49360000",
    ----       INIT_0D => X"00181412 7f100000 00274949 49710000 003c4a49 48700000 00432111 0d030000",
    ----       INIT_0E => X"00364949 49360000 00060949 291e0000 00000012 00000000 00000052 30000000",
    ----       INIT_0F => X"00000814 14220000 00141414 14141400 00002214 14080000 00020159 05020000",
    ----       INIT_10 => X"3e415d55 4d512e00 407c4a09 4a7c4000 417f4949 49493600 1c224141 41412200",
    ----       INIT_11 => X"417f4141 41221c00 417f4949 5d416300 417f4909 1d010300 1c224149 493a0800",
    ----       INIT_12 => X"417f0808 087f4100 0041417F 41410000 30404141 3F010100 417f080c 12614100",
    ----       INIT_13 => X"417f4140 40406000 417f420c 427f4100 417f420c 117f0100 1c224141 41221c00",
    ----       INIT_14 => X"417f4909 09090600 0c122121 61524c00 417f0909 19694600 66494949 49493300",
    ----       INIT_15 => X"0301417f 41010300 013f4140 413f0100 010f3140 310f0100 011f6114 611f0100",
    ----       INIT_16 => X"41413608 36414100 01034478 44030100 43615149 45436100 00007f41 41000000",
    ----       INIT_17 => X"01020408 10204000 00004141 7f000000 00040201 01020400 00404040 40404000",
    ----       INIT_18 => X"00010200 00000000 00344a4a 4a3c4000 00413f48 48483000 003c4242 42240000",
    ----       INIT_19 => X"00304848 493f4000 003c4a4a 4a2c0000 0000487e 49090000 00264949 493f0100",
    ----       INIT_1A => X"417f4804 44784000 0000447d 40000000 00004044 3d000000 417f1018 24424200",
    ----       INIT_1B => X"0040417f 40400000 427e027c 027e4000 427e4402 427c4000 003c4242 423c0000",
    ----       INIT_1C => X"00417f49 09090600 00060909 497f4100 00427e44 02020400 00644a4a 4a360000",
    ----       INIT_1D => X"00043f44 44200000 00023e40 40227e40 020e3240 320e0200 021e6218 621e0200",
    ----       INIT_1E => X"42621408 14624200 01434538 05030100 00466252 4a466200 00000836 41000000",
    ----       INIT_1F => X"0000007f 00000000 00000041 36080000 00180808 10101800 AA55AA55 AA55AA55"
    ----       INIT_00 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_01 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_02 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_03 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_04 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_05 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_06 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_07 => X"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",
    ----       INIT_08 => X"00000000 00000000 5f000000 00000000 00030000 00000003 64263c64 0024263c",
    ----       INIT_09 => X"7f494926 00324949 08122542 00215224 554e5020 00285822 03000000 00000000",
    ----       INIT_0A => X"221c0000 00000041 41000000 00001c22 0e151500 0015150e 3e080800 00000808",
    ----       INIT_0B => X"50000000 00000030 08080800 00000808 40000000 00000000 08102040 00010204",
    ----       INIT_0C => X"41413e00 00003e41 7f410000 00000040 51614200 00006e49 49412200 00003649",
    ----       INIT_0D => X"12141800 0000107f 49492700 00007149 494a3c00 00007048 11214300 0000030d",
    ----       INIT_0E => X"49493600 00003649 49090600 00001e29 12000000 00000000 52000000 00000030",
    ----       INIT_0F => X"14080000 00002214 14141400 00141414 14220000 00000814 59010200 00000205",
    ----       INIT_10 => X"555d413e 002e514d 094a7c40 00407c4a 49497f41 00364949 4141221c 00224141",
    ----       INIT_11 => X"41417f41 001c2241 49497f41 0063415d 09497f41 0003011d 4941221c 00083a49",
    ----       INIT_12 => X"08087f41 00417f08 7F414100 00004141 41414030 0001013F 0c087f41 00416112",
    ----       INIT_13 => X"40417f41 00604040 0c427f41 00417f42 0c427f41 00017f11 4141221c 001c2241",
    ----       INIT_14 => X"09497f41 00060909 2121120c 004c5261 09097f41 00466919 49494966 00334949",
    ----       INIT_15 => X"7f410103 00030141 40413f01 00013f41 40310f01 00010f31 14611f01 00011f61",
    ----       INIT_16 => X"08364141 00414136 78440301 00010344 49516143 00614345 417f0000 00000041",
    ----       INIT_17 => X"08040201 00402010 41410000 0000007f 01020400 00040201 40404000 00404040",
    ----       INIT_18 => X"00020100 00000000 4a4a3400 00403c4a 483f4100 00304848 42423c00 00002442",
    ----       INIT_19 => X"48483000 00403f49 4a4a3c00 00002c4a 7e480000 00000949 49492600 00013f49",
    ----       INIT_1A => X"04487f41 00407844 7d440000 00000040 44400000 0000003d 18107f41 00424224",
    ----       INIT_1B => X"7f414000 00004040 7c027e42 00407e02 02447e42 00407c42 42423c00 00003c42",
    ----       INIT_1C => X"497f4100 00060909 09090600 00417f49 447e4200 00040202 4a4a6400 0000364a",
    ----       INIT_1D => X"443f0400 00002044 403e0200 407e2240 40320e02 00020e32 18621e02 00021e62",
    ----       INIT_1E => X"08146242 00426214 38454301 00010305 52624600 0062464a 36080000 00000041",
    ----       INIT_1F => X"7f000000 00000000 41000000 00000836 08081800 00181010 55AA55AA 55AA55AA"
    ----       INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
    ----       INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
    ----       INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
    ----       INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
    ----       INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
    ----       INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
    ----       INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
    ----       INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
    ----       INIT_08 => X"64263c640024263c00030000000000035f000000000000000000000000000000",
    ----       INIT_09 => X"0300000000000000554e50200028582208122542002152247f49492600324949",
    ----       INIT_0A => X"3e080800000008080e1515000015150e4100000000001c22221c000000000041",
    ----       INIT_0B => X"0810204000010204400000000000000008080800000008085000000000000030",
    ----       INIT_0C => X"49412200000036495161420000006e497f4100000000004041413e0000003e41",
    ----       INIT_0D => X"112143000000030d494a3c00000070484949270000007149121418000000107f",
    ----       INIT_0E => X"520000000000003012000000000000004909060000001e294949360000003649",
    ----       INIT_0F => X"5901020000000205142200000000081414141400001414141408000000002214",
    ----       INIT_10 => X"4141221c0022414149497f4100364949094a7c4000407c4a555d413e002e514d",
    ----       INIT_11 => X"4941221c00083a4909497f410003011d49497f410063415d41417f41001c2241",
    ----       INIT_12 => X"0c087f4100416112414140300001013F7F4141000000414108087f4100417f08",
    ----       INIT_13 => X"4141221c001c22410c427f4100017f110c427f4100417f4240417f4100604040",
    ----       INIT_14 => X"494949660033494909097f41004669192121120c004c526109497f4100060909",
    ----       INIT_15 => X"14611f0100011f6140310f0100010f3140413f0100013f417f41010300030141",
    ----       INIT_16 => X"417f000000000041495161430061434578440301000103440836414100414136",
    ----       INIT_17 => X"40404000004040400102040000040201414100000000007f0804020100402010",
    ----       INIT_18 => X"42423c0000002442483f4100003048484a4a340000403c4a0002010000000000",
    ----       INIT_19 => X"4949260000013f497e480000000009494a4a3c0000002c4a4848300000403f49",
    ----       INIT_1A => X"18107f4100424224444000000000003d7d4400000000004004487f4100407844",
    ----       INIT_1B => X"42423c0000003c4202447e4200407c427c027e4200407e027f41400000004040",
    ----       INIT_1C => X"4a4a64000000364a447e4200000402020909060000417f49497f410000060909",
    ----       INIT_1D => X"18621e0200021e6240320e0200020e32403e0200407e2240443f040000002044",
    ----       INIT_1E => X"3608000000000041526246000062464a38454301000103050814624200426214",
    ----       INIT_1F => X"55AA55AA55AA55AA080818000018101041000000000008367f00000000000000"
    --       INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
    --       INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
    --       INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
    --       INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
    --       INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
    --       INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
    --       INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
    --       INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
    --       INIT_08 => X"643c26643c26240000000300030000000000005f000000000000000000000000",
    --       INIT_09 => X"000000030000000020504e552258280042251208245221002649497f49493200",
    --       INIT_0A => X"0008083e080800000015150e0e15150000000041221c000000001c2241000000",
    --       INIT_0B => X"4020100804020100000000400000000000080808080800000000005030000000",
    --       INIT_0C => X"002241494936000000426151496e00000000417f40000000003e4141413e0000",
    --       INIT_0D => X"004321110d030000003c4a49487000000027494949710000001814127f100000",
    --       INIT_0E => X"0000005230000000000000120000000000060949291e00000036494949360000",
    --       INIT_0F => X"0002015905020000000022141408000000141414141414000000081414220000",
    --       INIT_10 => X"1c22414141412200417f494949493600407c4a094a7c40003e415d554d512e00",
    --       INIT_11 => X"1c224149493a0800417f49091d010300417f49495d416300417f414141221c00",
    --       INIT_12 => X"417f080c12614100304041413F0101000041417F41410000417f0808087f4100",
    --       INIT_13 => X"1c22414141221c00417f420c117f0100417f420c427f4100417f414040406000",
    --       INIT_14 => X"6649494949493300417f0909196946000c12212161524c00417f490909090600",
    --       INIT_15 => X"011f6114611f0100010f3140310f0100013f4140413f01000301417f41010300",
    --       INIT_16 => X"00007f4141000000436151494543610001034478440301004141360836414100",
    --       INIT_17 => X"00404040404040000004020101020400000041417f0000000102040810204000",
    --       INIT_18 => X"003c42424224000000413f484848300000344a4a4a3c40000001020000000000",
    --       INIT_19 => X"00264949493f01000000487e49090000003c4a4a4a2c000000304848493f4000",
    --       INIT_1A => X"417f101824424200000040443d0000000000447d40000000417f480444784000",
    --       INIT_1B => X"003c4242423c0000427e4402427c4000427e027c027e40000040417f40400000",
    --       INIT_1C => X"00644a4a4a36000000427e440202040000060909497f410000417f4909090600",
    --       INIT_1D => X"021e6218621e0200020e3240320e020000023e4040227e4000043f4444200000",
    --       INIT_1E => X"0000083641000000004662524a46620001434538050301004262140814624200",
    --       INIT_1F => X"AA55AA55AA55AA55001808081010180000000041360800000000007f00000000"
    --    )
    --    port map (
    --       DO => temp_dout,      -- Output data, width defined by READ_WIDTH parameter
    --       ADDR => temp_addr,  -- Input address, width defined by read/write port depth
    --       CLK => CLK,    -- 1-bit input clock
    --       DI => temp_dout,      -- Input data port, width defined by WRITE_WIDTH parameter
    --       EN => '1',      -- 1-bit input RAM enable
    --       REGCE => '0', --REGCE, -- 1-bit input output register enable
    --       RST => '0',--RST,    -- 1-bit input reset
    --       WE => "0"       -- Input write enable, width defined by write port depth
    --    );




    SECTIMER : PROCESS(clk, RST, sectrigger)
        VARIABLE timer_msb_to_zero : unsigned(timer'RANGE);
    BEGIN
        IF RST = '1' THEN
            timer <= (others => '0');
        ELSIF clk'event and clk = '1' THEN
            timer_msb_to_zero                   := timer;
            -- set msb TO zero, the msb will be our overflow bit
            timer_msb_to_zero(timer'length - 1) := '0';
            timer                               <= timer_msb_to_zero + 1;
        END IF;
    END PROCESS SECTIMER;

    sec <= (timer(timer'length - 1));

    PROCESS (CLK)
        variable v_toggle : std_logic := '0';
    BEGIN
        IF(rising_edge(CLK)) THEN
            CASE(current_state) IS
                --Idle until EN pulled high than intialize Page to 0 and go to state Alphabet afterwards
                WHEN Idle =>
                    IF(EN = '1') THEN
                        current_state <= ClearDC;
                        after_page_state <= ReadScreen;
                        temp_page <= "00";
                    END IF;
                --Set current_screen to constant alphabet_screen and update the screen.  Go to state Wait1 afterwards
                WHEN ReadScreen =>
                    current_screen <= i_oled_mem;
                    current_state <= UpdateScreen;
                    IF (i_blink ='1' or v_toggle = '1') THEN
                        after_update_state <= BClearDC;
                    ELSE
                        after_update_state <= WaitS;
                    END IF;
                --Wait 5ms and go to UpdateScreen
                WHEN WaitS =>
                    after_state <= ReadScreen;

                    temp_delay_ms <= "000000000101"; -- min 5ms!!!!
                    current_state <= Transition3;


                WHEN BClearDC =>
                    temp_dc <= '0';
                    current_state <=  BInvDisp;

                WHEN BInvDisp =>
                    IF i_blink = '1' THEN
                        v_toggle := not v_toggle;
                    ELSE
                        v_toggle := '0';
                    END IF;
                    IF v_toggle = '0' THEN
                        temp_spi_data <= X"A6"; --0x
                    ELSE
                        temp_spi_data <= X"A7"; --0x
                    END IF;
                                after_state <= BSetDC;
                                current_state <= Transition1;


                WHEN BSetDC =>
                    temp_dc <= '1';
                    current_state <= WaitA;

                WHEN WaitA =>
                    after_state <= ReadScreen;

                    temp_delay_ms <= "000100000000"; -- 1024ms!!!!
                    current_state <= Transition3;

                --Do nothing until EN is deassertted and then current_state is Idle
                WHEN Done =>
                    IF(EN = '0') THEN
                        current_state <= Idle;
                    END IF;

                --UpdateScreen State
                --1. Gets ASCII value from current_screen at the current page and the current spot of the page
                --2. If on the last character of the page transition update the page number, if on the last page(3)
                --   then the updateScreen go to "after_update_state" after
                WHEN UpdateScreen =>
                    temp_char <= current_screen(CONV_INTEGER(temp_page),temp_index);
                    IF(temp_index = 15) THEN
                        temp_index <= 0;
                        temp_page <= temp_page + 1;
                        after_char_state <= ClearDC;
                        IF(temp_page = "11") THEN
                            after_page_state <= after_update_state;
                        ELSE
                            after_page_state <= UpdateScreen;
                        END IF;
                    ELSE
                        temp_index <= temp_index + 1;
                        after_char_state <= UpdateScreen;
                    END IF;
                    current_state <= SendChar1;

                --Update Page states
                --1. Sets DC to command mode
                --2. Sends the SetPage Command
                --3. Sends the Page to be set to
                --4. Sets the start pixel to the left column
                --5. Sets DC to data mode
                WHEN ClearDC =>
                    temp_dc <= '0';
                    current_state <= SetPage;
                WHEN SetPage =>
                    temp_spi_data <= "00100010"; --0x22
                    after_state <= PageNum;
                    current_state <= Transition1;
                WHEN PageNum =>
                    temp_spi_data <= "000000" & temp_page;
                    after_state <= LeftColumn1;
                    current_state <= Transition1;
                WHEN LeftColumn1 =>
                    temp_spi_data <= "00000000"; --0x00
                    after_state <= LeftColumn2;
                    current_state <= Transition1;
                WHEN LeftColumn2 =>
                    temp_spi_data <= "00010000"; --0x10
                    after_state <= SetDC;
                    current_state <= Transition1;
                WHEN SetDC =>
                    temp_dc <= '1';
                    current_state <= after_page_state;
                --End Update Page States

                --Send Character States
                --1. Sets the Address to ASCII value of char with the counter appended to the end
                --2. Waits a clock for the data to get ready by going to ReadMem and ReadMem2 states
                --3. Send the byte of data given by the block Ram
                --4. Repeat 7 more times for the rest of the character bytes
                WHEN SendChar1 =>
                    temp_addr <= temp_char & "000";
                    after_state <= SendChar2;
                    current_state <= ReadMem;
                WHEN SendChar2 =>
                    temp_addr <= temp_char & "001";
                    after_state <= SendChar3;
                    current_state <= ReadMem;
                WHEN SendChar3 =>
                    temp_addr <= temp_char & "010";
                    after_state <= SendChar4;
                    current_state <= ReadMem;
                WHEN SendChar4 =>
                    temp_addr <= temp_char & "011";
                    after_state <= SendChar5;
                    current_state <= ReadMem;
                WHEN SendChar5 =>
                    temp_addr <= temp_char & "100";
                    after_state <= SendChar6;
                    current_state <= ReadMem;
                WHEN SendChar6 =>
                    temp_addr <= temp_char & "101";
                    after_state <= SendChar7;
                    current_state <= ReadMem;
                WHEN SendChar7 =>
                    temp_addr <= temp_char & "110";
                    after_state <= SendChar8;
                    current_state <= ReadMem;
                WHEN SendChar8 =>
                    temp_addr <= temp_char & "111";
                    after_state <= after_char_state;
                    current_state <= ReadMem;
                WHEN ReadMem =>
                    current_state <= ReadMem2;
                WHEN ReadMem2 =>
                    temp_spi_data <= temp_dout;
                    current_state <= Transition1;
                --End Send Character States

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
    END PROCESS;

END Behavioral;