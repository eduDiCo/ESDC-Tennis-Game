library ieee;
use ieee.std_logic_1164.all;

entity main_control is
	port (
		clk, nrst: in std_logic;
		hash: in std_logic; --active when the user has pressed hashtag (#)
		ast: in std_logic; --active when the user has pressed hashtag (*)
		--WINNER, LOOSER: Signals activated by the GAME block. These signals are active when the game is over. 
		--This indicates that the game returns to the wait state, waiting for a new game to start (i.e., the user presses #).
		winner, looser: in std_logic; 
		--
		
		key_read: out std_logic; -- Used as ACK signal for the KEYBOARD block, to indicate that the # has been read.
		game_over: out std_logic; --It i s active while the CONTROL i s i n the wait state, waiting for the user to press # 
								  --in order to start a new game
		ready_play: out std_logic; 
		new_game: out std_logic 						  
		);
end main_control;


architecture main of main_control is
	type state_type is (pr_Wait, pr_W_Game);

	-- Definition of the state register
	
	signal state : state_type;
	
begin

PROTOCOL_FSM : process (clk, nrst) begin
	if nrst = '0' then
		game_over <= '1';
		key_read <= '0';
		new_game <= '0';
		state <= pr_Wait;
	elsif clk'EVENT and clk = '1' then
		case state is
			
			when pr_Wait =>
				if hash = '1' then 
					key_read <= '1'; 
					new_game <= '1';
					game_over <= '0';
					state <= pr_W_Game; 
				else 
					state <= pr_Wait; 
				end if;
				
			when pr_W_Game =>	
				if (winner='1' or looser='1') then 
					new_game <= '0';
					game_over <= '1';
					state <= pr_Wait;
				elsif ast = '1' then 
					ready_play <= '1';
					state <= pr_W_Game;
				else
					ready_play <= '0';
					state <= pr_W_Game; 
				end if;
			
			when others =>
				end case;
	end if;
end process;
end;