----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:26:27 05/03/2020 
-- Design Name: 
-- Module Name:    io_port - Behavioral 
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

entity io_port is
    Port ( 	clk: in STD_LOGIC;
				nMRD : in  STD_LOGIC;
				nMWR : in  STD_LOGIC;
				N : in  STD_LOGIC_VECTOR (2 downto 0);
				DBUS : inout  STD_LOGIC_VECTOR (7 downto 0);
				sel : in  STD_LOGIC_VECTOR (2 downto 0);
				input : in  STD_LOGIC_VECTOR (7 downto 0);
				data : buffer  STD_LOGIC_VECTOR (7 downto 0));
end io_port;

architecture Behavioral of io_port is

signal enable: std_logic;

begin

enable <= '1' when (sel = N) else '0';

-- read port data to bus in order to write to memory
DBUS <= input when (enable = '1' and nMWR = '0') else "ZZZZZZZZ";

-- update port data
update: process(clk, DBUS, input, enable)
begin
	if (rising_edge(clk)) then
		-- data coming from memory
		if (nMRD = '0' and enable = '1') then
			data <= DBUS;
		end if;
	end if;
end process;

-- 

end Behavioral;

