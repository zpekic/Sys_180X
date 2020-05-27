----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:24:08 04/03/2019 
-- Design Name: 
-- Module Name:    mux11x4 - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mux11x4 is
    Port ( e : in  STD_LOGIC_VECTOR (10 downto 0);
           x : in  STD_LOGIC_VECTOR (43 downto 0);
           y : out  STD_LOGIC_VECTOR (3 downto 0));
end mux11x4;

architecture Behavioral of mux11x4 is

--signal s10, s9, s8, s7, s6, s5, s4, s3, s2, s1, s0: std_logic_vector(3 downto 0);
--signal s: std_logic_vector(3 downto 0);

begin

mux_generate: for i in 0 to 3 generate
begin
	y(i) <= 	(e(10) or x(40 + i)) and 
				(e(9) or x(36 + i)) and
				(e(8) or x(32 + i)) and
				(e(7) or x(28 + i)) and
				(e(6) or x(24 + i)) and
				(e(5) or x(20 + i)) and
				(e(4) or x(16 + i)) and
				(e(3) or x(12 + i)) and
				(e(2) or x(8 + i)) and
				(e(1) or x(4 + i)) and
				(e(0) or x(0 + i));
end generate;

--with e select
--	y <=	x(43 downto 40) when "01111111111",
--			x(39 downto 36) when "X0111111111",
--			x(35 downto 32) when "XX011111111",
--			x(31 downto 28) when "XXX01111111",
--			x(27 downto 24) when "XXXX0111111",
--			x(23 downto 20) when "XXXXX011111",
--			x(19 downto 16) when "XXXXXX01111",
--			x(15 downto 12) when "XXXXXXX0111",
--			x(11 downto  8) when "XXXXXXXX011",
--			x( 7 downto  4) when "XXXXXXXXX01",
--			x( 3 downto  0) when "XXXXXXXXXX0",
--			"0000" when others;

--s0 <= x( 3 downto  0) when e(0) = '0' else X"0";
--s1 <= x( 7 downto  4) when e(1) = '0' else X"0";
--s2 <= x(11 downto  8) when e(2) = '0' else X"0";
--s3 <= x(15 downto 12) when e(3) = '0' else X"0";
--s4 <= x(19 downto 16) when e(4) = '0' else X"0";
--s5 <= x(23 downto 20) when e(5) = '0' else X"0";
--s6 <= x(27 downto 24) when e(6) = '0' else X"0";
--s7 <= x(31 downto 28) when e(7) = '0' else X"0";
--s8 <= x(35 downto 32) when e(8) = '0' else X"0";
--s9 <= x(39 downto 36) when e(9) = '0' else X"0";
--s10 <= x(43 downto 40) when e(10) = '0' else X"0";
--
--y <= s10 or s9 or s8 or s7 or s6 or s5 or s4 or s3 or s2 or s1 or s0;
--
--s(3) <= not(e(10) and e(9) and e(8));
--s(2) <= not(e(7) and e(6) and e(5) and e(4));
--s(1) <= not(e(10) and e(7) and e(6) and e(3) and e(2));
--s(0) <= not(e(9) and e(7) and e(5) and e(3) and e(1));
--
--with s select
--	y <=	x(43 downto 40) when "1010", -- 10
--			x(39 downto 36) when "1001", -- 9
--			x(35 downto 32) when "1000", -- 8
--			x(31 downto 28) when "0111", -- 7
--			x(27 downto 24) when "0110", -- 6
--			x(23 downto 20) when "0101", -- 5
--			x(19 downto 16) when "0100", -- 4
--			x(15 downto 12) when "0011", -- 3
--			x(11 downto  8) when "0010", -- 2
--			x( 7 downto  4) when "0001", -- 1
--			x( 3 downto  0) when "0000", -- 0
--			X"0" when others;

--s(3) <= e(10) and e(9) and e(8);
--s(2) <= e(7) and e(6) and e(5) and e(4);
--s(1) <= e(10) and e(7) and e(6) and e(3) and e(2);
--s(0) <= e(9) and e(7) and e(5) and e(3) and e(1);
--
--with s select
--	y <=	x(43 downto 40) when "0101", -- 10
--			x(39 downto 36) when "0110", -- 9
--			x(35 downto 32) when "0111", -- 8
--			x(31 downto 28) when "1000", -- 7
--			x(27 downto 24) when "1001", -- 6
--			x(23 downto 20) when "1010", -- 5
--			x(19 downto 16) when "1011", -- 4
--			x(15 downto 12) when "1100", -- 3
--			x(11 downto  8) when "1101", -- 2
--			x( 7 downto  4) when "1110", -- 1
--			x( 3 downto  0) when "1111", -- 0
--			X"0" when others;

end Behavioral;

