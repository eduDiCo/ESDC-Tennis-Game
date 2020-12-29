library ieee;
use ieee.std_logic_1164.all;

entity Delay_Block is
	port (
		clk, nrst: in std_logic;
		enable : in std_logic;  
		
		delay_500: out std_logic 					  
		);
end Delay_Block ;


architecture main of Delay_Block is
	type state_type is (pr_w_enable, pr_Wait);

	-- Definition of the state register
	
	signal state : state_type;
	
	-- Definition of the registers in the process unit

	signal cont_i : integer range 0 to 63; -- Registered Position to trasmit.
	
begin

PROTOCOL_FSM : process (clk, nrst) begin
	if nrst = '0' then
		state <= pr_w_enable;
		cont_i <= 0; 
		delay_500<= '0';
		
	elsif clk'EVENT and clk = '1' then
		case state is
			
			when pr_w_enable =>
				cont_i <= 0;
				delay_500<= '0';				
				if  enable = '1' then state <= pr_Wait; 
				else state <= pr_w_enable; 
				end if;
			
			when pr_Wait =>
				cont_i <= cont_i + 1;
				if  cont_i = 50 then 
					delay_500<= '1';
					state <= pr_w_enable; 
				else state <= pr_Wait; 
				end if;
						
			when others =>
				end case;
	end if;
end process;

end;