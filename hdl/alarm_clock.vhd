-- vim: set syntax=vhdl ts=8 sts=2 sw=2 et:

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

ENTITY alarm_clock IS
    PORT(
        -- Alarm Clock
        mclk              : IN    std_logic; -- Master clock 125MHz
        reset             : IN    std_logic; -- Reset (Switch-SW1 auf FPGA-Board)
        btn0              : IN    std_logic; -- Set Time    (Push-BTN3 auf FPGA-Board)
        btn1              : IN    std_logic; -- Set Alarm   (Push-BTN2 auf FPGA-Board)
        btn2              : IN    std_logic; -- Set Minutes (Push-BTN0 auf FPGA-Board)
        btn3              : IN    std_logic; -- Set Hours   (Push-BTN1 auf FPGA-Board)
        sw0               : IN    std_logic; -- Set Alarm ON/OFF (Switch-SW0 auf FPGA-Board)
        ring_led          : OUT   std_logic; -- Led LD7 auf FPGA-Board
        -- OLED
        CS                : OUT   std_logic;
        OLED_SDIN         : OUT   std_logic;
        OLED_SCLK         : OUT   std_logic;
        OLED_DC           : OUT   std_logic;
        OLED_RES          : OUT   std_logic;
        OLED_VBAT         : OUT   std_logic;
        OLED_VDD          : OUT   std_logic;
        -- IPI
        AC_BCLK           : OUT   std_logic_vector ( 0 TO 0 );
        AC_MCLK           : OUT   std_logic;
        AC_MUTE_N         : OUT   std_logic_vector ( 0 TO 0 );
        AC_PBLRC          : OUT   std_logic_vector ( 0 TO 0 );
        AC_RECLRC         : OUT   std_logic_vector ( 0 TO 0 );
        AC_SDATA_I        : IN    std_logic;
        AC_SDATA_O        : OUT   std_logic_vector ( 0 TO 0 );
        DDR_addr          : INOUT std_logic_vector ( 14 DOWNTO 0 );
        DDR_ba            : INOUT std_logic_vector (  2 DOWNTO 0 );
        DDR_cas_n         : INOUT std_logic;
        DDR_ck_n          : INOUT std_logic;
        DDR_ck_p          : INOUT std_logic;
        DDR_cke           : INOUT std_logic;
        DDR_cs_n          : INOUT std_logic;
        DDR_dm            : INOUT std_logic_vector (  3 DOWNTO 0 );
        DDR_dq            : INOUT std_logic_vector ( 31 DOWNTO 0 );
        DDR_dqs_n         : INOUT std_logic_vector (  3 DOWNTO 0 );
        DDR_dqs_p         : INOUT std_logic_vector (  3 DOWNTO 0 );
        DDR_odt           : INOUT std_logic;
        DDR_ras_n         : INOUT std_logic;
        DDR_reset_n       : INOUT std_logic;
        DDR_we_n          : INOUT std_logic;
        FIXED_IO_ddr_vrn  : INOUT std_logic;
        FIXED_IO_ddr_vrp  : INOUT std_logic;
        FIXED_IO_mio      : INOUT std_logic_vector ( 53 DOWNTO 0 );
        FIXED_IO_ps_clk   : INOUT std_logic;
        FIXED_IO_ps_porb  : INOUT std_logic;
        FIXED_IO_ps_srstb : INOUT std_logic;
        iic_0_scl_io      : INOUT std_logic;
        iic_0_sda_io      : INOUT std_logic
      );
END ENTITY alarm_clock;

