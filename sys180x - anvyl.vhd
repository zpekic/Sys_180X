----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: zpekic@hotmail.com
-- 
-- Create Date: 05/12/2020 9:45:02 PM
-- Design Name: 
-- Module Name: sys180x-anvyl - Behavioral
-- Project Name: Simple system around microcode implemented CDP1802 CPU
-- Target Devices: https://reference.digilentinc.com/_media/anvyl:anvyl_rm.pdf
-- Tool Versions: ISE 14.7 (nt)
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.99 - Kinda works...
-- Additional Comments:
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.sys180x_package.all;

entity sys180x_anvyl is
    Port ( 
				-- 100MHz on the Anvyl board
				CLK: in std_logic;
				-- Switches
				-- SW(0) -- LED display selection
				--		0 AAAA.DD (CPU bus)
				--		1 UU.TT.EE (microinstruction)
				-- SW(2 downto 1) -- tracing selection
				--   X	0  no tracing
				--   0   1  UART trace 38400 baud
				--   1   1  VGA trace
				-- SW(3)
				--		0 select ROM0
				-- 	1 select ROM1
				-- SW(4)
				-- 	0 1802 mode
				--    1 1805 mode
				-- SW(6 downto 5) -- system clock speed 
				--   0   0	16Hz	(can be used with SS mode)
				--   0   1	1024Hz (can be used with SS mode)
				--   1   0  12.5MHz
				--   1   1  25MHz
				-- SW7
				--   0   single step mode off (BTN3 should be pressed once to start the system)
				--   1   single step mode on (use with BTN3)
				SW: in std_logic_vector(7 downto 0); 
				-- Push buttons 
				-- BTN0 - generate interrupt
				-- BTN1 - show digits 6 and 7 (not 4 and 5) on 7seg LEDs
				-- BTN2 - reset
				-- BTN3 - single step clock cycle forward if in SS mode (NOTE: single press on this button is needed after reset to unlock SS circuit)
				BTN: in std_logic_vector(3 downto 0); 
				-- 6 7seg LED digits
				SEG: out std_logic_vector(6 downto 0); 
				AN: out std_logic_vector(5 downto 0); 
				DP: out std_logic; 
				-- 8 single LEDs
				LED: out std_logic_vector(7 downto 0);
				--PMOD interface
				JA1: inout std_logic;
				JA2: buffer std_logic;
				JA3: in std_logic;
				JA4: inout std_logic;
				JB1: inout std_logic;
				JB2: buffer std_logic;
				JB3: in std_logic;
				JB4: inout std_logic;
				--DIP switches
				DIP_B4, DIP_B3, DIP_B2, DIP_B1: in std_logic;
				DIP_A4, DIP_A3, DIP_A2, DIP_A1: in std_logic;
--				-- Hex keypad
				KYPD_COL: out std_logic_vector(3 downto 0);
				KYPD_ROW: in std_logic_vector(3 downto 0);
				-- SRAM --
				SRAM_CS1: out std_logic;
				SRAM_CS2: out std_logic;
				SRAM_OE: out std_logic;
				SRAM_WE: out std_logic;
				SRAM_UPPER_B: out std_logic;
				SRAM_LOWER_B: out std_logic;
				Memory_address: out std_logic_vector(18 downto 0);
				Memory_data: inout std_logic_vector(15 downto 0);
				-- Red / Yellow / Green LEDs
				LDT1G: out std_logic;
				LDT1Y: out std_logic;
				LDT1R: out std_logic;
				LDT2G: out std_logic;
				LDT2Y: out std_logic;
				LDT2R: out std_logic;
				-- VGA
				HSYNC_O: out std_logic;
				VSYNC_O: out std_logic;
				RED_O: out std_logic_vector(3 downto 0);
				GREEN_O: out std_logic_vector(3 downto 0);
				BLUE_O: out std_logic_vector(3 downto 0)
				-- TFT
--				TFT_R_O: out std_logic_vector(7 downto 0);
--				TFT_G_O: out std_logic_vector(7 downto 0);
--				TFT_B_O: out std_logic_vector(7 downto 0);
--				TFT_CLK_O: out std_logic;
--				TFT_DE_O: out std_logic;
--				TFT_DISP_O: out std_logic;
--				TFT_BKLT_O: out std_logic;
--				TFT_VDDEN_O: out std_logic;
				-- breadboard signal connections
--				BB1: out std_logic;
--				BB2: out std_logic;
--				BB3: out std_logic;
--				BB4: out std_logic;
--				BB5: out std_logic;
--				BB6: out std_logic;
--				BB7: out std_logic;
--				BB8: out std_logic;
--				BB9: out std_logic;
--				BB10: out std_logic
          );
end sys180x_anvyl;

architecture Structural of sys180x_anvyl is

component clock_divider is
	 generic (CLK_FREQ: integer);
    Port ( reset : in  STD_LOGIC;
           clock : in  STD_LOGIC;
           slow : out  STD_LOGIC_VECTOR (11 downto 0);
			  baud : out STD_LOGIC_VECTOR(7 downto 0);
           fast : out  STD_LOGIC_VECTOR (6 downto 0)
			 );
end component;

