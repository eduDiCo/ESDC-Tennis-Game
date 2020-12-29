library ieee;
use ieee.std_logic_1164.all;

entity protocol_tx is
	port (
		clk, nrst: in std_logic;
		SEND_RDY, SEND_BALL_DT, SEND_SCORE_DT: in std_logic;  -- Frame to transmit.		
		-- BALL TX
		Ball_Pos_Y_TX : in std_logic_vector(9 downto 0); -- Position sent to the Opponent, when half field reached. Position Y of the ball (top left vertex): 0-479 pixel
		Ball_Move_X_TX : in std_logic_vector(9 downto 0); --Direction of the ball
		Ball_Move_Y_TX : in std_logic_vector(9 downto 0); --Direction of the ball
		-- SCORE: send the modified value
		Oponent_Score_TX : in std_logic_vector(7 downto 0); 
		Our_Score_TX : in std_logic_vector(7 downto 0);
		
		send : out std_logic;  -- send: to the UART. Active to send a new byte.
	    tx_data : out std_logic_vector(7 downto 0);  -- Byte sent to the UART TX for transmission
		ready_to_TX: out std_logic;  -- Flag. Active high if protocol is ready to tx (not transmiting a frame)									
		tx_empty : in std_logic  -- Signal from the UART TX. Active if new byte can be transmitted.
		);
end protocol_tx;


architecture main of protocol_tx is
	type state_type is (pr_wait, pr_rdy, pr_score, pr_ball, pr_s1, pr_w1, pr_s2, pr_w2,
						pr_check_data, pr_s3, pr_w3, pr_s4, pr_w4, pr_s5, pr_w5, pr_s6, 
						pr_w6, pr_s7, pr_w7, pr_s8, pr_w8, pr_set_TX );
	 
	 -- Definition of the diferent FRAME TYPE
	constant FRAME_ID : std_logic_vector(7 downto 0) := x"AA";
	constant RDY_TO_PLAY : std_logic_vector(7 downto 0) := x"A1";
	constant BALL : std_logic_vector(7 downto 0) := x"C1";
	constant SCORE : std_logic_vector(7 downto 0) := x"C4";	

	-- Definition of the state register
	
	signal state : state_type;
	
	-- Definition of the registers in the process unit

	signal frame_type: std_logic_vector(7 downto 0);
	signal dataH_i, dataT_i, dataU_i : std_logic_vector(3 downto 0);  -- Data to trasmit if FRAME is DATA.
	
begin

PROTOCOL_FSM : process (clk, nrst) begin
	if nrst = '0' then
		state <= pr_wait;
		ready_to_tx <= '1';
	elsif clk'EVENT and clk = '1' then
		case state is
			
			when pr_wait =>
				if SEND_RDY = '1' then state <= pr_rdy; 
				elsif SEND_SCORE_DT = '1' then 
					state <= pr_score;
				elsif SEND_BALL_DT = '1' then 
					state <= pr_ball; 
				else state <= pr_wait; 
				end if;

			-- Filling TX_DATA with frame ID and updating FRAME_TYPE.	
			when pr_rdy => 
				ready_to_tx <= '0';
				frame_type <= RDY_TO_PLAY;
				tx_data <= FRAME_ID;
				state <= pr_s1;
			when pr_ball => 
				ready_to_tx <= '0';
				frame_type <= BALL;
				tx_data <= FRAME_ID;
				state <= pr_s1;
			when pr_score => 
				ready_to_tx <= '0';
				frame_type <= SCORE;
				tx_data <= FRAME_ID;
				state <= pr_s1;	
				
			-- Sending FRAME_ID. SEND should be activated with a combinational system. 
			when pr_s1 =>
				state <= pr_w1;
				
			when pr_w1 =>
				if tx_empty = '1' then 
					state <= pr_s2;
					tx_data <= frame_type;
				end if;
				
			-- Sending FRAME TYPE. Send should be activated with a combinational system.	
			when pr_s2 =>
				state <= pr_w2;
					
			when pr_w2 =>
				if tx_empty = '1' then 
					state <= pr_check_data;
				end if;
				
			-- Checking if FRAME TYPE is DATA. If so, 8 bytes with data should be sent.
-- 1
			when pr_check_data => 
				if frame_type = BALL then
					state <= pr_s3;
					tx_data <= Ball_Pos_Y_TX(7 downto 0);
				elsif frame_type = SCORE then
					state <= pr_s3;
					tx_data <= Our_Score_TX;
				else
					state <= pr_set_TX;
				end if;
--				
			-- IF DATA. Let's send the 6 data bytes.
			-- Sending hundreds. Send should be activated with a combinational system.
			when pr_s3 =>
				state <= pr_w3;
-- 2				
			when pr_w3 =>
				if (tx_empty = '1' and frame_type = BALL) then
					state <= pr_s4;
					tx_data <= "000000" & Ball_Pos_Y_TX(9 downto 8);
				elsif (tx_empty = '1' and frame_type = SCORE) then
					state <= pr_s4;
					tx_data <= Oponent_Score_TX;
				else
					state <= pr_w3;
				end if;
							
			when pr_s4 =>
				state <= pr_w4;
--				
-- 3 -- Aqui en el cas de Score ja s'ha enviat tota la informació	
			when pr_w4 =>
				if (tx_empty = '1' and frame_type = BALL) then
					state <= pr_s5;
					tx_data <= Ball_Move_X_TX (7 downto 0);
				elsif (tx_empty = '1' and frame_type = SCORE) then
					state <= pr_set_TX;
				else
					state <= pr_w4;
				end if;

			when pr_s5 =>
				state <= pr_w5;
--
-- 4 -- Only Ball type can reach this point			
			when pr_w5 =>
				if tx_empty = '1' then
					state <= pr_s6;
					tx_data <= "000000" & Ball_Move_X_TX(9 downto 8);
				else
					state <= pr_w5;
				end if;

			when pr_s6 =>
				state <= pr_w6;
--
-- 5
			when pr_w6 =>
				if tx_empty = '1' then
					state <= pr_s7;
					tx_data <= Ball_Move_Y_TX (7 downto 0);
				else
					state <= pr_w6;
				end if;	

			when pr_s7 =>
				state <= pr_w7;
--
-- 6			
			when pr_w7 =>
				if tx_empty = '1' then
					state <= pr_s8;
					tx_data <= "000000" & Ball_Move_Y_TX(9 downto 8);
				else
					state <= pr_w7;
				end if;	
				
			when pr_s8 =>
				state <= pr_w8;
--
-- Done Tx Ball Data				
			when pr_w8 =>
				if tx_empty = '1' then 
					state <= pr_set_TX;
				end if;
			
			-- Final STATE. The frame has been sent. TX_EMPTY should be set to 1
			
			when pr_set_TX => 
				state <= pr_wait;
				ready_to_tx <= '1';
			when others =>
				end case;
	end if;
end process;

-- Activation of the signal SEND when the state is any of the pr_s

send <= '1' when state = pr_s1 or state = pr_s2 or state = pr_s3 or state = pr_s4 or state = pr_s5 
				or state = pr_s6 or state = pr_s7 or state = pr_s8 else '0';
end;