ARCHITECTURE behavioral OF alarm_clock IS
    component system is
        port (
            HS_Sigs_tri_i     : IN    std_logic_vector ( 7 downto 0 );
            DDR_cas_n         : INOUT std_logic;
            DDR_cke           : INOUT std_logic;
            DDR_ck_n          : INOUT std_logic;
            DDR_ck_p          : INOUT std_logic;
            DDR_cs_n          : INOUT std_logic;
            DDR_reset_n       : INOUT std_logic;
            DDR_odt           : INOUT std_logic;
            DDR_ras_n         : INOUT std_logic;
            DDR_we_n          : INOUT std_logic;
            DDR_ba            : INOUT std_logic_vector (  2 DOWNTO 0 );
            DDR_addr          : INOUT std_logic_vector ( 14 DOWNTO 0 );
            DDR_dm            : INOUT std_logic_vector (  3 DOWNTO 0 );
            DDR_dq            : INOUT std_logic_vector ( 31 DOWNTO 0 );
            DDR_dqs_n         : INOUT std_logic_vector (  3 DOWNTO 0 );
            DDR_dqs_p         : INOUT std_logic_vector (  3 DOWNTO 0 );
            FIXED_IO_mio      : INOUT std_logic_vector ( 53 DOWNTO 0 );
            FIXED_IO_ddr_vrn  : INOUT std_logic;
            FIXED_IO_ddr_vrp  : INOUT std_logic;
            FIXED_IO_ps_srstb : INOUT std_logic;
            FIXED_IO_ps_clk   : INOUT std_logic;
            FIXED_IO_ps_porb  : INOUT std_logic;
            IIC_0_sda_i       : IN    std_logic;
            IIC_0_sda_o       : OUT   std_logic;
            IIC_0_sda_t       : OUT   std_logic;
            IIC_0_scl_i       : IN    std_logic;
            IIC_0_scl_o       : OUT   std_logic;
            IIC_0_scl_t       : OUT   std_logic;
            SH_Sigs_tri_o     : OUT   std_logic_vector ( 7 DOWNTO 0 );
            audio_mclk        : IN    std_logic;
            AC_SDATA_I        : IN    std_logic;
            AC_MCLK           : OUT   std_logic;
            FCLK_12288khz     : OUT   std_logic;
            FCLK_11289khz     : OUT   std_logic;
            AC_SDATA_O        : OUT   std_logic_vector ( 0 TO 0 );
            AC_PBLRC          : OUT   std_logic_vector ( 0 TO 0 );
            AC_RECLRC         : OUT   std_logic_vector ( 0 TO 0 );
            AC_BCLK           : OUT   std_logic_vector ( 0 TO 0 );
            AC_MUTE_N         : OUT   std_logic_vector ( 0 TO 0 )
        );
    end component system;
    component IOBUF is
    port (
        I   : IN    std_logic;
        O   : OUT   std_logic;
        T   : IN    std_logic;
        IO  : INOUT std_logic
    );
    end component IOBUF;
    signal iic_0_scl_i : STD_LOGIC;
    signal iic_0_scl_o : STD_LOGIC;
    signal iic_0_scl_t : STD_LOGIC;
    signal iic_0_sda_i : STD_LOGIC;
    signal iic_0_sda_o : STD_LOGIC;
    signal iic_0_sda_t : STD_LOGIC;

    signal hs_sigs  : std_logic_vector (7 downto 0);
    signal sh_sigs  : std_logic_vector (7 downto 0);
    signal start    : std_logic;
    signal sw_err   : std_logic;


    component BUFGCTRL is
        generic (
            INIT_OUT     : integer;
            PRESELECT_I0 : boolean;
            PRESELECT_I1 : boolean);
        port (
            O       : out STD_LOGIC;
            CE0     : in  STD_LOGIC;
            CE1     : in  STD_LOGIC;
            I0      : in  STD_LOGIC;
            I1      : in  STD_LOGIC;
            IGNORE0 : in  STD_LOGIC;
            IGNORE1 : in  STD_LOGIC;
            S0      : in  STD_LOGIC;
            S1      : in  STD_LOGIC
        );
    end component BUFGCTRL;
    signal audio_mclk : std_logic;
    signal clk_12mhz  : std_logic;
    signal clk_11mhz  : std_logic;
    signal ClkSel     : std_logic;

    COMPONENT controller IS
        PORT(
            btn                     : IN  std_logic_vector(3 DOWNTO 0);
            sw                      : IN  std_logic;
            o_mins, o_secs, o_wmins : OUT integer RANGE 0 TO 59;
            o_hours, o_whours       : OUT integer RANGE 0 TO 23;
            state                   : OUT std_logic_vector(1 downto 0);
            alarm                   : OUT std_logic;
            clk                     : IN  std_logic;
            reset                   : IN  std_logic
        );
    END COMPONENT;

    COMPONENT clock_div IS
        PORT(
            I : IN  std_logic;
            O : OUT std_logic);
    END COMPONENT;

    COMPONENT display IS
        PORT(
            i_mins, i_secs, i_wmins : IN integer RANGE 0 TO 59;
            i_hours, i_whours       : IN integer RANGE 0 TO 23;
            state                   : IN std_logic_vector(1 downto 0);
            alarm                   : IN std_logic;
            alarm_s                 : IN std_logic;
            sw_err                  : IN std_logic;

            CS                      : OUT std_logic;
            OLED_SDIN               : OUT std_logic;
            OLED_SCLK               : OUT std_logic;
            OLED_DC                 : OUT std_logic;
            OLED_RES                : OUT std_logic;
            OLED_VBAT               : OUT std_logic;
            OLED_VDD                : OUT std_logic;

            dclk                    : IN  std_logic;
            rst                     : IN  std_logic
        );
    END COMPONENT;

    SIGNAL number            : integer RANGE 0 TO 9;
    SIGNAL clk               : std_logic;
    SIGNAL state             : std_logic_vector(1 downto 0);
    SIGNAL alarm             : std_logic;

    SIGNAL hours, whours     : integer RANGE 0 TO 23;
    SIGNAL secs, mins, wmins : integer RANGE 0 TO 59;

    SIGNAL digit_inv         : std_logic_vector(3 DOWNTO 0);
    SIGNAL switches          : std_logic_vector(3 downto 0);
    SIGNAL ring_local        : std_logic;

