----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: zpekic@hotmail.com
-- 
-- Create Date:    12:25:11 04/21/2020 
-- Design Name: 	 CDP1802/5/6 compatible CPU in VHDL
-- Module Name:    CDP180X - Behavioral 
-- Project Name: 
-- Target Devices: Digilent Anvyl
-- Tool versions:  Xilinx ISE 14.7
-- Description: 	 This is proof of concept for mcc microcode compiler https://github.com/zpekic/MicroCodeCompiler
--
-- Dependencies:   
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.cdp180x_code.all;
use work.cdp180x_map.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CDP180X is
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
           A : out  STD_LOGIC_VECTOR (15 downto 0);
           hexSel : in  STD_LOGIC_VECTOR (2 downto 0);
           hexOut : out  STD_LOGIC_VECTOR (3 downto 0);
			  traceEnabled: in STD_LOGIC;
           traceOut : out  STD_LOGIC_VECTOR (7 downto 0);
           traceReady : in  STD_LOGIC);
end CDP180X;

architecture Behavioral of CDP180X is

component cpu_control_unit is
	 Generic (
			CODE_DEPTH : positive;
			IF_WIDTH : positive
			);
    Port ( 
			  reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           seq_cond : in  STD_LOGIC_VECTOR (IF_WIDTH - 1 downto 0);
           seq_then : in  STD_LOGIC_VECTOR (CODE_DEPTH - 1 downto 0);
           seq_else : in  STD_LOGIC_VECTOR (CODE_DEPTH - 1 downto 0);
           seq_fork : in  STD_LOGIC_VECTOR (CODE_DEPTH - 1 downto 0);
           cond : in  STD_LOGIC_VECTOR (2 ** IF_WIDTH - 1 downto 0);
           ui_nextinstr : buffer  STD_LOGIC_VECTOR (CODE_DEPTH - 1 downto 0);
           ui_address : out  STD_LOGIC_VECTOR (CODE_DEPTH - 1 downto 0));
end component;

component nibbleadder is
    Port ( cin : in  STD_LOGIC;
           a : in  STD_LOGIC_VECTOR (3 downto 0);
           b : in  STD_LOGIC_VECTOR (3 downto 0);
           na : in  STD_LOGIC;
           nb : in  STD_LOGIC;
           bcd : in  STD_LOGIC;
           y : out  STD_LOGIC_VECTOR (3 downto 0);
           cout : out  STD_LOGIC);
end component;

-- architecture visible registers
signal reg_d: std_logic_vector(7 downto 0); -- data register (== accumulator)
signal reg_t: std_logic_vector(7 downto 0);
signal reg_b: std_logic_vector(7 downto 0);
signal reg_in: std_logic_vector(7 downto 0);
alias reg_i: std_logic_vector(3 downto 0) is reg_in(7 downto 4);
alias reg_n: std_logic_vector(3 downto 0) is reg_in(3 downto 0);

signal reg_x: std_logic_vector(3 downto 0);
signal reg_p: std_logic_vector(3 downto 0);

signal reg_df: std_logic;	-- data flag (== carry/borrow)
signal reg_q: std_logic;	-- Q output
signal reg_mie: std_logic;	-- master interrupt enable

type regblock is array(0 to 15) of std_logic_vector(15 downto 0);
signal reg_r: regblock;
signal reg_y: std_logic_vector(15 downto 0);
alias reg_hi: std_logic_vector(7 downto 0) is reg_y(15 downto 8);
alias reg_lo: std_logic_vector(7 downto 0) is reg_y(7 downto 0);

-- other registers 
signal reg_ef: std_logic_vector(3 downto 0); 	-- holds inverted nEF4..nEF1
signal reg_dma: std_logic_vector(1 downto 0);	-- holds inverted DMA
signal reg_int: std_logic;								-- holds int if enabled
signal reg_extend: std_logic;							-- 1 if executing 68XX extended instructions
signal data_in: std_logic_vector(7 downto 0);	-- data captured from DBUS

