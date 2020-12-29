library ieee;
use ieee.std_logic_1164.all;

entity register_bank is
	port (
		clk, nrst: in std_logic;
		bcd: in std_logic; --flag signal from the keyboard block (BCD key pressed) Active high.
		direction : in std_logic_vector(3 downto 0);  --Code of the key pressed by the user to go up or down (2 or 8)
	    
	    new_direction : out std_logic_vector(3 downto 0);  -- Code of the BCD pressed
		key_read : out std_logic;  -- ACK signal for the keyboard when a key has been read by this block
		bank_ready : out std_logic --The signal is active when the register bank is ready to be
								   --awakened and to store a new value.
		);
end register_bank;


architecture main of register_bank is
	type state_type is ( pr_W_Keypress );

	-- Definition of the state register
	
	signal state : state_type;
	
	-- Definition of the registers in the process unit

	signal dir_i : std_logic_vector(3 downto 0);  -- Registered Data to trasmit.
	
begin

PROTOCOL_FSM : process (clk, nrst) begin
	if nrst = '0' then
		state <= pr_W_Keypress;
		bank_ready <= '1';
		key_read <= '0';
		new_direction <= x"0";
		
	elsif clk'EVENT and clk = '1' then
		case state is
										
			when pr_W_Keypress => 
				if bcd = '1' then
					--Llegim i guardem per deixar-ho registrat.
					bank_ready <= '0';
					key_read <= '1';
					new_direction  <= direction;
					state <= pr_W_Keypress;
				else 
					bank_ready <= '1';
					key_read <= '0';
					state <= pr_W_Keypress; 
				end if;
						
			when others =>
				end case;
	end if;
end process;

end;