component clocksinglestepper is
    Port ( reset : in STD_LOGIC;
           clock0_in : in STD_LOGIC;
           clock1_in : in STD_LOGIC;
           clock2_in : in STD_LOGIC;
           clock3_in : in STD_LOGIC;
           clocksel : in STD_LOGIC_VECTOR(1 downto 0);
           modesel : in STD_LOGIC;
           singlestep : in STD_LOGIC;
           clock_out : out STD_LOGIC);
end component;

component debouncer8channel is
	 generic (
					WIDTH: integer
				);
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           signal_raw : in  STD_LOGIC_VECTOR(width - 1 downto 0);
           signal_debounced : out  STD_LOGIC_VECTOR(width - 1 downto 0));
end component;

component sixdigitsevensegled is
    Port ( -- inputs
			  hexdata : in  STD_LOGIC_VECTOR (3 downto 0);
           digsel : in  STD_LOGIC_VECTOR (2 downto 0);
           showdigit : in  STD_LOGIC_VECTOR (5 downto 0);
           showdot : in  STD_LOGIC_VECTOR (5 downto 0);
           showsegments : in  STD_LOGIC;
			  show76: in STD_LOGIC;
			  -- outputs
           anode : out  STD_LOGIC_VECTOR (5 downto 0);
           segment : out  STD_LOGIC_VECTOR (7 downto 0)
			 );
end component;

component uart_receiver is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           din : in  STD_LOGIC;
           dout : out  STD_LOGIC_VECTOR (7 downto 0);
           dout_frame : out  STD_LOGIC;
           dout_valid : in  STD_LOGIC);
end component;

component mcsmp20b IS
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END component;

component hexfilerom is
	 generic (
		filename: string := "";
		address_size: positive := 8;
		max_address: STD_LOGIC_VECTOR(15 downto 0) := X"0000";
		default_value: STD_LOGIC_VECTOR(7 downto 0) := X"00"
		); 
    Port (           
			  clk: in STD_LOGIC;
			  D : out  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR ((address_size - 1) downto 0);
           nRead : in  STD_LOGIC;
           nSelect : in  STD_LOGIC);
end component;

component simpleram is
	 generic (
		address_size: integer;
		default_value: STD_LOGIC_VECTOR(7 downto 0)
	  );
    Port (       
			  clk: in STD_LOGIC;
			  D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR ((address_size - 1) downto 0);
           nRead : in  STD_LOGIC;
           nWrite : in  STD_LOGIC;
           sel : in  STD_LOGIC);
end component;

component CDP180X is
    Port ( CLOCK : in  STD_LOGIC;
           nWAIT : in  STD_LOGIC;
           nCLEAR : in  STD_LOGIC;
           Q : out  STD_LOGIC;
           SC : out  STD_LOGIC_VECTOR (1 downto 0);
           nMRD : out  STD_LOGIC;
           DBUS : inout  STD_LOGIC_VECTOR (7 downto 0);
           nME : in  STD_LOGIC;
           N : out  STD_LOGIC_VECTOR (2 downto 0);
           nEF4 : in  STD_LOGIC;
           nEF3 : in  STD_LOGIC;
           nEF2 : in  STD_LOGIC;
           nEF1 : in  STD_LOGIC;
           MA : out  STD_LOGIC_VECTOR (7 downto 0);
           TPB : buffer  STD_LOGIC;
           TPA : buffer  STD_LOGIC;
           nMWR : out  STD_LOGIC;
           nINTERRUPT : in  STD_LOGIC;
           nDMAOUT : in  STD_LOGIC;
           nDMAIN : in  STD_LOGIC;
           nXTAL : out  STD_LOGIC;
			  -- not part of real device, used to turn on 1805 mode
			  mode_1805: in STD_LOGIC;
			  -- not part of real device, used for debugging
			  A: out STD_LOGIC_VECTOR(15 downto 0);
           hexSel : in  STD_LOGIC_VECTOR (2 downto 0);
           hexOut : out  STD_LOGIC_VECTOR (3 downto 0);
  			  traceEnabled: in STD_LOGIC;
           traceOut : out  STD_LOGIC_VECTOR (7 downto 0);
           traceReady : in  STD_LOGIC);
end component;

component tty_screen is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  enable: in STD_LOGIC;
			  ---
           char : in  STD_LOGIC_VECTOR (7 downto 0);
			  char_sent: out STD_LOGIC;
			  ---
			  maxRow: in STD_LOGIC_VECTOR (7 downto 0);
			  maxCol: in STD_LOGIC_VECTOR (7 downto 0);
           mrd : out  STD_LOGIC;
           mwr : out  STD_LOGIC;
           x : out  STD_LOGIC_VECTOR (7 downto 0);
           y : out  STD_LOGIC_VECTOR (7 downto 0);
			  mready: in STD_LOGIC;
           din : in  STD_LOGIC_VECTOR (7 downto 0);
           dout : out  STD_LOGIC_VECTOR (7 downto 0);
			  
			  -- not part of real device, used for debugging
           hexSel : in  STD_LOGIC_VECTOR (2 downto 0);
           hexOut : out  STD_LOGIC_VECTOR (3 downto 0)
          );
end component;