-- microcontrol related
signal ui_address, ui_nextinstr: std_logic_vector(CODE_ADDRESS_WIDTH - 1 downto 0);
signal instructionstart: std_logic_vector(7 downto 0);
signal UCLK: std_logic;	-- microinstruction clock (drives machine forward on rising edge)

-- other
signal cond_3X, cond_CX: std_logic;
signal d_is_zero: std_logic;
signal continue: std_logic;
signal alu_y, add_y, r, s: std_logic_vector(7 downto 0);
signal alu_cin, alu_cout, cout: std_logic;
signal sel_reg: std_logic_vector(3 downto 0);
signal alu16_y: std_logic_vector(15 downto 0);
signal alu16_is_zero: std_logic;
signal seq_else: std_logic_vector(7 downto 0);

-- tracer
signal reg_trace: std_logic_vector(8 downto 0);
signal hexTrace: std_logic_vector(3 downto 0);
signal asciiOffs, asciiBase: std_logic_vector(7 downto 0);

-- machine cycle signals
signal mode_reset, mode_pause, mode_run, mode_load: std_logic;
signal sync: std_logic;
signal cnt8: std_logic_vector(2 downto 0);
signal cnt16: std_logic_vector(3 downto 0);

type rom16x8 is array(0 to 15) of std_logic_vector(7 downto 0);
signal cycle_rom: rom16x8 := (
"00100011", -- 00					MA_HIGH				EF	UC
"00100011",	-- 01					MA_HIGH				EF	UC
"10100011",	-- 10	TPA 			MA_HIGH				EF	UC	
"10110001",	-- 11	TPA			MA_HIGH	RD				UC
"00110001",	-- 20					MA_HIGH	RD				UC
"00010001",	-- 21								RD				UC
"00010001",	-- 30								RD				UC
"00010001",	-- 31								RD				UC
"00010001",	-- 40								RD				UC
"00010001",	-- 41								RD				UC
"00011001",	-- 50								RD	WR			UC
"00011001",	-- 51								RD	WR			UC
"00011101",	-- 60								RD	WR DI		UC
"01011101",	-- 61			TPB				RD	WR	DI		UC
"01011001",	-- 70			TPB				RD	WR			UC
"00000000"	-- 71												
);
signal cycle: std_logic_vector(7 downto 0);
alias cycle_tpa: std_logic is cycle(7);
alias cycle_tpb: std_logic is cycle(6);
alias cycle_ahi: std_logic is cycle(5);
alias cycle_rd:  std_logic is cycle(4);
alias cycle_wr:  std_logic is cycle(3);
alias cycle_di:  std_logic is cycle(2);
alias cycle_ef:  std_logic is cycle(1);
alias cycle_uc:  std_logic is cycle(0);

signal state_rom: rom16x8 := (
		-- 										SC1	SC0	RD	WR	OE	NE	S1S2	S1S2S3
"01000011", 	--		exec_nop,		//	0		1		0	0	0	0	1		1
"01100011",		--		exec_memread,	//	0		1		1	0	0	0	1		1
"01011011",		--		exec_memwrite,	//	0		1		0	1	1	0	1		1
"01010111",		--		exec_ioread,	//	0		1		0	1	0	1	1		1
"01100111",		--		exec_iowrite,	//	0		1		1	0	0	1	1		1
"10100011",		--		dma_memread,	//	1		0		1	0	0	0	1		1
"10010011",		--		dma_memwrite,	//	1		0		0	1	0	0	1		1
"11000001",		--		int_nop,			//	1		1		0	0	0	0	0		1
"00100000",		--		fetch_memread,	//	0		0		1	0	0	0	0		0
"00000000",				
"00000000",				
"00000000",				
"00000000",				
"00000000",				
"00000000",				
"00000000"				
);
signal state: std_logic_vector(7 downto 0);
alias state_sc: std_logic_vector(1 downto 0) is state(7 downto 6);
alias state_rd: std_logic is state(5);
alias state_wr: std_logic is state(4);
alias state_oe: std_logic is state(3);
alias state_ne: std_logic is state(2);
alias state_s1s2: 	std_logic is state(1);
alias state_s1s2s3: 	std_logic is state(0);