BEGIN
    iic_0_scl_iobuf: component IOBUF
        port map (
            I  => iic_0_scl_o,
            IO => iic_0_scl_io,
            O  => iic_0_scl_i,
            T  => iic_0_scl_t
        );
    iic_0_sda_iobuf: component IOBUF
        port map (
            I  => iic_0_sda_o,
            IO => iic_0_sda_io,
            O  => iic_0_sda_i,
            T  => iic_0_sda_t
        );
    system_i: component system
        port map (
            AC_BCLK(0) => AC_BCLK(0),
            AC_MCLK => AC_MCLK,
            AC_MUTE_N(0) => AC_MUTE_N(0),
            AC_PBLRC(0) => AC_PBLRC(0),
            AC_RECLRC(0) => AC_RECLRC(0),
            AC_SDATA_I => AC_SDATA_I,
            AC_SDATA_O(0) => AC_SDATA_O(0),
            DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
            DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
            DDR_cas_n => DDR_cas_n,
            DDR_ck_n => DDR_ck_n,
            DDR_ck_p => DDR_ck_p,
            DDR_cke => DDR_cke,
            DDR_cs_n => DDR_cs_n,
            DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
            DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
            DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
            DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
            DDR_odt => DDR_odt,
            DDR_ras_n => DDR_ras_n,
            DDR_reset_n => DDR_reset_n,
            DDR_we_n => DDR_we_n,
            FCLK_11289khz => clk_11mhz,
            FCLK_12288khz => clk_12mhz,
            FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
            FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
            FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
            FIXED_IO_ps_clk => FIXED_IO_ps_clk,
            FIXED_IO_ps_porb => FIXED_IO_ps_porb,
            FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
            HS_Sigs_tri_i(7 downto 0) => hs_sigs(7 downto 0),
            IIC_0_scl_i => iic_0_scl_i,
            IIC_0_scl_o => iic_0_scl_o,
            IIC_0_scl_t => iic_0_scl_t,
            IIC_0_sda_i => iic_0_sda_i,
            IIC_0_sda_o => iic_0_sda_o,
            IIC_0_sda_t => iic_0_sda_t,
            SH_Sigs_tri_o(7 downto 0) => sh_sigs(7 downto 0),
            audio_mclk => audio_mclk
        );

    ClkSel <= sh_sigs(2);

    BufGCtrlMux_l : BUFGCTRL
        generic map (
            INIT_OUT     => 0,
            PRESELECT_I0 => FALSE,
            PRESELECT_I1 => FALSE)
        port map (
            O       => audio_mclk,
            CE0     => not ClkSel,
            CE1     => ClkSel,
            I0      => clk_12mhz,
            I1      => clk_11mhz,
            IGNORE0 => '0',
            IGNORE1 => '0',
            S0      => '1', -- Clock select0 input
            S1      => '1' -- Clock select1 input
        );

    hs_sigs <= "1" & reset & "00000" & alarm;
    start <= sh_sigs(0);
    sw_err <= sh_sigs(1);

 -- clock_div teilt die 125 MHz vom FPGA-Board auf 2^13 Hz runter
    inst_clk_div : clock_div
        PORT MAP(
            I => mclk,
            O => clk);

    ring_led    <= alarm;

 --SWITCHES <= Time & Alarm & Hours & Minutes & AlarmON/OFF;
    switches <= btn3 & btn2 & btn1 & btn0;

    controller1 : controller
        PORT MAP(
            btn      => switches,
            sw       => sw0,
            o_hours  => hours,
            o_mins   => mins,
            o_secs   => secs,
            o_whours => whours,
            o_wmins  => wmins,
            alarm    => alarm,
            state    => state,
            clk      => clk,
--          reset    => reset or not start);
            reset    => reset);

    oled: display
        PORT MAP(
            i_mins => mins,
            i_secs => secs,
            i_wmins => wmins,
            i_hours => hours,
            i_whours => whours,
            state => state,
            alarm => alarm,
            alarm_s => sw0 and not reset,
            sw_err => sw_err,
            CS     => CS,
            OLED_SDIN => OLED_SDIN,
            OLED_SCLK => OLED_SCLK,
            OLED_DC  => OLED_DC,
            OLED_RES => OLED_RES,
            OLED_VBAT => OLED_VBAT,
            OLED_VDD => OLED_VDD,
            dclk     => mclk,
            rst   => reset);

END ARCHITECTURE behavioral;