component mwvga is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
			  din: in STD_LOGIC_VECTOR (7 downto 0);
           hactive : buffer  STD_LOGIC;
           vactive : buffer  STD_LOGIC;
           x : out  STD_LOGIC_VECTOR (7 downto 0);
           y : out  STD_LOGIC_VECTOR (7 downto 0);
			  cursor_enable : in  STD_LOGIC;
			  cursor_type : in  STD_LOGIC;
			  -- VGA connections
           rgb : out  STD_LOGIC_VECTOR (11 downto 0);
           hsync : out  STD_LOGIC;
           vsync : out  STD_LOGIC);
end component;

component xyram is
	 generic (maxram: integer;
				 maxrow: integer;
				 maxcol: integer);
    Port ( clk : in  STD_LOGIC;
           din : in  STD_LOGIC_VECTOR (7 downto 0);
           rw_wr : in  STD_LOGIC;
			  rw_rd : in STD_LOGIC;
			  rw_x : in  STD_LOGIC_VECTOR (7 downto 0);
           rw_y : in  STD_LOGIC_VECTOR (7 downto 0);
			  ro_rd: in STD_LOGIC;
           ro_x : in  STD_LOGIC_VECTOR (7 downto 0);
           ro_y : in  STD_LOGIC_VECTOR (7 downto 0);
           dout : out  STD_LOGIC_VECTOR (7 downto 0));
end component;

component traceunit is
    Port ( reset: in STD_LOGIC;
			  clk : in  STD_LOGIC;
			  enable : in STD_LOGIC;
			  char: in STD_LOGIC_VECTOR(7 downto 0);
           char_sent : buffer STD_LOGIC;
           txd : out  STD_LOGIC);
end component;

--component VModTFT is
--    Port ( Reset : in  STD_LOGIC;
--           Clk : in  STD_LOGIC;
--			  din: in STD_LOGIC_VECTOR (7 downto 0);
--           hactive : buffer  STD_LOGIC;
--           vactive : buffer  STD_LOGIC;
--           x : out  STD_LOGIC_VECTOR (7 downto 0);
--           y : out  STD_LOGIC_VECTOR (7 downto 0);
--			  cursor_enable : in  STD_LOGIC;
--			  cursor_type : in  STD_LOGIC;
--			  display_blank: in STD_LOGIC;
--			  -- TFT connections
--           TFT_R : out STD_LOGIC_VECTOR (7 downto 0);
--           TFT_G : out STD_LOGIC_VECTOR (7 downto 0);
--           TFT_B : out STD_LOGIC_VECTOR (7 downto 0);
--           TFT_CLK : out  STD_LOGIC;
--           TFT_DE : out STD_LOGIC;
--			  TFT_DISP: out STD_LOGIC;
--           TFT_BKLT : out  STD_LOGIC;
--           TFT_VDDEN : out  STD_LOGIC
--          );
--end component;

--component debugtracer is
--    Port ( reset : in  STD_LOGIC;
--           trace : in  STD_LOGIC;
--           ready : out  STD_LOGIC;
--           char : out  STD_LOGIC_VECTOR (7 downto 0);
--           char_sent : in  STD_LOGIC;
--           in0 : in  STD_LOGIC_VECTOR (3 downto 0);
--           in1 : in  STD_LOGIC_VECTOR (3 downto 0);
--           in2 : in  STD_LOGIC_VECTOR (3 downto 0);
--           in3 : in  STD_LOGIC_VECTOR (3 downto 0);
--           in4 : in  STD_LOGIC_VECTOR (3 downto 0);
--           in5 : in  STD_LOGIC_VECTOR (3 downto 0);
--           in6 : in  STD_LOGIC_VECTOR (3 downto 0);
--           in7 : in  STD_LOGIC_VECTOR (3 downto 0);
--           in8 : in  STD_LOGIC_VECTOR (3 downto 0);
--           in9 : in  STD_LOGIC_VECTOR (3 downto 0);
--           in10 : in  STD_LOGIC_VECTOR (3 downto 0);
--           in11 : in  STD_LOGIC_VECTOR (3 downto 0)
--			);
--end component;

--component rom32k8 IS
--  PORT (
--    clka : IN STD_LOGIC;
--    ena : IN STD_LOGIC;
--    addra : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
--    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
--  );
--END component;

--component io_port is
--    Port ( 	clk: in STD_LOGIC;
--				nMRD : in  STD_LOGIC;
--				nMWR : in  STD_LOGIC;
--				N : in  STD_LOGIC_VECTOR (2 downto 0);
--				DBUS : inout  STD_LOGIC_VECTOR (7 downto 0);
--				sel : in  STD_LOGIC_VECTOR (2 downto 0);
--				input : in  STD_LOGIC_VECTOR (7 downto 0);
--				data : buffer  STD_LOGIC_VECTOR (7 downto 0));
--end component;

-- CPU buses
signal D: std_logic_vector(7 downto 0);
--signal AL: std_logic_vector(7 downto 0);
--signal AH: std_logic_vector(7 downto 0);
signal A: std_logic_vector(15 downto 0);
alias AH: std_logic_vector(7 downto 0) is A(15 downto 8);
alias AL: std_logic_vector(7 downto 0) is A(7 downto 0);
signal N: std_logic_vector(2 downto 0);
signal SC: std_logic_vector(1 downto 0);
signal nMRD, nMWR, TPA, TPB: std_logic;
signal Q, nEF3: std_logic;
signal nME: std_logic;