-- internal RAM
signal ram_en: std_logic;
type internal_mem is array(0 to 63) of std_logic_vector(7 downto 0); 
signal ram: internal_mem := (others => X"C4");

begin

nXTAL <= not CLOCK;

mode_load <= 	(not nCLEAR) 	and (not nWAIT);
mode_reset <= 	(not nCLEAR) 	and nWAIT; 
mode_pause <= 	nCLEAR 			and (not nWAIT);
mode_run <= 	nCLEAR 			and nWAIT;

ram_en <= mode_1805 when (nME = '0') else '0';

-- cycle counter
-- 1 machine cycle is 8 clock cycles, all signals are sync'd to this sequence
machine_cycle: process(CLOCK, mode_reset, mode_pause)
begin
	if (mode_reset = '1') then
		cnt8 <= "000";
	else
		if (falling_edge(CLOCK) and (mode_pause = '0')) then
			cnt8 <= std_logic_vector(unsigned(cnt8) + 1);
		end if;
	end if;
end process;

-- machine cycle (8 clocks, fixed)
cnt16 <= cnt8 & CLOCK;
cycle <= cycle_rom(to_integer(unsigned(cnt16)));

-- CPU state (driven by microcode)
state <= state_rom(to_integer(unsigned(cpu_bus_state)));

-- driving output control signals, which are a combination of cycle and state
TPA <= cycle_tpa;
TPB <= cycle_tpb;
Q <= reg_q;
N <= reg_n(2 downto 0) when (state_ne = '1') else "000"; -- note that 60 and 68 will still generate N=000
SC <= state_sc;

-- ADDRESS BUS - always reflects currently selected R(?), R(?).1 in first 5 periods, R(?).0 in remaining 11
MA <= reg_hi when (cycle_ahi = '1') else reg_lo;	
A <= reg_y;

-- READ/WRITE at specific timing in the cycle, if enabled by CPU state
nMRD <= not (state_rd and cycle_rd);
nMWR <= not (state_wr and cycle_wr);

-- DATA BUS - drive and capture at specific moments in the cycle
DBUS <= alu_y when ((state_oe and cycle_wr) = '1') else "ZZZZZZZZ";

capture_dbus: process(DBUS, ram, cycle_di, state_rd, ram_en)
begin
	if (falling_edge(cycle_di) and state_rd = '1') then
		if (ram_en = '1') then
			data_in <= ram(to_integer(unsigned(reg_y(5 downto 0))));
		else
			data_in <= DBUS;
		end if;
	end if;
end process;

write_ram: process(ram, cycle_wr, ram_en, state_wr)
begin
	if (falling_edge(cycle_wr) and ram_en = '1' and state_wr = '1') then
		ram(to_integer(unsigned(reg_y(5 downto 0)))) <= alu_y;
	end if;
end process;

-- EF input signals capture
-- 1802: rising clock edge while TPA is high, during S1 (execute) state
-- 1805/6: TBD
capture_ef: process(nEF4, nEF3, nEF2, nEF1, cycle_ef, state_sc)
begin
	if (falling_edge(cycle_ef) and (state_sc = "01")) then		
		reg_ef <= (not nEF4) & (not nEF3) & (not nEF2) & (not nEF1);
	end if;
end process;

-- capture state of interrupt
capture_int: process(nINTERRUPT, cycle_di, state_s1s2)
begin
	if (falling_edge(cycle_di) and (state_s1s2 = '1')) then
		reg_int <= reg_mie and (not nINTERRUPT);
	end if;
end process;

