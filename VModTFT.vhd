----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:14:48 09/08/2018 
-- Design Name: 
-- Module Name:    VModTFT - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: http://www.wmelectronic.at/PDFS/digilent/VmodTFT_rm.pdf
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

entity VModTFT is
    Port ( Reset : in  STD_LOGIC;
           Clk : in  STD_LOGIC;
			  din: in STD_LOGIC_VECTOR (7 downto 0);
           hactive : buffer  STD_LOGIC;
           vactive : buffer  STD_LOGIC;
           x : out  STD_LOGIC_VECTOR (7 downto 0);
           y : out  STD_LOGIC_VECTOR (7 downto 0);
			  cursor_enable : in  STD_LOGIC;
			  cursor_type : in  STD_LOGIC;
			  display_blank: in STD_LOGIC;
			  -- TFT connections
           TFT_R : out STD_LOGIC_VECTOR (7 downto 0);
           TFT_G : out STD_LOGIC_VECTOR (7 downto 0);
           TFT_B : out STD_LOGIC_VECTOR (7 downto 0);
           TFT_CLK : out  STD_LOGIC;
           TFT_DE : out STD_LOGIC;
			  TFT_DISP: out STD_LOGIC;
           TFT_BKLT : out  STD_LOGIC;
           TFT_VDDEN : out  STD_LOGIC
          );
end VModTFT;

architecture Behavioral of VModTFT is

component chargen_rom is
    Port ( a : in  STD_LOGIC_VECTOR (10 downto 0);
           d : out  STD_LOGIC_VECTOR (7 downto 0));
end component;

signal divide_cnt: integer range 0 to 15;
signal disp_cnt: integer range 0 to 31;
signal pixel_clk: std_logic;
signal pixel, reverse: std_logic;
signal pattern: std_logic_vector(7 downto 0);
signal pixel_color: std_logic_vector(23 downto 0);

signal col_cnt: std_logic_vector(11 downto 0);
alias  line_clk: std_logic is col_cnt(11);
constant col_start: std_logic_vector(11 downto 0) := X"FD3"; 	-- 45 cols will be blank signal
constant col_end:	std_logic_vector(11 downto 0) := X"1DF";		-- 480 rows will be displayed

signal row_cnt: std_logic_vector(11 downto 0);
alias  frame_clk: std_logic is row_cnt(11);
constant row_start: std_logic_vector(11 downto 0) := X"FF0"; 	-- 16 rows will be blank signal
constant row_end:	std_logic_vector(11 downto 0) := X"10F";		-- 272 rows will be displayed

begin

-- generate Pixel clock (100MHz / 7 / 2 ~= 7.14MHz)
TFT_CLK <= pixel_clk;

generate_pixel_clock: process(Reset, Clk)
begin
	if (Reset = '1') then
		pixel_clk <= '0';
		divide_cnt <= 0;
	else
		if (rising_edge(Clk)) then
			if (divide_cnt = 6) then
				pixel_clk <= not pixel_clk;
			else
				divide_cnt <= divide_cnt + 1;
			end if;
		end if;
	end if;
end process;

-- generate columns
x <= col_cnt(10 downto 3);
hactive <= not (col_cnt(11)); -- or display_blank);

generate_col: process(Reset, pixel_clk)
begin
	if (Reset = '1') then
		col_cnt <= col_start;
	else
		if (rising_edge(pixel_clk)) then
			if (col_cnt = col_end) then
				col_cnt <= col_start;
			else
				col_cnt <= std_logic_vector(unsigned(col_cnt) + 1);
			end if;
		end if;
	end if;
end process;

-- generate rows
y <= row_cnt(10 downto 3);
vactive <= not (row_cnt(11)); -- or display_blank);

generate_row: process(Reset, line_clk)
begin
	if (Reset = '1') then
		row_cnt <= row_start;
	else
		if (rising_edge(line_clk)) then
			if (row_cnt = row_end) then
				row_cnt <= row_start;
			else
				row_cnt <= std_logic_vector(unsigned(row_cnt) + 1);
			end if;
		end if;
	end if;
end process;

-- generate DISP
generate_disp: process(Reset, frame_clk)
begin
	if (Reset = '1') then
		disp_cnt <= 20;
		TFT_DISP <= '0';
		TFT_VDDEN <= '0';
	else
		if (rising_edge(frame_clk)) then
			if (disp_cnt = 0) then
				TFT_DISP <= '1';
				TFT_VDDEN <= '1';
			else
				disp_cnt <= disp_cnt - 1;
				TFT_DISP <= '0';
				TFT_VDDEN <= '0';
			end if;
		end if;
	end if;
end process;

-- other signals
--TFT_VDDEN <= '1'; -- not sure what is this for, so safer to leave it on :-)	 
TFT_BKLT <= not Display_blank; -- turn off backlight when display is blanked	 
--Pixel_read <= '0' when (Display_blank = '1') else not (row_cnt(11) or col_cnt(11)); -- need memory only when both x >= 0 and y >= 0 and display is not blanked
TFT_DE <= not (row_cnt(11) or col_cnt(11)); -- when both x >= 0 and y >= 0

-- pixel path
reverse <= cursor_enable and ((cursor_type and row_cnt(2) and row_cnt(1)) or (not cursor_type));

chargen: chargen_rom port map (
		a(10) => (din(7) xor reverse),			-- invert the pattern based on cursor / char code 128-255
		a(9 downto 3) => din(6 downto 0),		-- 128 chars
		a(2 downto 0) => row_cnt(2 downto 0),	-- 8 rows per char
		d => pattern
	);
	
with col_cnt(2 downto 0) select
	pixel <= pattern(7) when "000",
				pattern(6) when "001",
				pattern(5) when "010",
				pattern(4) when "011",
				pattern(3) when "100",
				pattern(2) when "101",
				pattern(1) when "110",
				pattern(0) when "111";
				
pixel_color <= X"FFFFFF" when (pixel = '1') else X"00FF00"; -- hard code white on green

TFT_R <= pixel_color(23 downto 16);
TFT_G <= pixel_color(15 downto 8);
TFT_B <= pixel_color(7 downto 0);
				
end Behavioral;