signal Reset, nReset, nWait: std_logic;
signal clock_main: std_logic;

signal ram_write: std_logic;
signal dmem: std_logic_vector(7 downto 0);
signal wea: std_logic_vector(3 downto 0);
signal douta: std_logic_vector(31 downto 0);

signal nROMSel : std_logic;
signal nExtRamEnable, nExtRamRead, nExtRamWrite: std_logic;
signal xmem: std_logic_vector(7 downto 0);

-- other signals
signal reset_delay: std_logic_vector(3 downto 0);

signal switch: std_logic_vector(7 downto 0);
alias sw_ssmode: 		std_logic is switch(7);
alias sw_cpufreq: 	std_logic_vector(1 downto 0) is switch(6 downto 5);
alias sw_1805mode: 	std_logic is switch(4);
alias sw_romsel: 		std_logic is switch(3);
alias sw_tracemode: 	std_logic_vector(1 downto 0) is switch(2 downto 1);
alias sw_showcpu: 	std_logic is switch(0);

signal button: std_logic_vector(7 downto 0);
alias btn_start: 	std_logic is button(3);
alias btn_reset: 	std_logic is button(2);
alias btn_show67: std_logic is button(1);
alias btn_interrupt: std_logic is button(0);

signal hexData, hexBus, hexCpu, hexTTY: std_logic_vector(3 downto 0);
--signal test_code: std_logic_vector(7 downto 0);
signal out4: std_logic_vector(7 downto 0);
--signal selMem: std_logic;
signal busActive: std_logic;

-- frequencies
signal freq2k, freq1k, freq512, freq256, freq128, freq64, freq32, freq16, freq8, freq4, freq2, freq1: std_logic;
signal freq57600, freq38400, freq19200, freq9600, freq4800, freq2400, freq1200, freq600, freq300: std_logic;
signal freq50M, freq25M, freq12M5, freq6M25, freq3M125, freq1M5625, freq0m78125: std_logic;
signal scanCnt: std_logic_vector(3 downto 0);
alias  ledDigSel: std_logic_vector(2 downto 0) is scanCnt(2 downto 0);

-- VGA
signal vga_memaddr: std_logic_vector(15 downto 0);
signal vga_hactive, vga_vactive: std_logic;
signal vga_cursor_enable: std_logic;
signal vga_char: std_logic_vector(7 downto 0);

-- TFT
--signal tft_memaddr: std_logic_vector(15 downto 0);
--signal tft_hactive, tft_vactive: std_logic;
--signal tft_cursor_enable: std_logic;
--signal tft_char: std_logic_vector(7 downto 0);

-- KBD (hex 4*4 keyboard)
signal kbd_ready: std_logic;
signal kbd_buffer, kbd_current: std_logic_vector(7 downto 0);
signal kypd_pressed: std_logic;

type intmap is array(0 to 15) of integer range 0 to 15;
constant kbd2hex: intmap := (
	1, 	2, 	3,		10,
	4, 	5, 	6,		11,
	7, 	8, 	9,		12,
	0, 	15, 	14,	13
);

-- instruction tracer
signal bus_memaddr, tty_memaddr: std_logic_vector(15 downto 0);
signal vgatracer_ascii, uarttracer_ascii, cputrace_ascii, bustrace_ascii: std_logic_vector(7 downto 0);
signal uarttracer_ready, vgatracer_ready, cputrace_ready, bustrace_ready, traceEnabled, traceReady: std_logic;
signal bus_wr, bus_rd, tty_wr, tty_rd: std_logic;
signal bus_char, tty_char, mem_char: std_logic_vector(7 downto 0);
signal traceExtended: std_logic;
signal fetch, fetch_extended, fetch_sep_r1, fetch_sep_r5: std_logic;

-- LED signals that also go to VGA
signal led_anode: std_logic_vector(5 downto 0);
signal led_segment: std_logic_vector(7 downto 0);

-- UARTs 
-- FTDI connected to PMOD JB: https://store.digilentinc.com/pmod-usbuart-usb-to-uart-interface/
alias JB_RTS: std_logic is JB1;
alias JB_RXD: std_logic is JB2;
alias JB_TXD: std_logic is JB3;
alias JB_CTS: std_logic is JB4;
alias JA_RTS: std_logic is JA1;
alias JA_RXD: std_logic is JA2;
alias JA_TXD: std_logic is JA3;
alias JA_CTS: std_logic is JA4;
signal uart_data: std_logic_vector(7 downto 0);
signal uart_valid, uart_frame: std_logic;

-- auto tracer
type mem256x1 is array(0 to 255) of std_logic;
signal traceMem: mem256x1 := (others => '0');
signal OpCode : std_logic_vector(7 downto 0);
signal traceDone, tr_current, tr_previous: std_logic;

