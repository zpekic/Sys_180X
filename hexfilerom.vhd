----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:56:00 11/12/2017 
-- Design Name: 
-- Module Name:    hexfilerom - Behavioral 
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
use STD.textio.all;
use ieee.std_logic_textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use work.sys180x_package.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hexfilerom is
	 generic (
		filename: string := "";
		address_size: positive := 8;
		max_address: std_logic_vector(15 downto 0) := X"0000";
		default_value: STD_LOGIC_VECTOR(7 downto 0) := X"FF"); -- as if "empty EPROM"
    Port (           
			  clk: in STD_LOGIC;
			  D : out  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR ((address_size - 1) downto 0);
           nRead : in  STD_LOGIC;
           nSelect : in  STD_LOGIC);
end hexfilerom;

architecture Behavioral of hexfilerom is

type bytememory is array(0 to (2 ** address_size) - 1) of std_logic_vector(7 downto 0);

impure function init_filememory(file_name : in string; depth: in integer; default_value: std_logic_vector(7 downto 0); max_address: std_logic_vector(15 downto 0)) return bytememory is
variable temp_mem : bytememory;
variable i, addr_start, addr_end: integer range 0 to (depth - 1);
variable location: std_logic_vector(7 downto 0);
file input_file : text open read_mode is file_name;
variable input_line : line;
variable line_current: integer := 0;
variable address: std_logic_vector(15 downto 0);
variable byte_count, record_type, byte_value: std_logic_vector(7 downto 0);
variable firstChar: character;
variable count: integer;
variable isOk: boolean;
variable cnt_defaultinit: integer := 0;
variable cnt_valueinit: integer := 0;

begin
	-- fill with default value
	for i in 0 to depth - 1 loop	
			temp_mem(i) := default_value;
			cnt_defaultinit := cnt_defaultinit + 1;
	end loop;

	 -- parse the file for the data
	 -- format described here: https://en.wikipedia.org/wiki/Intel_HEX
	 assert false report file_name & ": loading up to " & integer'image(depth) & " bytes." severity note;
	 loop 
		line_current := line_current + 1;
      readline (input_file, input_line);
		exit when endfile(input_file); --till the end of file is reached continue.

		read(input_line, firstChar);
		if (firstChar = ':') then
			hread(input_line, byte_count);
			hread(input_line, address);
			hread(input_line, record_type);
			case record_type is
				when X"00" => -- DATA
					count := to_integer(unsigned(byte_count));
					if (count > 0) then
						addr_start := to_integer(unsigned(address));
						if (addr_start < to_integer(unsigned(max_address))) then
							addr_end := addr_start + to_integer(unsigned(byte_count)) - 1;
							report file_name & ": parsing line " & integer'image(line_current) & " for " & integer'image(count) & " bytes at address " & get_string(to_unsigned(addr_start, 16), 4, 16) severity note;
							for i in addr_start to addr_end loop
								hread(input_line, byte_value);
								if (i < depth) then
									temp_mem(i) := byte_value;
									cnt_valueinit := cnt_valueinit + 1;
								else
									report file_name & ": line " & integer'image(line_current) & " data beyond memory capacity ignored" severity failure;
								end if;
							end loop;
						else
							report file_name & ": parsing line " & integer'image(line_current) & " max address " & get_string(unsigned(max_address), 4, 16) & " reached" severity note;
						   exit;
						end if;
					else
						report file_name  & ": line " & integer'image(line_current) & " has no data" severity failure;
						exit;
					end if;
				when X"01" => -- EOF
					report file_name & ": line " & integer'image(line_current) & " eof record type detected" severity note;
					exit;
				when others =>
					report file_name & ": line " & integer'image(line_current) & " unsupported record type detected" severity failure;
					exit;
			end case;
		else
			report file_name & ": line " & integer'image(line_current) & " does not start with ':' " severity failure;
			exit;
		end if;
	end loop; -- next line in file

	assert false report file_name & " closing." severity note; 
	file_close(input_file);

	assert false report integer'image(cnt_defaultinit) & " bytes initialized to default of " & get_string(unsigned(default_value), 2, 16) & ", " & integer'image(cnt_valueinit) & " bytes overwritten with data" severity note;
   return temp_mem;
	
end init_filememory;

signal rom: bytememory := init_filememory(filename, 2 ** address_size, default_value, max_address);
signal data: std_logic_vector(7 downto 0);
--signal rom: bytememory := init_inlinememory(2 ** address_size, default_value);
--attribute rom_style : string;
--attribute rom_style of rom : signal is "block";

begin
	
capture: process(clk, rom)
begin
	if (rising_edge(clk)) then
		data <= rom(to_integer(unsigned(A)));
	end if;
end process;

D <=  data when (nRead = '0' and nSelect = '0') else "ZZZZZZZZ";

end Behavioral;

