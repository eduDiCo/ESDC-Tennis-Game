library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tennisGame_P1 is
	port (
		clk, nrst: in std_logic;
		new_game: in std_logic; --activating signal from the MAIN block. Synchronous signal, active high.(1 clock period)
		ast: in std_logic; --activating signal from the MAIN block. Synchronous signal, active high.(1 clock period)
		RDY_RECEIVED, DT_BALL_RECEIVED, DT_SCORE_RECEIVED : in std_logic; --from the RECEIVER block. Indicates the type of frame received.		
		-- BALL
		Ball_Pos_Y: in std_logic_vector(9 downto 0); -- Position Y of the ball (top left vertex): 0-479 pixel
		Ball_Move_X : in std_logic_vector(9 downto 0); --Direction of the ball
		Ball_Move_Y : in std_logic_vector(9 downto 0); --Direction of the ball 
		-- SCORE: modified everytime that the ball touches the back.
		Oponent_Score_RX : in std_logic_vector(7 downto 0); 
		Our_Score_RX : in std_logic_vector(7 downto 0); 
		--
		--Info from BALL Blocks
		end_of_field_reached : in std_logic;  -- When the ball Reaches the half of the field, send the Ball Data "SEND_BALL_DT" to the Oponnent.
		goal : in std_logic;
		ready_to_TX: in std_logic; -- transmitter i s not currently transmitting any frame, and a new frame can be transmitted.
		
		SEND_RDY, SEND_BALL_DT, SEND_SCORE_DT: out std_logic;  -- Frame to transmit.
		-- Ball Modification
		enable_Ball_Move: out std_logic; -- Signal to Activate the Ball_Movement block to draw the ball, active when "DT_BALL_RECEIVED" is received.
		initial_Move: out std_logic; -- Signal to start the first ball movement of the point (the 1rst will always go towards player 1).
		--enable_Ball_Hits_Racket: out std_logic; -- Signal to Activate mentioned Block, to handle if its "Goal" or "Racket Hit".
		--
		frame_received: out std_logic; --acknowledge the reception of a frame
		LightWIN: out std_logic; -- inform that the game is over and the user wins the game
		Light_Loose: out std_logic; -- inform that the game is over and the user loses the game
		-- BALL TX
		Ball_Pos_Y_TX : out std_logic_vector(9 downto 0); -- Position sent to the Opponent, when half field reached. Position Y of the ball (top left vertex): 0-479 pixel
		Ball_Move_X_TX : out std_logic_vector(9 downto 0); --Direction of the ball
		Ball_Move_Y_TX : out std_logic_vector(9 downto 0); --Direction of the ball
		-- SCORE: send the modified value
		Oponent_Score_TX : out std_logic_vector(7 downto 0); 
		Our_Score_TX : out std_logic_vector(7 downto 0)
		);
end tennisGame_P1;


architecture main of tennisGame_P1 is
	type state_type is (pr_wait_start, pr_W_Tx1, pr_S_RDY, pr_wait_RDY, pr_Initial_Move,pr_W_Data, pr_Score_RX, 
						pr_Ball_Rx, pr_W_Game, pr_W_Tx2, pr_end_field_reached, pr_W_Tx3);
	 
	-- Definition of the state register
	
	signal state : state_type;
	
	-- Definition of the registers in the process unit
	
	signal our_score_i : integer range 0 to 16; -- Registered Position to trasmit.
	signal opponent_score_i: integer range 0 to 16; -- Registered Position to trasmit.
	
begin

