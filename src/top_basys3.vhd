--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    :   in std_logic; -- asynch reset for clock
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
    component controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component controller_fsm;
    
    component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
        -- Effectively, you divide the clk double this 
        -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
    
    component ALU is
        Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
               i_B : in STD_LOGIC_VECTOR (7 downto 0);
               i_op : in STD_LOGIC_VECTOR (2 downto 0);
               o_result : out STD_LOGIC_VECTOR (7 downto 0);
               o_flags : out STD_LOGIC_VECTOR (3 downto 0));
    end component ALU;
    
    component twos_comp is
        port (
            i_bin: in std_logic_vector(7 downto 0);
            o_sign: out std_logic;
            o_hund: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twos_comp;
    
    component TDM4 is
        generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
               i_reset		: in  STD_LOGIC; -- asynchronous
               i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
        );
    end component TDM4;
    
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component button_debounce is
        Port(	clk: in  STD_LOGIC;
                reset : in  STD_LOGIC;
                button: in STD_LOGIC;
                action: out STD_LOGIC);
    end component button_debounce;
    
    -- Signal declarations
    signal w_cycle  : std_logic_vector(3 downto 0);
    signal w_clk    : std_logic;
    signal w_debounce : std_logic;
    signal w_regA, w_regB : std_logic_vector(7 downto 0);
    signal w_result, w_ALU : std_logic_vector(7 downto 0);
    signal w_flags : std_logic_vector(3 downto 0); 
    
    signal w_seg : std_logic_vector(6 downto 0);
    signal w_sign, w_hund, w_tens, w_ones : std_logic_vector(3 downto 0);
    signal w_sign_mux : std_logic;
    signal w_sel, w_data : std_logic_vector(3 downto 0);
  
begin
	-- PORT MAPS ----------------------------------------
    controller_fsm_inst : controller_fsm
        port map (
            i_reset => btnU,
            i_adv   => w_debounce,
            o_cycle => w_cycle
        );
        
    clock_divider_inst : clock_divider
        generic map (k_DIV => 200000)
        port map(
            i_clk   => clk,
            i_reset => btnL,
            o_clk   => w_clk
        );
        
    ALU_inst : ALU
        port map (
            i_A => w_regA,
            i_B => w_regB,
            i_op => sw(2 downto 0),
            o_result => w_result,
            o_flags => w_flags
        );
        
    twos_comp_inst : twos_comp
        port map (
            i_bin => w_ALU,
            o_sign => w_sign_mux,
            o_hund => w_hund,
            o_tens => w_tens,
            o_ones => w_ones
        );
	
	TDM4_inst : TDM4
        generic map (k_WIDTH => 4)
        port map (
            i_clk => w_clk,
            i_reset => btnL,
            i_D3 => w_sign,
            i_D2 => w_hund,
            i_D1 => w_tens,
            i_D0 => w_ones,
            o_data => w_data,
            o_sel => w_sel
        );
        
    sevenseg_decoder_inst : sevenseg_decoder
        port map (
            i_Hex => w_data,
            o_seg_n => w_seg
        );
        
    button_debounce_inst : button_debounce
        port map (
            clk => clk,
            reset => btnU,
            button => btnC,
            action => w_debounce
        );
	
	-- CONCURRENT STATEMENTS ----------------------------
	-- Display mux from ALU
    w_ALU <= w_regA   when w_cycle(1) = '1' else
             w_regB   when w_cycle(2) = '1' else
             w_result when w_cycle(3) = '1' else
             "00000000";
         
	-- led
    led(3 downto 0) <= w_cycle;
    led(15 downto 12) <= w_flags;
    
    -- Mux to help deal with minus sign
    seg <= "0111111" when w_sel = "0111" and w_sign_mux = '1' else
           "1111111" when w_sel = "0111" and w_sign_mux = '0' else
           w_seg;
    -- Placeholder for sign data for TDM4 since actual minus goes through mux
    w_sign <= "0000";

    
    -- Another mux to blank display back in reset cycle
    an <= "1111" when w_cycle(0) = '1' else
          w_sel;
    
    
	-- Following from the 
	register_proc : process (clk)
	begin
	   if rising_edge(clk) then
           if btnU = '1' then
                w_regA <= "00000000";
                w_regB <= "00000000";
           else
                if w_debounce = '1' and w_cycle(1) = '1' then
                    w_regA <= sw;
                elsif w_debounce = '1' and w_cycle(2) = '1' then
                    w_regB <= sw;
                end if;
            end if;
        end if;

	end process register_proc;
	
end top_basys3_arch;