-- capture state of dma requests
capture_dma: process(nDMAIN, nDMAOUT, cycle_di, state_s1s2s3)
begin
	if (falling_edge(cycle_di) and (state_s1s2s3 = '1')) then
		reg_dma <= (not nDMAIN) & (not nDMAOUT);
	end if;
end process;

continue <= not (reg_int or reg_dma(1) or reg_dma(0));	-- no external signal received 

-- when tracer is in "disable" mode, 1 microinstruction is executed per 1 clock cycle, when "enable" then
-- it is executed per 1 machine cycle (TPB is the end of the cycle)
sync <= '1' when (cnt8 = "111") else '0';
UCLK <= not(cycle_uc) when (reg_trace(8) = '1') else CLOCK;
--UCLK <= not(cnt8(2)) when (reg_trace(8) = '1') else CLOCK;

-- control unit
cpu_uinstruction <= cpu_microcode(to_integer(unsigned(ui_address)));
-- when executing 68XX, reg_extend is 1 so op-codes are 100 to 1FF
cpu_instructionstart <= cpu_mapper(to_integer(unsigned(reg_extend & reg_in)));

-- "switch statement" for 8 possible combinations of DMA and INT states
seq_else <= ("0001" & reg_dma & reg_int & '1') when (to_integer(unsigned(cpu_seq_cond)) = seq_cond_continue_sw) else cpu_seq_else;

cu: cpu_control_unit
		generic map (
			CODE_DEPTH => CODE_ADDRESS_WIDTH,
			IF_WIDTH => CODE_IF_WIDTH
		)
		port map (
			-- inputs
			reset => mode_reset,
			clk => UCLK,
			seq_cond => cpu_seq_cond,
			seq_then => cpu_seq_then,
			seq_else => seq_else,	-- see "switch" above
			seq_fork => cpu_instructionstart,
			cond(seq_cond_true) => '1',
			cond(seq_cond_mode_1805) => mode_1805,
			cond(seq_cond_sync) => sync,	
			cond(seq_cond_cond_3X) => reg_n(3) xor cond_3X,	
			cond(seq_cond_cond_4) => '1',	-- NC
			cond(seq_cond_cond_5) => '1',	-- NC
			cond(seq_cond_continue) => continue,
			cond(seq_cond_continue_sw) => continue,		-- HACKHACK!!! this drives the "swich statement" hooked up to else
			cond(seq_cond_cond_8) => '1', -- NC		
			cond(seq_cond_externalInt) => '0',				-- TODO
			cond(seq_cond_counterInt) => '0',				-- TODO
			cond(seq_cond_alu16_zero) => alu16_is_zero,	-- TODO?
			cond(seq_cond_cond_CX) => reg_n(3) xor cond_CX,			
			cond(seq_cond_traceEnabled) => traceEnabled,
			cond(seq_cond_traceReady) => traceReady,		
			cond(seq_cond_false) => '0',
			-- outputs
			ui_nextinstr => ui_nextinstr, -- NEXT microinstruction to be executed
			ui_address => ui_address	-- address of CURRENT microinstruction

		);

-- processor condition codes driven directly from instruction register
d_is_zero <= '1' when (reg_d = X"00") else '0';
 
with reg_n(2 downto 0) select
	cond_3X <=	'1'			when "000",	-- BR/SKP
					reg_q			when "001",	-- BQ/BNQ
					d_is_zero 	when "010", -- BZ/BNZ
					reg_df		when "011",	-- BDF/BNF
					reg_ef(0)	when "100",	-- B1/BN1
					reg_ef(1)	when "101",	-- B2/BN2
					reg_ef(2)	when "110",	-- B3/BN3
					reg_ef(3)	when "111";	-- B4/BN4

