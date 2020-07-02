----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:13:30 06/07/2020 
-- Design Name: 
-- Module Name:    serialreceiver - Behavioral 
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

entity serialreceiver is
    Port ( reset : in  STD_LOGIC;
			  discard: in STD_LOGIC;
           clk : in  STD_LOGIC;
           din : in  STD_LOGIC;
           dout : out  STD_LOGIC_VECTOR (7 downto 0);
           dout_frame : buffer  STD_LOGIC;
           dout_valid : buffer  STD_LOGIC);
end serialreceiver;

architecture Behavioral of serialreceiver is

signal s0, s1, shifter: std_logic_vector(11 downto 0);
signal sel: std_logic;

begin

-- hard-coded to 8N1
shifter <= s0 when (sel = '0') else s1;
dout <= shifter(1) & shifter(2) & shifter(3) & shifter(4) & shifter(5) & shifter(6) & shifter(7) & shifter(8);
dout_frame <= shifter(0) and (not shifter(9));
dout_valid <= dout_frame; -- TODO: frame and valid same only because there is no parity check

ser2par: process(reset, discard, dout_frame, clk, shifter, din)
begin
	if (reset = '1' or discard = '1') then
		if (reset = '1' or (discard and (not sel)) = '1') then
			s0 <= (others => '1');
		end if;
		if (reset = '1' or (discard and sel) = '1') then
			s1 <= (others => '1');
		end if;
	else
		if (rising_edge(clk)) then
			if (sel = '1') then
				s0 <= (others => '1');
				s1 <= s1(10 downto 0) & din;
			else
				s0 <= s0(10 downto 0) & din;
				s1 <= (others => '1');
			end if;
			if (dout_frame = '1') then
				sel <= not sel;
			end if;
		end if;
	end if;
end process;

end Behavioral;

