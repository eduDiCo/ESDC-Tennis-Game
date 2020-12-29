library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Ball_Movement is
	port (
		clk, nrst: in std_logic;
		enable: in std_logic; --from the TennisGame block when "DT_BALL_RECEIVED" is received. Enables this Block.
		delay: in std_logic; --from the TennisGame block when "DT_BALL_RECEIVED" is received. Enables this Block.
		initial_Move: in std_logic; -- Signal from Game Block. Signals the first ball movement of the point (the 1rst will always go towards player 1).
		goal : in std_logic;
		racket_hit : in std_logic;
		Ball_Pos_Y_RX: in std_logic_vector(9 downto 0); --Position of the ball, received from the opponent
		Ball_Move_X_RX : in std_logic_vector(9 downto 0); --Direction Vector X of the ball, received from the opponent 
		Ball_Move_Y_RX : in std_logic_vector(9 downto 0); --Direction Vector Y of the ball, received from the opponent 
		
		end_of_field_reached : out std_logic;  -- When the ball Reaches the half of the field, send the Ball Data "SEND_BALL_DT" to the Oponnent.
		enable_Ball_Hits_Racket: out std_logic; -- Signal to Activate mentioned Block, to handle if its "Goal" or "Racket Hit".
		enable_Delay: out std_logic; -- Signal to Activate mentioned Block, in order to have 500ms of delay.
		
		--Data Sent to Tennis Game block that will be, eventually, sent to the Opponent.
		--This also is sent to the VGA
		New_Ball_Pos_X : out std_logic_vector(9 downto 0); --new position X  of the ball. Position X of the ball (top left vertex): 0-639 pixel
		New_Ball_Pos_Y : out std_logic_vector(9 downto 0); --new position Y  of the ball. Position Y of the ball (top left vertex): 0-479 pixel
		--
		New_Ball_Move_X : out std_logic_vector(9 downto 0); --new direction Vector X  of the ball
		New_Ball_Move_Y : out std_logic_vector(9 downto 0) --new direction Vector Y  of the ball			  
		--
		);
end Ball_Movement;


architecture main of Ball_Movement is
	type state_type is (pr_wait_enable, pr_Initial_Move, pr_wait_05, pr_change_pos, pr_half_reached, pr_hit_racket, 
						pr_wait_hit_response, pr_hit_out, pr_final_data, pr_enable0);

	-- Definition of the state register
	
	signal state : state_type;
	
	-- Definition of the registers in the process unit

	--signal enable_i : std_logic;
	signal hit_i : std_logic; -- Used to avoid entering in "pr_half_reached" when we receive the ball info.
	signal initial_vector_X_i, initial_vector_Y_i: std_logic_vector(9 downto 0);
	signal pos_X_RX_i : integer range 0 to 1023; --Initial X position 240-20=620
	signal pos_X_i, pos_Y_i, vector_X_i, vector_Y_i : integer range 0 to 1023; -- Registered Position to trasmit.
	
begin