begin
   
	Reset <= BTN(2); --USR_BTN;
	nReset <= '0' when (Reset = '1') or (reset_delay /= "0000") else '1'; 
	-- delay to generate nReset 4 cycles after reset
	generate_nReset: process (clock_main, Reset)
	begin
		if (Reset = '1') then
			reset_delay <= "1111";
		else
			if (rising_edge(clock_main)) then
				reset_delay <= reset_delay(2 downto 0) & Reset;
			end if;
		end if;
	end process;
	
	-- "bit bang" serial connected to Q and nEF3
	JA_RXD <= (Q xor DIP_A1);
	nEF3 <= (JA_TXD xor DIP_A2);
	
	--BB9 <= (Q xor DIP_A1);
	--BB10 <= (JA_TXD xor DIP_A2);
	
	scanCnt <= freq32 & freq64 & freq128 & freq256;
	
	 -- DISPLAY
	LDT2R <= JA_TXD;	LDT1R <= JA_RXD;	-- CPU
	LDT2Y <= JB_TXD;	LDT1Y <= JB_RXD;	-- Tracer
	LDT2G <= SC(1); 	LDT1G <= SC(0);

	LED <= out4 when (button(0) = '1') else (TPA & TPB & (not nMRD) & (not nMWR) & clock_main & N);
	 
    led6x7: sixdigitsevensegled port map ( 
			  -- inputs
			  hexdata => hexData,
			  digsel => ledDigSel,
           showdigit => "111111",
			  showdot => '0' & sw_showcpu & "0100",
           showsegments => busActive,
			  show76 => button(1),
			  -- outputs
           anode => led_anode,
			  segment => led_segment
			 );
	 
	 AN <= led_anode;
	 SEG <= led_segment(6 downto 0);
	 DP <= led_segment(7);
	 
	 with ledDigSel select 
		hexBus <= 	D(3 downto 0) when "000",
						D(7 downto 4) when "001",
						A(3 downto 0) when "010",
						A(7 downto 4) when "011",
						A(11 downto 8) when "100",
						A(15 downto 12) when "101",
						--kbd_buffer(3 downto 0) when "110",
						--kbd_buffer(7 downto 4) when "111";
						KYPD_ROW(3 downto 0) when "110",
						button(7 downto 4) when "111";

--		hexBus <= 	D(3 downto 0) when "000",
--						D(7 downto 4) when "001",
--						"00" & tr_current & tr_previous when "010",
--						"000" & traceDone when "011",
--						OpCode(3 downto 0) when "100",
--						OpCode(7 downto 4) when "101",
--						"0000" when others;
						
	 hexData <= hexCpu when (sw_showcpu = '1') else hexBus;
	 --hexData <= hexTTY when (switch(0) = '1') else hexBus;
	 busActive <= '1' when (sw_showcpu = '1') else not(nMRD and nMWR);
	 
    -- FREQUENCY GENERATOR
    one_sec: clock_divider
	 generic map (CLK_FREQ => 100e6)	 
	 port map 
    (
        clock => CLK,
        reset => Reset,
        slow(11) => freq1, -- 1Hz
        slow(10) => freq2, -- 2Hz
        slow(9) => freq4, -- 4Hz
        slow(8) => freq8, -- 8Hz
        slow(7) => freq16,  -- 16Hz
        slow(6) => freq32,  -- 32Hz
        slow(5) => freq64,  -- 64Hz
        slow(4) => freq128,  -- 128Hz
        slow(3) => freq256,  -- 256Hz
        slow(2) => freq512,  -- 512Hz
        slow(1) => freq1k,  -- 1024Hz
        slow(0) => freq2k,  -- 2048Hz
		  baud(7) => freq300,
		  baud(6) => freq600,		  
		  baud(5) => freq1200,
		  baud(4) => freq2400,
		  baud(3) => freq4800,
		  baud(2) => freq9600,
		  baud(1) => freq19200,
		  baud(0) => freq38400,
		  fast(6) => freq0M78125,
		  fast(5) => freq1M5625,
		  fast(4) => freq3M125,
		  fast(3) => freq6M25,
		  fast(2) => freq12M5,
		  fast(1) => freq25M,
		  fast(0) => freq50M
    );

	-- Single step by each clock cycle, slow or fast
	ss: clocksinglestepper port map (
        reset => Reset,
        clock3_in => freq25M,
        clock2_in => freq12M5,
        clock1_in => freq1M5625,
        clock0_in => freq16,
        clocksel => sw_cpufreq,
        modesel => sw_ssmode, -- or selMem,
        singlestep => btn_start,
        clock_out => clock_main
    );

	-- DEBOUNCE the 8 switches, 4 buttons, 4 keyboard return lines
    debouncer: debouncer8channel
		generic map (
			width => 16	 
		)
		port map (
			clock => freq2k,
			reset => Reset,
			signal_raw(15 downto 8) => SW,
			signal_raw(7 downto 4) => KYPD_ROW(3 downto 0), -- xor "1111",
			signal_raw(3 downto 0) => BTN(3 downto 0),

			signal_debounced(15 downto 8) => switch,
			signal_debounced(7 downto 0) => button
    );
			
-- 64k memory is block RAM on the FPGA, pre-initialized with BASIC/Monitor in range 0x0000 - 0x7FFF
-- 32-bit * 16k instead of 8 bit * 64 memory layout is due to Bin2Coe.exe utility by Pedro Ignacio Martos
-- which converts into 32bit words.
sysmem: mcsmp20b port map
	(
    clka => TPB,
    ena => nME,
    wea => wea,
    addra => A(15 downto 2),
    dina => D & D & D & D,
    douta => douta
	);

