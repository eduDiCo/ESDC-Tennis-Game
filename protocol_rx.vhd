library ieee;
use ieee.std_logic_1164.all;

entity protocol_rx is
	port (
		clk, nrst: in std_logic;
		RDY_RECEIVED, DT_BALL_RECEIVED, DT_SCORE_RECEIVED : out std_logic;  -- Frame received.
		rx_data : in std_logic_vector(7 downto 0);  -- Byte received from the UART RX
		rx_new, frame_read : in std_logic;  -- Signal from the UART RX. Active if new byte has been received.
										   -- Frame READ: frame has been read. Frame received has to be deactivated.
		-- BALL
		Ball_Pos_Y: out std_logic_vector(9 downto 0); -- Position Y of the ball (top left vertex): 0-479 pixel
		Ball_Move_X : out std_logic_vector(9 downto 0); --Direction of the ball
		Ball_Move_Y : out std_logic_vector(9 downto 0); --Direction of the ball 
		-- SCORE: modified everytime that the ball touches the back.
		Oponent_Score_RX : out std_logic_vector(7 downto 0); 
		Our_Score_RX : out std_logic_vector(7 downto 0);
		--
		data_read,new_frame : out std_logic  -- Flag. Active high if protocol is ready to tx (not transmiting a frame)
											-- new_frame: active if a new frame is received.
		);
end protocol_rx;


architecture main of protocol_rx is
	type state_type is (pr_ini, pr_w1, pr_r1, pr_w2, pr_r2, pr_f_type, pr_s_rdy, 
						pr_w3, pr_r3, pr_w4, pr_r4, pr_w5, pr_r5, pr_w6, pr_r6,
						pr_w7, pr_r7, pr_w8, pr_r8, pr_s_dt );
	 
	 -- Definition of the diferent FRAME TYPE
	constant FRAME_ID : std_logic_vector(7 downto 0) := x"AA";
	constant RDY_TO_PLAY : std_logic_vector(7 downto 0) := x"A1";
	constant BALL : std_logic_vector(7 downto 0) := x"C1";
	constant SCORE : std_logic_vector(7 downto 0) := x"C4";

	-- Definition of the state register
	
	signal state : state_type;
	
	-- Definition of the registers in the process unit

	signal frame_type: std_logic_vector(7 downto 0);
	
	-- Signals to activate the output flags
	signal set_RDY_RECEIVED, set_DT_BALL_RX , set_DT_SCORE_RX : std_logic;
	signal set_new_frame : std_logic;
	
begin

PROTOCOL_FSM : process (clk, nrst) begin
	if nrst = '0' then
		state <= pr_ini;
		RDY_RECEIVED <= '0'; 
		DT_BALL_RECEIVED <= '0';
		DT_SCORE_RECEIVED <= '0'; 
	    new_frame <= '0';
		Ball_Pos_Y <= "0000000000";
		Ball_Move_X <= "0000000000";
		Ball_Move_Y <= "0000000000";
		Oponent_Score_RX <= "00000000"; 
		Our_Score_RX <= "00000000";

	elsif clk'EVENT and clk = '1' then
				
		case state is
			when pr_ini =>
				RDY_RECEIVED <= '0'; 
				DT_BALL_RECEIVED <= '0';
				DT_SCORE_RECEIVED <= '0';  
				state <= pr_w1;
			
			-- Waiting for frame_ID to arrive
			when pr_w1 =>
				if rx_new = '1' then state <= pr_r1;
				end if;

			-- Frame ID arrived. We do not check it..	
			-- Data_read should be activated within a combinational system
			when pr_r1 => 
				state <= pr_w2;
				
			-- Waiting for FRAME TYPE to arive
			when pr_w2 => 
				if rx_new = '1' then state <= pr_r2;
				end if;	
			-- FRAME TYPE ARRIVED. 
			-- Data Read should be activated within a combinational system	
			when pr_r2 => 
				frame_type <= rx_data;
				state <= pr_f_type;
				
			-- Checking frame type. If type is data the system read 3 extra bytes.	
			when pr_f_type => 
				if frame_type = RDY_TO_PLAY then state <= pr_s_rdy;
				elsif frame_type = BALL then state <= pr_w3;
				elsif frame_type = SCORE then state <= pr_w3;
				end if;
				
			-- Activation of flags if frame is not CODE
			-- Flags should be activated within a combinational system.
			when pr_s_rdy =>
				RDY_RECEIVED <= '1'; 
				new_frame <= '1';
				state <= pr_ini;
				
			-- If FRAME is CODE, 8 extra bytes should be transmited.
