----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:56:00 11/12/2017 
-- Design Name: 
-- Module Name:    simpleram - Behavioral 
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

entity simpleram is
	 generic (
		address_size: positive := 16;
		default_value: STD_LOGIC_VECTOR(7 downto 0) := X"FF");
    Port (       
			  clk: in STD_LOGIC;
			  D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR ((address_size - 1) downto 0);
           nRead : in  STD_LOGIC;
           nWrite : in  STD_LOGIC;
           sel : in  STD_LOGIC);
end simpleram;

architecture Behavioral of simpleram is

-- test programs from http://www.sunrise-ev.com/1802.htm
signal rom: std_logic_vector(7 downto 0);

type mem64x8 is array(0 to 63) of std_logic_vector(7 downto 0);
signal ram: mem64x8 := (
	-- PROGRAM 2, BLINK Q SLOW
	X"F8",X"02",
	X"B2",
	X"22",
	X"92",
	X"3A",X"03",
	X"CD",
	X"7B",
	X"38",
	X"7A",
	X"30",X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	-- PROGRAM 3, READ SWITCHES AND DISPLAY VALUES IN LEDS
	X"E1",
	X"90",
	X"B1",
	X"F8",X"13",
	X"A1",
	X"6C",
	X"64",
	X"CD",
	X"7B",
	X"38",
	X"7A",
	X"FF",X"01",
	X"3A",X"0C",
	X"7A",
	X"30",X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00",
	X"00"
);

begin

	-- Read path
	D <= ram(to_integer(unsigned(A(5 downto 0)))) when (sel = '1' and nRead = '0') else "ZZZZZZZZ";
	
	-- Write path
	update_ram: process(ram, sel, nWrite, clk)
	begin
		if (rising_edge(clk)) then
			if (nWrite = '0' and sel = '1') then
				ram(to_integer(unsigned(A(5 downto 0)))) <= D;
			end if;
		end if;
	end process;

end Behavioral;

