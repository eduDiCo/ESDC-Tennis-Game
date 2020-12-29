library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Ball_Hits_Racket is
	port (
		clk, nrst: in std_logic;
		enable: in std_logic; -- If the ball is coming towards the player, eventually is going to hit
		Ball_Pos_Y : in std_logic_vector(9 downto 0); --Position Y of the ball.
		Racket_Position : in std_logic_vector(9 downto 0);  --Position of our racket (modified by new_direction from register Block)
		
		goal : out std_logic; -- If the ball hits the end of the game field. and not the ball
		racket_hit : out std_logic 			  
		);
end  Ball_Hits_Racket;


architecture main of  Ball_Hits_Racket is
	type state_type is (pr_wait_enable, pr_hit);

	-- Definition of the state register
	
	signal state : state_type;
	
	-- Definition of the registers in the process unit

	signal hit_i : std_logic; 
	signal pos_Y_i, racket_Y_i: integer range 0 to 1023; -- Registered Position to trasmit.
	
begin

PROTOCOL_FSM : process (clk, nrst)
	variable cont : integer;
begin
	if nrst = '0' then
		state <= pr_wait_enable;
		hit_i <= '0';
		goal <= '0';
		racket_hit <= '0'; 
		
	elsif clk'EVENT and clk = '1' then
		case state is
			
			when pr_wait_enable =>
				if enable = '1' then 
					hit_i <= '0';
					goal <= '0';
					racket_hit <= '0'; 
					pos_Y_i <=  to_integer(unsigned(Ball_Pos_Y));
					racket_Y_i <=  to_integer(unsigned(Racket_Position));
					state <= pr_hit;
				else 
					hit_i <= '0';
					goal <= '0';
					racket_hit <= '0'; 
					state <= pr_wait_enable; 
				end if;
			
			when pr_hit =>
				-- Hit?
				if ( ( pos_Y_i > racket_Y_i and pos_Y_i < (racket_Y_i + 64) ) or ( (pos_Y_i + 20) > racket_Y_i and (pos_Y_i + 20) < (racket_Y_i + 64) ) ) then 

					hit_i <= '1';
					racket_hit <= '1';
					goal <= '0';
					state <= pr_wait_enable;
				--No Hit
				elsif hit_i = '0' then
					racket_hit <= '0';
					goal <= '1';
					state <= pr_wait_enable;
				end if;
						
			when others =>
				end case;
	end if;
end process;

end;