-- 1
			when pr_w3 => 
				if rx_new = '1' then state <= pr_r3;
				end if;	
				
			-- Data Read should be activated within a combinational system	
			when pr_r3 =>
				if frame_type = BALL then
					Ball_Pos_Y (7 downto 0)<= rx_data;
					state <= pr_w4;
				elsif frame_type = SCORE then
					Oponent_Score_RX <= rx_data;
					state <= pr_w4;
				else
					state <= pr_r3;
				end if;
--
-- 2		
			when pr_w4 => 
				if rx_new = '1' then state <= pr_r4;
				end if;	

			-- Data Read should be activated within a combinational system	
			when pr_r4 => 
				if frame_type = BALL then
					Ball_Pos_Y (9 downto 8) <= rx_data(1 downto 0);
					state <= pr_w5;
				elsif frame_type = SCORE then
					Our_Score_RX <= rx_data;
					state <= pr_s_dt;
				else
					state <= pr_r4;
				end if;
-- 3 -- Aqui en el cas de Score ja s'ha rebut tota la informació				
			when pr_w5 => 
				if rx_new = '1' then state <= pr_r5;
				end if;	

			-- Data Read should be activated within a combinational system	
			when pr_r5 => 
				if frame_type = BALL then
					Ball_Move_X (7 downto 0)<= rx_data;
					state <= pr_w6;
				elsif frame_type = SCORE then
					state <= pr_s_dt;
				else
					state <= pr_r5;
				end if;
--
-- 4 -- Only Ball type can reach this point
			when pr_w6 => 
				if rx_new = '1' then state <= pr_r6;
				end if;	

			-- Data Read should be activated within a combinational system	
			when pr_r6 => 
				if frame_type = BALL then
					Ball_Move_X (9 downto 8) <= rx_data(1 downto 0);
					state <= pr_w7;
				else
					state <= pr_r6;
				end if;				
--
-- 5 
			when pr_w7 => 
				if rx_new = '1' then state <= pr_r7;
				end if;	

			-- Data Read should be activated within a combinational system	
			when pr_r7 => 
				if frame_type = BALL then
					Ball_Move_Y (7 downto 0) <= rx_data;
					state <= pr_w8;
				else
					state <= pr_r7;
				end if;				
--
-- 6 -- Last Rx Ball Data
			when pr_w8 => 
				if rx_new = '1' then state <= pr_r8;
				end if;	

			-- Data Read should be activated within a combinational system	
			when pr_r8 => 
				if frame_type = BALL then
					Ball_Move_Y (9 downto 8) <= rx_data(1 downto 0);
					state <= pr_s_dt;
				else
					state <= pr_r8;
				end if;				
--		
			-- Activation of the CODE Flag
			-- Activation must be done in a combinational system
			when pr_s_dt =>
				if frame_type = BALL then
					DT_BALL_RECEIVED <= '1'; 
					new_frame <= '1';
					state <= pr_ini;
				elsif frame_type = SCORE then
					DT_SCORE_RECEIVED <= '1'; 
					new_frame <= '1';
					state <= pr_ini;
				else
					state <= pr_s_dt;
				end if;
				
			when others =>
				end case;
	end if;
end process;


-- Combinational system for the signals that activate

data_read <= '1' when state = pr_r1 or state = pr_r2 or state = pr_r3 or 
	state = pr_r4 or state = pr_r5 or state = pr_r6 or state = pr_r7 or state = pr_r8 else '0';
		
end;