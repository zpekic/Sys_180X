----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:08:25 12/07/2019 
-- Design Name: 
-- Module Name:    rom16k16 - Behavioral 
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
use work.eprom_pack;

entity rom16k16 is
    Port ( A : in  STD_LOGIC_VECTOR (13 downto 0);
           nRead : in  STD_LOGIC;
           nSelect : in  STD_LOGIC;
           D : out  STD_LOGIC_VECTOR (15 downto 0));
end rom16k16;

architecture Behavioral of rom16k16 is

begin
	-- MSB is even byte
	-- LSB is odd byte
	D <= eprom_rom(to_integer(unsigned(A & '0'))) & eprom_rom(to_integer(unsigned(A & '1'))) when (nRead = '0' and nSelect = '0') else "ZZZZZZZZZZZZZZZZ";

end Behavioral;

