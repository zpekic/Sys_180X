----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:00:49 06/07/2020 
-- Design Name: 
-- Module Name:    uart_receiver - Behavioral 
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

entity uart_receiver is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           din : in  STD_LOGIC;
           dout : out  STD_LOGIC_VECTOR (7 downto 0);
           dout_frame : out  STD_LOGIC;
           dout_valid : out  STD_LOGIC);
end uart_receiver;

architecture Behavioral of uart_receiver is

component serialreceiver is
    Port ( reset : in  STD_LOGIC;
			  discard: in STD_LOGIC;
           clk : in  STD_LOGIC;
           din : in  STD_LOGIC;
           dout : out  STD_LOGIC_VECTOR (7 downto 0);
           dout_frame : out  STD_LOGIC;
           dout_valid : out STD_LOGIC);
end component;

signal data: std_logic_vector(15 downto 0);
signal frame, valid: std_logic_vector(1 downto 0);

begin

s_to_p0: serialreceiver Port map ( 
				reset => reset,
				discard => frame(1),
				clk => clk,
				din => din,
				dout => data(7 downto 0),
				dout_frame => frame(0),
				dout_valid => valid(0)
			);

s_to_p1: serialreceiver Port map ( 
				reset => reset,
				discard => frame(0),
				clk => not clk,
				din => din,
				dout => data(15 downto 8),
				dout_frame => frame(1),
				dout_valid => valid(1)
			);


dout_frame <= frame(1) or frame(0);

with frame select
	dout <= 	X"21" when "00", -- "!" for debug only
				data(7 downto 0) when "01",
				data(15 downto 8) when "10",
				X"3F" when "11";	-- "?" for debug only
				
with frame select
	dout_valid <= '1' when "00",
				valid(0) when "01",
				valid(1) when "10",
				'1' when "11";

end Behavioral;