PROTOCOL_FSM : process (clk, nrst) begin
	if nrst = '0' then
		our_score_i <= 0;
		opponent_score_i <= 0;
		state <= pr_wait_start;
		--SEND_RDY <= '0';
		--SEND_BALL_DT <= '0';
		--SEND_SCORE_DT <= '0';
		enable_Ball_Move <= '0';
		initial_Move <= '0';
		--frame_received <= '0';
		LightWIN <= '0';
		Light_Loose <= '0';
		Ball_Pos_Y_TX <= "0000000000";
		Ball_Move_X_TX <= "0000000000";
		Ball_Move_Y_TX <= "0000000000";
		Oponent_Score_TX <= x"00";
		Our_Score_TX <= x"00";
		
	elsif clk'EVENT and clk = '1' then
		case state is
			
			when pr_wait_start =>
				if new_game = '1' and ast = '1' then 					
					initial_Move <= '1'; -- Posat a '1' permet el primer saque, jugador 2 ho te a 0.
					LightWIN <= '0';
					Light_Loose <= '0'; 
					state <= pr_W_Tx1; 
				else state <= pr_wait_start; 
				end if;
				
			--Enviar Ready	
			when pr_W_Tx1 =>
				if ready_to_TX = '1' then state <= pr_S_RDY; 
				else state <= pr_W_Tx1;
				end if;
				
			when pr_S_RDY =>
				state <= pr_wait_RDY;
				--SEND_RDY <= '1';
			--
			--Espera a rebre el Ready de l'oponent
			when pr_wait_RDY =>
				if RDY_RECEIVED = '1' then state <= pr_Initial_Move; 
				else state <= pr_wait_RDY;
				end if;
			--
			--Es fa el primer saque. A partir d'aqui saca qui fa punt. ( score -> initial_Move = '1';)
			when pr_Initial_Move =>
				initial_Move <= '1';
				enable_Ball_Move <= '1';
				state <= pr_W_Game; 
			--
			-- Esperem a rebre feedback del Oponent
			when pr_W_Data =>
				if DT_BALL_RECEIVED = '1' then state <= pr_Ball_Rx;
				elsif DT_SCORE_RECEIVED = '1' then 
					opponent_score_i <= to_integer(unsigned(Oponent_Score_RX));
					our_score_i<= to_integer(unsigned(Our_Score_RX));
					state <= pr_Score_RX;
				else state <= pr_W_Data;
				end if;
			--
			
			-- 1.Rebem la Puntuacio ( score -> initial_Move = '1', tornem a sacar)
			when pr_Score_RX =>
				initial_Move <= '1';
				-- El primer que arriba a 9 guanya
				if our_score_i = 9 then 
					LightWIN <= '1';
					state <= pr_wait_start;
				--Torna a comenÃ§ar un nou punt
				else state <= pr_W_Tx1;
				end if;
			--
			-- 2. Rebem la informacio de la pilota
			when pr_Ball_Rx =>
				enable_Ball_Move <= '1';
				state <= pr_W_Game;
			
				-- Esperem si es gol o continua el joc
			when pr_W_Game =>
					initial_Move <= '0';
					if goal = '1' then  --( No score -> initial_Move = '0', saca el oponent)
					opponent_score_i<= opponent_score_i + 1;
					Our_Score_TX <= std_logic_vector(to_unsigned(our_score_i, 8));
					Ball_Pos_Y_TX <= "0000000000";
					Ball_Move_X_TX <= "0000000000";
					Ball_Move_Y_TX <= "0000000000";
					state <= pr_W_Tx2;
				elsif end_of_field_reached = '1' then  --( No score -> initial_Move = '0', saca el oponent)	
					state <= pr_end_field_reached;
				else state <= pr_W_Game;
				end if;
				--

				-- Si es gol
			when pr_W_Tx2 =>
				--SEND_SCORE_DT <= '1';
				Oponent_Score_TX <= std_logic_vector(to_unsigned(opponent_score_i, 8));
				enable_Ball_Move <= '0';
				if opponent_score_i = 9 then 
					Light_Loose <= '1';
					state <= pr_wait_start;
				--Torna a comenÃ§ar un nou punt
				else state <= pr_wait_start;
				end if;
				--

				-- Si no es gol el joc continua i enviem la informació al oponent
			when pr_end_field_reached =>
				enable_Ball_Move <= '0';
				Ball_Pos_Y_TX <= Ball_Pos_Y;
				Ball_Move_X_TX <= Ball_Move_X; 
				Ball_Move_Y_TX <= Ball_Move_Y;
				state <= pr_W_Tx3;
				--Tornem a esperar la resposta de l'oponent
			when pr_W_Tx3 =>
				--SEND_BALL_DT <= '1';
				state <= pr_W_Data;
				--
			--

			when others =>
				end case;
	end if;
end process;

-- Els segûents casos només son actius durant 1 clock cicle:
-- S'han deixat marcats al codi per claredat.
SEND_RDY <= '1' when state = pr_S_RDY else '0';
SEND_SCORE_DT <= '1' when state = pr_W_Tx2 else '0';
SEND_BALL_DT <= '1' when state = pr_W_Tx3 else '0';
frame_received <= '1' when (state = pr_W_Data or state = pr_wait_RDY) else '0';
end;