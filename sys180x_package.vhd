--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
package sys180x_package is

constant tab: character := character'val(9);

-- basic colors (BBGGGRRR)
constant color8_black : std_logic_vector(7 downto 0) := "00000000"; 
constant color8_red	 : std_logic_vector(7 downto 0) := "00000111"; 
constant color8_green : std_logic_vector(7 downto 0) := "00111000"; 
constant color8_yellow: std_logic_vector(7 downto 0) := "00111111"; 
constant color8_blue	 : std_logic_vector(7 downto 0) := "11000000"; 
constant color8_purple: std_logic_vector(7 downto 0) := "11000111"; 
constant color8_cyan	 : std_logic_vector(7 downto 0) := "11111000"; 
constant color8_white : std_logic_vector(7 downto 0) := "11111111"; 

type lookup is array(0 to 15) of std_logic_vector(7 downto 0);
constant hex2char: lookup := (
	std_logic_vector(to_unsigned(natural(character'pos('0')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('1')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('2')), 8)), 	
	std_logic_vector(to_unsigned(natural(character'pos('3')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('4')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('5')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('6')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('7')), 8)),
	std_logic_vector(to_unsigned(natural(character'pos('8')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('9')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('A')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('B')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('C')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('D')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('E')), 8)),	
	std_logic_vector(to_unsigned(natural(character'pos('F')), 8))
);

impure function char2hex(char: in character) return integer is
begin
	case char is
		when '0' to '9' =>
			return character'pos(char) - character'pos('0');
		when 'a' to 'f' =>
			return character'pos(char) - character'pos('a') + 10;
		when 'A' to 'F' =>
			return character'pos(char) - character'pos('A') + 10;
		when others =>
			assert false report "char2hex(): unexpected character '" & char & "'" severity failure;
	end case;
	return 0;
end char2hex;

impure function get_string(value: in unsigned; len: in integer; base: in integer) return string is
	variable str: string(1 to 8) := "????????"; 
	variable m, d: integer;
	
begin
	d := to_integer(value);
	
	for i in 0 to len - 1 loop
		m := d mod base;
		d := d / base;
		case m is
			when 0 => str(8 - i) := '0';
			when 1 => str(8 - i) := '1';
			when 2 => str(8 - i) := '2';
			when 3 => str(8 - i) := '3';
			when 4 => str(8 - i) := '4';
			when 5 => str(8 - i) := '5';
			when 6 => str(8 - i) := '6';
			when 7 => str(8 - i) := '7';
			when 8 => str(8 - i) := '8';
			when 9 => str(8 - i) := '9';
			when 10 => str(8 - i) := 'A';
			when 11 => str(8 - i) := 'B';
			when 12 => str(8 - i) := 'C';
			when 13 => str(8 - i) := 'D';
			when 14 => str(8 - i) := 'E';
			when 15 => str(8 - i) := 'F';
			when others =>
				assert false report "get_string() reached unexpected case m =" & integer'image(m) severity failure; 
		end case;
	end loop;
	
	return str(8 - len + 1 to 8);
	
end get_string;

impure function parseBinary8(bin_str: in string) return std_logic_vector is
	variable val: std_logic_vector(7 downto 0) := "00000000";
begin
	--report "parseBinary8(" & bin_str & ")" severity note;
	for i in bin_str'left to bin_str'right loop
		case bin_str(i) is
			when '0' =>
				val := val(6 downto 0) & "0";
			when '1'|'X' => -- interpret X as '1' due to bus signal being low active - this way is undefined microinstruction is executed, bus won't short!
				val := val(6 downto 0) & "1";
			when others =>
				assert false report "parseBinary8(): unexpected character '" & bin_str(i) & "'" severity failure;
		end case;
	end loop;

	return val;
end parseBinary8;

impure function parseBinary16(bin_str: in string) return std_logic_vector is
begin
	--report "parseBinary16(" & bin_str & ")" severity note;
	return parseBinary8(bin_str(1 to 8)) & parseBinary8(bin_str(9 to 16));
end parseBinary16;

impure function parseHex16(hex_str: in string) return std_logic_vector is
	variable intVal: integer := 0;
begin
	--report "parseHex16(" & hex_str & ")" severity note;
	
	for i in hex_str'left to hex_str'right loop
		intVal := 16 * intVal + char2hex(hex_str(i));
	end loop;
	return std_logic_vector(to_unsigned(intVal, 16));
end parseHex16;

end sys180x_package;