with reg_n(2 downto 0) select
	cond_CX <= 	'1'				when "000", -- LBR/LSKP
					reg_q				when "001",	-- LBQ/LBNQ
					d_is_zero		when "010", -- LBZ/LBNZ
					reg_df			when "011",	-- LBDF/LBNF
					not(reg_mie)	when "100",	-- NOP/LSIE (note that NOP will not use it)
					not(reg_q)		when "101",	-- LSNQ/LSQ
					not(d_is_zero) when "110", -- LSNZ/LSZ
					not(reg_df) 	when "111";	-- LSNF/LSDF
	
-- update D (data == accumulator) register
update_d: process(UCLK, cpu_reg_d, alu_y, reg_df)
begin
	if (rising_edge(UCLK)) then
		case cpu_reg_d is
			when reg_d_alu_y =>
				reg_d <= alu_y;
			when reg_d_shift_dn_df =>
				reg_d <= reg_df & reg_d(7 downto 1);
			when reg_d_shift_dn_0 =>
				reg_d <= '0' & reg_d(7 downto 1);
			when others =>
				null;
		end case;
	end if;
end process;

-- update DF (data flag == carry) register
update_df: process(UCLK, cpu_reg_df, alu_cout, reg_d)
begin
	if (rising_edge(UCLK)) then
		case cpu_reg_df is
			when reg_df_d_msb =>
				reg_df <= reg_d(7);
			when reg_df_d_lsb =>
				reg_df <= reg_d(0);
			when reg_df_alu_cout =>
				reg_df <= alu_cout;
			when others =>
				null;
		end case;
	end if;
end process;

-- update T (temporary) register
update_t: process(UCLK, cpu_reg_t, alu_y, reg_x, reg_p, reg_in)
begin
	if (rising_edge(UCLK)) then
		case cpu_reg_t is
			when reg_t_alu_y =>
				reg_t <= alu_y;
			when reg_t_xp =>
				reg_t <= reg_x & reg_p;
			when reg_t_in =>
				reg_t <= reg_in;
			when others =>
				null;
		end case;
	end if;
end process;

-- update B (ALU AUX) register
update_b: process(UCLK, cpu_reg_b, alu_y, reg_t, reg_df, reg_d)
begin
	if (rising_edge(UCLK)) then
		case cpu_reg_b is
			when reg_b_alu_y =>
				reg_b <= alu_y;
			when reg_b_t =>
				reg_b <= reg_t;
			when reg_b_df_d_dn =>
				reg_b <= reg_df & reg_d(7 downto 1);
			when others =>
				null;
		end case;
	end if;
end process;

-- update X (index pointer) register
update_x: process(UCLK, cpu_reg_x, alu_y, reg_n, reg_p)
begin
	if (rising_edge(UCLK)) then
		case cpu_reg_x is
			when reg_x_alu_yhi =>
				reg_x <= alu_y(7 downto 4);
			when reg_x_n =>
				reg_x <= reg_n;
			when reg_x_p =>
				reg_x <= reg_p;
			when others =>
				null;
		end case;
	end if;
end process;

-- update P (program counter pointer) register
update_p: process(UCLK, cpu_reg_p, alu_y, reg_n)
begin
	if (rising_edge(UCLK)) then
		case cpu_reg_p is
			when reg_p_alu_ylo =>
				reg_p <= alu_y(3 downto 0);
			when reg_p_n =>
				reg_p <= reg_n;
			when others =>
				null;
		end case;
	end if;
end process;

-- update IN (instruction) register
update_in: process(UCLK, cpu_reg_in, alu_y)
begin
	if (rising_edge(UCLK)) then
		case cpu_reg_in is
			when reg_in_alu_y =>
				reg_in <= alu_y;
			when others =>
				null;
		end case;
	end if;
end process;

-- update Q register
update_q: process(UCLK, cpu_reg_q)
begin
	if (rising_edge(UCLK)) then
		case cpu_reg_q is
			when reg_q_zero =>
				reg_q <= '0';
			when reg_q_one =>
				reg_q <= '1';
			when others =>
				null;
		end case;
	end if;
end process;

