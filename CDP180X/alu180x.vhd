----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:30:10 04/25/2020 
-- Design Name: 
-- Module Name:    alu180x - Behavioral 
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

entity alu180x is
    Port ( cin : in  STD_LOGIC;
           r : in  STD_LOGIC_VECTOR (7 downto 0);
           s : in  STD_LOGIC_VECTOR (7 downto 0);
           f : in  STD_LOGIC_VECTOR (3 downto 0);
           alu_y : out  STD_LOGIC_VECTOR (7 downto 0);
           alu_cout : out  STD_LOGIC);
end alu180x;

architecture Behavioral of alu180x is

begin


end Behavioral;

