library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Position is
	port (
		clk, nrst: in std_logic;
		new_direction : in std_logic_vector(3 downto 0);  -- Code of the BCD pressed
		key_read: in std_logic;  -- signal from the register bank that tells when a Keypad key has been pressed.
		
		racket_Y_VGA: out std_logic_vector(9 downto 0)	-- Position Y of the racket (top left vertex): 0-479						  
		);
end position;


architecture main of Position is
	type state_type is (pr_Wait);

	-- Definition of the state register
	
	signal state : state_type;
	
	-- Definition of the registers in the process unit

	signal pos_Y_i : integer range 0 to 511; -- Registered Position to trasmit.
	
begin

PROTOCOL_FSM : process (clk, nrst) begin
	if nrst = '0' then
		state <= pr_Wait;
		pos_Y_i <= 240; --480/2=240, half of Y position.
		racket_Y_VGA <= std_logic_vector(to_unsigned(pos_Y_i, 10));
		
	elsif clk'EVENT and clk = '1' then
		case state is
			
			when pr_Wait =>
				if (key_read = '1' and new_direction = x"2" and pos_Y_i > 0) then 
					pos_Y_i <= pos_Y_i - 10;
					racket_Y_VGA <= std_logic_vector(to_unsigned(pos_Y_i, 10));
					state <= pr_Wait;
				elsif (key_read = '1' and new_direction = x"8" and pos_Y_i < 415) then  -- Racket is 64 then: 479-64=415
					pos_Y_i <= pos_Y_i + 10;
					racket_Y_VGA <= std_logic_vector(to_unsigned(pos_Y_i, 10));
					state <= pr_Wait;  
				else state <= pr_Wait; 
				end if;
						
			when others =>
				end case;
	end if;
end process;

end;