-- update MIE (master interrupt enable) register
update_mie: process(UCLK, cpu_reg_mie)
begin
	if (rising_edge(UCLK)) then
		case cpu_reg_mie is
			when reg_mie_enable =>
				reg_mie <= '1';
			when reg_mie_disable =>
				reg_mie <= '0';
			when others =>
				null;
		end case;
	end if;
end process;

-- update EXTEND register (it is '1' when executing 68XX extended opcodes, this also puts ALU in BCD mode!)
update_extend: process(UCLK, cpu_reg_extend)
begin
	if (rising_edge(UCLK)) then
		case cpu_reg_extend is
			when reg_extend_zero =>
				reg_extend <= '0';
			when reg_extend_one =>
				reg_extend <= '1';
			when others =>
				null;
		end case;
	end if;
end process;

-- Register array data path
with cpu_sel_reg select
		sel_reg <= 	X"0" when sel_reg_zero,
						X"1" when sel_reg_one,
						X"2" when sel_reg_two,
						reg_x when sel_reg_x,
						reg_n when sel_reg_n,
						reg_p when sel_reg_p,
						sel_reg when others;

reg_y <= reg_r(to_integer(unsigned(sel_reg)));

update_r: process(UCLK, cpu_reg_r, reg_r, sel_reg, reg_b, reg_t, alu_y, alu16_y)
begin
	if (rising_edge(UCLK)) then
		case cpu_reg_r is
			when reg_r_zero =>
				reg_r(to_integer(unsigned(sel_reg))) <= X"0000";
			when reg_r_r_plus_one =>
				reg_r(to_integer(unsigned(sel_reg))) <= std_logic_vector(unsigned(reg_y) + 1);
			when reg_r_r_minus_one =>
				reg_r(to_integer(unsigned(sel_reg))) <= std_logic_vector(unsigned(reg_y) - 1);
			when reg_r_yhi_rlo =>
				reg_r(to_integer(unsigned(sel_reg))) <= alu_y & reg_lo;
			when reg_r_rhi_ylo =>
				reg_r(to_integer(unsigned(sel_reg))) <= reg_hi & alu_y;
			when reg_r_b_t =>
				reg_r(to_integer(unsigned(sel_reg))) <= reg_b & reg_t;
			when others =>
				null;
		end case;
	end if;
end process;

alu16_is_zero <= '1' when (reg_y = X"0000") else '0';

-- ALU data path
with cpu_alu_r select
		r <= 	reg_t 	when alu_r_t,
				reg_d 	when alu_r_d,
				reg_b 	when alu_r_b,
				reg_hi 	when alu_r_reg_hi;		-- R(sel_reg).1	TODO

with cpu_alu_s select
		s <= 	data_in	when alu_s_bus,			-- data bus input
				reg_d 	when alu_s_d,
				cpu_seq_else when alu_s_const,	-- "constant" is reused else field
				reg_lo 	when alu_s_reg_lo;		-- R(sel_reg).0	TODO
			
with cpu_alu_cin select
		alu_cin <= 	cpu_alu_f(1) or cpu_alu_f(0) when alu_cin_f1_or_f0, -- this will be 0 for add (no carry) and 1 for substract (no borrow)
						reg_df when alu_cin_df;
			
adder_lo: nibbleadder Port map ( 
				cin => alu_cin,
				a => r(3 downto 0),
				b => s(3 downto 0),
				na => cpu_alu_f(1),
				nb =>	cpu_alu_f(0),
				bcd => reg_extend,	-- all 68XX add/sub is in BCD mode
				y => add_y(3 downto 0),
				cout => cout
			);

adder_hi: nibbleadder Port map ( 
				cin => cout,
				a => r(7 downto 4),
				b => s(7 downto 4),
				na => cpu_alu_f(1),
				nb =>	cpu_alu_f(0),
				bcd => reg_extend,
				y => add_y(7 downto 4),
				cout => alu_cout
			);