-- memory read path
with A(1 downto 0) select
	dmem <= 	douta( 7 downto  0) when "00",
				douta(15 downto  8) when "01",
				douta(23 downto 16) when "10",
				douta(31 downto 24) when "11";
	
D <= dmem when (nMRD = '0' and nME = '1') else "ZZZZZZZZ";

-- memory write path
--ram_write <= A(15) and (not nMWR);
ram_write <= not nMWR;

wea(0) <= ram_write when (A(1 downto 0) = "00") else '0';
wea(1) <= ram_write when (A(1 downto 0) = "01") else '0';
wea(2) <= ram_write when (A(1 downto 0) = "10") else '0';
wea(3) <= ram_write when (A(1 downto 0) = "11") else '0';

--
-- BASIC3+MONITOR: http://www.sunrise-ev.com/MembershipCard/MCSMP20.pdf
-- Author: Chuch Yakym
--firmware0: hexfilerom 
--	 generic map 
--	 (
--			filename => "firmware\mcsmp20b.hex",
--			address_size => 15,
--			max_address => X"499F",
--			default_value => X"C4" -- NOP opcode
--	 )
--    Port map 
--	 (           
--			  clk => TPB,
--			  D => D,
--           A => A(14 downto 0),
--           nRead => nMRD,
--           nSelect => nRomSel or switch(3)
--	  );
--
------ Tiny BASIC + Monitor: http://www.retrotechnology.com/memship/mship_tbasic.html
------ Authors: TMSI/RCA/Pittman Tiny BASIC, fixes by Loren Christiansen and others
--firmware1: hexfilerom 
--	 generic map 
--	 (
--			filename => "firmware\tb0_test.hex",
--			address_size => 12,
--			max_address => X"0DAF",
--			default_value => X"C4" -- NOP opcode
--	 )
--    Port map 
--	 (           
--			  clk => TPB,
--			  D => D,
--           A => A(11 downto 0),
--           nRead => nMRD,
--           nSelect => nRomSel or (not switch(3))
--	  );
----
--nROMSel <= A(15) when (switch(3) = '0') else (A(15) or A(14) or A(13) or A(12)); 
--
---- Internal memory
----ram4k: simpleram 
----	 generic map
----	 (
----			address_size => 12,
----			default_value => X"C4" -- NOP opcode
----	 )
----    Port map 
----	 (       
----			clk => TPB,
----			D => D,
----			A => A(11 downto 0),
----			nRead => nMRD,
----			nWrite => nMWR,
----			sel => nROMSel
----	 );
--
---- External memory
--	nExtRamEnable <= not nROMSel;
--	nExtRamRead <=   nMRD or nExtRamEnable;
--	nExtRamWrite <=  nMWR or nExtRamEnable;
--
--	SRAM_CS1 <= '0';
--	SRAM_CS2 <= '1';
--	SRAM_OE <= nExtRamRead;
--	SRAM_WE <= nExtRamWrite;
--	SRAM_UPPER_B <= not A(0);
--	SRAM_LOWER_B <= A(0);
--	Memory_address <= "0000" & A(15 downto 1);
--
--	--Memory_data(15 downto 8) <= D when (nExtRamWrite = '0') else "ZZZZZZZZ";
--	--Memory_data(7 downto 0) <= D when (nExtRamWrite = '0') else "ZZZZZZZZ";
--	Memory_data <= D & D when (nExtRamWrite = '0') else "ZZZZZZZZZZZZZZZZ";
--	xmem <= Memory_data(15 downto 8) when (A(0) = '1') else Memory_data(7 downto 0);
--	D <= xmem when (nExtRamRead = '0') else "ZZZZZZZZ";

-- CPU
    cpu: cdp180x Port map
			( CLOCK => clock_main,
           nWAIT => '1', --nWait,
           nCLEAR => nReset,
           Q => Q,
           SC => SC,
           nMRD => nMRD,
           DBUS => D,
           nME => nME,
           N => N, 
           nEF4 => '1',
           nEF3 => nEF3,
           nEF2 => '1',
           nEF1 => '1',
           MA => open, --AL,
           TPB => TPB,
           TPA => TPA,
           nMWR => nMWR,
           nINTERRUPT => (not button(0)),
           nDMAOUT => '1',
           nDMAIN => '1',
           nXTAL => open,
			  -- extra signals (not in original chip)
			  mode_1805 => sw_1805mode, -- original 1802 functionality only
			  A => A,
           hexSel => ledDigSel,
           hexOut => hexCpu,
			  traceEnabled => traceEnabled,
           traceOut => cputrace_ascii,
           traceReady => traceReady
			 );

-- enable internal memory for 8000 - 803F
nME <= (not sw_1805mode) when (A(15 downto 6) = "1000000000") else '1';

-- capture upper addressbus

--A <= AH & AL;
--
--address_upper: process(TPA, AL)
--begin
--	if (falling_edge(TPA)) then
--		AH <= AL;
--	end if;
--end process;

--traceEnabled <= '0' when (switch(2 downto 1) = "00") else '1'; --not(tr_current and tr_previous);
traceReady <= vgatracer_ready and uarttracer_ready;

with sw_tracemode select
	traceEnabled <= 	'0' when "00",
							'1' when "01",
							'1' when "10",
							traceExtended when "11";

