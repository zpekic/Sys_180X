----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:43:00 06/17/2019 
-- Design Name: 
-- Module Name:    xyram - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity xyram is
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
end xyram;

architecture Behavioral of xyram is

type lookup is array(0 to 127) of std_logic_vector(15 downto 0);

impure function init_lookup(offset: in integer) return lookup is
variable temp_mem : lookup;
variable i: integer range 0 to 127;

begin
	-- fill with constant multiply table
	for i in 0 to 127 loop	
			temp_mem(i) := std_logic_vector(to_unsigned(i * offset, 16));
	end loop;

   return temp_mem;
	
end init_lookup;

signal row_offset: lookup := init_lookup(maxcol);

type generic_ram is array(0 to (maxram - 1)) of std_logic_vector(7 downto 0);
signal vram: generic_ram := (others => X"2E"); -- .
attribute ram_style: string;
attribute ram_style of vram : signal is "block";

signal mem_signal, ro_signal, rw_signal: std_logic_vector(15 downto 0);
alias mem_wr: std_logic is mem_signal(15);
alias mem_rd: std_logic is mem_signal(14);
alias mem_y: std_logic_vector(6 downto 0) is mem_signal(13 downto 7); 
alias mem_x: std_logic_vector(6 downto 0) is mem_signal(6 downto 0);
signal address: integer range 0 to maxram - 1;
signal row, col: std_logic_vector(15 downto 0);
 
begin

-- main mux
ro_signal <= '0'		& ro_rd	& ro_y(6 downto 0) & ro_x(6 downto 0); 	-- from controller
rw_signal <= rw_wr	& rw_rd	& rw_y(6 downto 0) & rw_x(6 downto 0); 	-- from tracer
mem_signal <= rw_signal when ((rw_wr or rw_rd) = '1') else ro_signal;
row <= row_offset(to_integer(unsigned(mem_y)));
col <= "000000000" & mem_x;
address <= to_integer(unsigned(row)) + to_integer(unsigned(col));

-- read path
dout <= vram(address) when (mem_rd = '1') else "ZZZZZZZZ";

-- write path
update_vram: process(vram, clk, mem_wr)
begin
	if (rising_edge(clk) and mem_wr = '1') then
		vram(address) <= din;
	end if;
end process;

end Behavioral;