with cpu_alu_f select
		alu_y <= r xor s 	when alu_f_xor,
					r and s 	when alu_f_and,
					r or s	when alu_f_ior,
					r			when alu_f_pass_r,
					add_y		when alu_f_r_plus_s,
					add_y		when alu_f_r_plus_ns,
					add_y		when alu_f_nr_plus_s,
					s			when alu_f_pass_s;
					
-- DEBUG UNIT					
-- hex debug output
with hexSel select
	hexOut <= 	ui_nextinstr(3 downto 0) when "000",
					ui_nextinstr(7 downto 4) when "001",
					ui_address(3 downto 0)	when "010",
					ui_address(7 downto 4) when "011",
					reg_n	when "100",
					reg_i	when "101",
					--data_in(3 downto 0) when "100",
					--data_in(7 downto 4) when "101",
					reg_ef when "110",
					nEF4 & nEF3 & nEF2 & nEF1 when "111";
--	hexOut <= 	cpu_seq_else(3 downto 0) when "000",
--					cpu_seq_else(7 downto 4) when "001",
--					cpu_seq_then(3 downto 0)	when "010",
--					cpu_seq_then(7 downto 4) when "011",
--					ui_address(3 downto 0) when "100",
--					ui_address(7 downto 4) when "101",
--					X"0" when "110",
--					X"0" when "111";

-- tracer
-- tracer works by sending ascii characters to TTY type output device, such as simple text display or serial
-- there is a protocol both need to follow:
-- 1. CPU outputs 0 to tracer port, DEVICE detects 0, does not nothing but asserts traceReady = 1
-- 2. CPU outputs ascii to tracer port, DEVICE detects != 0, starts displaying the char, traceReady = 0 indicating busy
-- 3. CPU waits until traceReady = 1
-- 4. goto step 1

with cpu_seq_else(3 downto 0) select
	hexTrace <= reg_t(3 downto 0)		when "0000",
					reg_t(7 downto 4) 	when "0001",
					"000" & reg_df 		when "0010",	
					"000" & reg_mie 		when "0011",	-- TODO: add other interrupt enable flags here
					reg_b(3 downto 0)		when "0100",
					reg_b(7 downto 4) 	when "0101",
					reg_d(3 downto 0)		when "0110",
					reg_d(7 downto 4) 	when "0111",
					reg_n						when "1000",
					reg_i						when "1001",
					reg_lo(3 downto 0)	when "1010",
					reg_lo(7 downto 4) 	when "1011",
					reg_hi(3 downto 0)	when "1100",
					reg_hi(7 downto 4) 	when "1101",
					reg_p						when "1110",
					reg_x						when "1111";
					
asciiBase <= X"30" when (hexTrace(3) = '0' or (hexTrace = X"8") or (hexTrace = X"9")) else X"37";
asciiOffs <= X"0" & hexTrace;
					
traceOut <= reg_trace(7 downto 0); -- reg_trace(8) can be used internally to enable/disable single stepping
-- update TRACER register
update_tracer: process(UCLK, cpu_reg_trace, cpu_seq_else)
begin
	if (rising_edge(UCLK)) then
		case cpu_reg_trace is
			when reg_trace_ss_enable_zero =>		-- enable single stepping, no char to trace
				reg_trace <= "100000000";
			when reg_trace_ss_disable_zero =>	-- disable single stepping, no char to trace
				reg_trace <= "000000000";
			when reg_trace_ss_disable_char =>	-- disable single stepping, ascii char to trace
				if (cpu_seq_else(7) = '0') then
					reg_trace <= '0' & cpu_seq_else;	-- ascii char is in the microcode
				else
					--reg_trace <= '0' & hex2char(to_integer(unsigned(hexTrace)));
					reg_trace <= '0' & std_logic_vector(unsigned(asciiBase) + unsigned(asciiOffs));
				end if;
			when others =>
				null;
		end case;
	end if;
end process;
 		
end Behavioral;