PROTOCOL_FSM : process (clk, nrst) begin
	if nrst = '0' then
		state <= pr_wait_enable;
		hit_i <= '0';
		pos_X_RX_i <= 640; -- Initial X position 640-20=620
		initial_vector_X_i <= "1111100010";  -- -30
		initial_vector_Y_i <= "1111100010";  -- -30
		end_of_field_reached <= '0';
		enable_Ball_Hits_Racket <= '0';
		New_Ball_Pos_Y <= "0000000000";
		New_Ball_Move_X <= "0000000000";
		New_Ball_Move_Y <= "0000000000"; 
		
	elsif clk'EVENT and clk = '1' then
		case state is
			
			when pr_wait_enable =>
				if enable = '1' then 
					hit_i <= '0';
					end_of_field_reached <= '0';
					enable_Ball_Hits_Racket <= '0';
					if initial_Move = '1' then 
						state <= pr_Initial_Move; 
					else
						pos_X_i <= pos_X_RX_i; --640-20=620
						pos_Y_i <=  to_integer(unsigned(Ball_Pos_Y_RX));
						vector_X_i <=  to_integer(signed(Ball_Move_X_RX));
						vector_Y_i <=  to_integer(signed(Ball_Move_Y_RX));
						state <= pr_change_pos;
					end if;
				else state <=  pr_wait_enable; 
				end if;
						
			when pr_wait_05 =>		
				--Esperar 0.5s
				if delay = '1' then 
					enable_Delay <= '0';
					state <= pr_change_pos; 
				else state <= pr_wait_05;
				end if;
			
			--Es fa el primer saque. A partir d'aqui saca qui fa punt. ( score -> initial_Move = '1';)
			when pr_Initial_Move =>
				--Valor de saque sempre el mateix
				pos_X_i <= pos_X_RX_i; --640-20=620
				pos_Y_i <= 240; -- 480/2 = 240
				vector_X_i <= to_integer(signed(initial_vector_X_i));
				vector_Y_i <= to_integer(signed(initial_vector_Y_i));
				state <= pr_change_pos; 
			--
			when pr_change_pos =>
				pos_X_i <= pos_X_i + vector_X_i; 
				pos_Y_i <= pos_Y_i + vector_Y_i;
				state <= pr_half_reached;
			--
			--Comprovem si s'ha arribat al mig del camp
			when pr_half_reached =>
				-- hit = 1 : means the ball has touched the racked and came back
				--If pos_X_i + vector_X_i is < 0 then pos_X_i gets values close to 1023 (ciclic integer variable)
				if (pos_X_i > 640 and pos_X_i < 900 and hit_i = '1') then
					end_of_field_reached <= '1';
					state <= pr_wait_enable;
				else state <= pr_hit_racket;
				end if;
			--
			--S'arriba al final del camp: gol o xoc raqueta?	
			when pr_hit_racket =>			
				-- Hit Racket ?
				--If pos_X_i + vector_X_i is < 0 then pos_X_i gets values close to 1023 (ciclic integer variable)
				if ( pos_X_i < 20 or pos_X_i = 20 or pos_X_i > 900) then
					enable_Ball_Hits_Racket <= '1';
					state <= pr_wait_hit_response;
				else state <= pr_hit_out;
				end if;
			--
			--Comprovem si es gol o toca la raqueta	
			when pr_wait_hit_response =>			
				-- Hit Racket
				if racket_hit = '1' then
					hit_i <= '1';
					enable_Ball_Hits_Racket <= '0';
					vector_X_i <= -vector_X_i;
					state <= pr_hit_out;
				-- No Hit Racket -> Opponent scored Goal
				elsif goal = '1' then
					enable_Ball_Hits_Racket <= '0';
					state <= pr_enable0;
				else state <= pr_wait_hit_response;
				end if;
			when pr_enable0 => -- we wait here until Game Block disenables.			
				if enable = '0' then
					New_Ball_Pos_X <= "0000000000";
					New_Ball_Pos_Y <= "0000000000";
					New_Ball_Move_X <= "0000000000";
					New_Ball_Move_Y <= "0000000000";
					state <= pr_wait_enable;
				else
					state <= pr_enable0;
				end if;
			--
			--Si toca adalt o abaix	
			when pr_hit_out =>		
				-- Hit Top
				--If pos_Y_i + vector_Y_i is < 0 then pos_Y_i gets values close to 1023 (ciclic integer variable)
				if (pos_Y_i = 0 or pos_Y_i > 900) then
					pos_Y_i <= 0;
					vector_Y_i <= - vector_Y_i;
				--Hit Bottom
				elsif (pos_Y_i > 479 or pos_Y_i = 479) then 
					pos_Y_i <= 479;
					vector_Y_i <= - vector_Y_i;
				end if;
				state <= pr_final_data;
			--
			--Pasem la info de posició i vectors	
			when pr_final_data =>
				New_Ball_Pos_X <= std_logic_vector(to_signed(pos_X_i, 10));
				New_Ball_Pos_Y <= std_logic_vector(to_signed(pos_Y_i, 10));
				New_Ball_Move_X <= std_logic_vector(to_signed(vector_X_i, 10));
				New_Ball_Move_Y <= std_logic_vector(to_signed(vector_Y_i, 10)); 
				if enable = '1' then
					enable_Delay <= '1';
					state <= pr_wait_05;
					--state <= pr_change_pos;
				else state <=  pr_wait_enable; 
				end if; 
			--
							
			when others =>
				end case;
	end if;
end process;

end;