fetch <= not (nMRD or SC(1) or SC(0));
fetch_extended <= fetch when (D = X"68") else '0'; -- escape for extended instructions in 1805 mode
fetch_sep_r1	<= fetch when (D = X"D1") else '0';	-- SEP R1 returns to Monitor (see 'R' in http://www.sunrise-ev.com/MembershipCard/MCSMP20.pdf)
fetch_sep_r5	<= fetch when (D = X"D5") else '0';	-- SEP R5 returns to BASIC (see 'CALL' in http://www.sunrise-ev.com/MembershipCard/BASIC3v11user.pdf)
							
set_traceExtended: process(TPB, D, nMWR, SC)
begin
	if (reset = '1') then
		traceExtended <= '0';
	else
		if (falling_edge(TPB)) then
			if (traceExtended = '0') then
				traceExtended <= sw_1805mode and fetch_extended;
			else 
				traceExtended <= not (fetch_sep_r1 or fetch_sep_r5);
			end if;
		end if;
	end if;
end process;

-- automatic tracing!
--autotrace_start: process(reset, TPB, traceMem, D, tr_current, tr_previous)
--begin
--	if (reset = '1') then
--			tr_current <= '0';
--			tr_previous <= '0';
--		else 
--			if (rising_edge(TPB)) then
--
--				if (fetch = '1') then
--					tr_previous <= tr_current;
--					tr_current <= traceMem(to_integer(unsigned(D)));
--					OpCode <= D;
--				end if;
--
--			end if;
--	end if;
--end process;
--
--traceDone <= traceReady when (cputrace_ascii = X"0A") else '0';
--autotrace_end: process(traceDone, OpCode, traceMem)
--begin
--	if (rising_edge(traceDone)) then
--		traceMem(to_integer(unsigned(OpCode))) <= '1';
--	end if;
--end process;

--	D <= test_code when (nMRD = '0') else "ZZZZZZZZ";
--	with A(2 downto 0) select
--		test_code <= 	X"31" when "100", -- BQ 0
--							X"00" when "101",
--							X"39" when "110", -- BNQ 0
--							X"00" when "111",
--							DIP_B4 & DIP_B3 & DIP_B2 & DIP_B1 & DIP_A4 & DIP_A3 & DIP_A2 & DIP_A1 when others;
			
-- uart debug tracer (active when switch(2 downto 1) = "01")
	uart_tracer: traceunit Port map ( 
				reset => reset,
				clk => freq38400,
				enable => sw_tracemode(0),
				char => cputrace_ascii,
				char_sent => uarttracer_ready,
				---
				txd => JB_RXD
			);

---------------------------------------------------------------
-- VGA output, 60 rows * 80 columns
---------------------------------------------------------------
	vga_tty: tty_screen Port map ( 
				reset => reset,
				clk => freq25M, --clock_main,
				enable => sw_tracemode(1),
				char => cputrace_ascii, --uart_acii
				char_sent => vgatracer_ready,
				---
				maxRow => X"3C", -- 60 rowns
				maxCol => X"50", -- 80 columns
				mrd => tty_rd,
				mwr => tty_wr,
				x => tty_memaddr(7 downto 0),
				y => tty_memaddr(15 downto 8),
				din => vga_char,
				mready => not vga_vactive,
				dout => tty_char,
				
			  -- not part of real device, used for debugging
           hexSel => ledDigSel,
           hexOut => hexTTY
			);

	vga_cursor_enable <= freq2 when (tty_memaddr = vga_memaddr) else '0';

	vga_controller: mwvga 
	port map ( 
		reset => reset,
		clk => freq25M, 
		din => vga_char,
		hactive => vga_hactive,
		vactive => vga_vactive,
		x => vga_memaddr(7 downto 0),
		y => vga_memaddr(15 downto 8),
		cursor_enable => vga_cursor_enable,
		cursor_type => switch(5),	-- just for test
		-- VGA connections
		rgb(3 downto 0) => RED_O,
		rgb(7 downto 4) => GREEN_O,
		rgb(11 downto 8) => BLUE_O,
		hsync => HSYNC_O,
		vsync => VSYNC_O
	);

	vga_ram: xyram 
	generic map (
		maxram => 8192, -- must be >= than maxrow * maxcol
		maxrow => 60,
		maxcol => 80	 
	)
	port map (
		clk => freq25M,
		din => tty_char,
		rw_wr => tty_wr,
		rw_rd => tty_rd,
		rw_x => tty_memaddr(7 downto 0),	
		rw_y => tty_memaddr(15 downto 8),	
		ro_rd => vga_hactive or vga_vactive,
		ro_x => vga_memaddr(7 downto 0),
		ro_y => vga_memaddr(15 downto 8),
		dout => vga_char
	);

-- read port 4
D <= kbd_buffer when (N = "100" and nMWR = '0') else "ZZZZZZZZ";

-- write port 4
out4 <= D when (N = "100" and nMRD = '0') else out4;

-- temporary keyboard for testing
with scanCnt(1 downto 0) select
	KYPD_COL <= "1110" when "00",
					"1101" when "01",
					"1011" when "10",
					"0111" when "11";

-- row signals coming through a debouncer
with scanCnt(3 downto 2) select
--	kypd_pressed <= 	KYPD_ROW(0) when "00",
--							KYPD_ROW(1) when "01",
--							KYPD_ROW(2) when "10",
--							KYPD_ROW(3) when "11";
	kypd_pressed <= 	button(4) when "00",
							button(5) when "01",
							button(6) when "10",
							button(7) when "11";

--	uart_in: uart_receiver Port map ( 
--				reset => reset,
--				clk => freq38400,
--				din => JB_TXD,
--				dout => uart_data,
--				dout_frame => uart_frame,
--				dout_valid => uart_valid
--			);

--capture_uart: process(reset, uart_valid, uart_data)
--begin
--	if (reset = '1') then
--		kbd_buffer <= X"00";
--	else
--		if (rising_edge(uart_valid)) then
--			kbd_buffer <= uart_data;
--		end if;
--	end if;

capture_kypd: process(scanCnt, kypd_pressed, reset, kbd_buffer)
begin
	if (reset = '1') then
		kbd_buffer <= X"00";
	else
		if (falling_edge(kypd_pressed)) then
			kbd_buffer <= kbd_buffer(3 downto 0) & std_logic_vector(to_unsigned(kbd2hex(to_integer(unsigned(scanCnt))), 4));
		end if;
	end if;
end process;

---------------------------------------------------------------
-- TFT output, 34 rows * 60 columns
---------------------------------------------------------------
--	tft_tty: tty_screen Port map ( 
--			reset => reset,
--			clk => freq25M, --clock_main,
--			enable => '1',
--			char => kbd_ascii,
--			char_sent => kbd_ready,
--			---
--			maxRow => X"22", -- 34 rowns
--			maxCol => X"3C", -- 60 columns
--			mrd => bus_rd,
--			mwr => bus_wr,
--			x => bus_memaddr(7 downto 0),
--			y => bus_memaddr(15 downto 8),
--			din => tft_char,
--			mready => not tft_vactive,
--			dout => bus_char,
--
--			-- not part of real device, used for debugging
--			hexSel => ledDigSel,
--			hexOut => open
--			);
--
--tft_cursor_enable <= freq2 when (bus_memaddr = tft_memaddr) else '0';
--
--tft_controller: VModTFT Port map ( 
--		Reset => reset,
--		Clk => CLK,
--		din => tft_char,
--		hactive => tft_vactive, 
--		vactive => tft_hactive,
--		x => tft_memaddr(7 downto 0),
--		y => tft_memaddr(15 downto 8),
--		cursor_enable => tft_cursor_enable,
--		cursor_type => not switch(5),	-- just test, opposite from VGA
--		display_blank => freq1,
--		-- TFT connections
--		TFT_R => TFT_R_O,
--		TFT_G => TFT_G_O,
--		TFT_B => TFT_B_O,
--		TFT_CLK => TFT_CLK_O,
--		TFT_DE => TFT_DE_O,
--		TFT_DISP => TFT_DISP_O,
--		TFT_BKLT => TFT_BKLT_O,
--		TFT_VDDEN => TFT_VDDEN_O
--    );
--
--	tft_ram: xyram 
--	generic map (
--		maxram => 2048, -- must be >= than maxrow * maxcol
--		maxrow => 34,
--		maxcol => 60	 
--	)
--	port map (
--		clk => freq25M,
--		din => bus_char,
--		rw_wr => bus_wr,
--		rw_rd => bus_rd,
--		rw_x => bus_memaddr(7 downto 0),	
--		rw_y => bus_memaddr(15 downto 8),	
--		ro_rd => tft_hactive or tft_vactive,
--		ro_x => tft_memaddr(7 downto 0),
--		ro_y => tft_memaddr(15 downto 8),
--		dout => tft_char
--	);


--bus_tracer: debugtracer Port map ( 
--				reset => reset,
--				trace => switch(2) and (not (nMRD and nMWR)),
--				ready => nWait,
--				char => bustrace_ascii,
--				char_sent => bustrace_ready,
--				in0 => kbd_ascii(3 downto 0),
--				in1 => kbd_ascii(7 downto 4),
--				in2 => '0' & N,
--				in3 => X"0", -- not used
--				in4 => D(3 downto 0),
--				in5 => D(7 downto 4),
--				in6 => A(3 downto 0),
--				in7 => A(7 downto 4),
--				in8 => A(11 downto 8),
--				in9 => A(15 downto 12),
--				in10 => SC & nMWR & nMRD,
--				in11 => X"0" -- not used
--			  );

--port4: io_port Port map ( 	
--				clk => TPB,
--				nMRD => nMRD,
--				nMWR => nMWR,
--				N => N,
--				DBUS => D,
--				sel => O"4",
--				input => DIP_B4 & DIP_B3 & DIP_B2 & DIP_B1 & DIP_A4 & DIP_A3 & DIP_A2 & DIP_A1,
--				data => out4
--			);
--
--selMem <= not(nMRD and nMWR) when (A(15 downto 8) = X"00") else '0';

--testprg: simpleram generic map 
--		(
--			address_size => 6,
--			default_value => X"00"
--		)
--		Port map
--		(       
--			  clk => TPB,
--			  D => D,
--           A => switch(3) & A(4 downto 0),
--           nRead => nMRD,
--           nWrite => nMWR,
--           sel => selMem
--		);

end;