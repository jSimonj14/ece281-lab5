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
        clk: in std_logic;
        sw: in std_logic_vector(7 downto 0);
        btnC: in std_logic;
        btnU: in std_logic;
        led: out std_logic_vector(15 downto 0);
        seg: out std_logic_vector(6 downto 0);
        an: out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 

    signal w_clkT, w_clkC, w_reset, w_next    : std_logic;
    signal w_state  : std_logic_vector (3 downto 0);
    signal w_A      : std_logic_vector (8 downto 0);
    signal w_B      : std_logic_vector (8 downto 0);
    signal w_result : std_logic_vector (7 downto 0);
    signal w_bin    : std_logic_vector (7 downto 0);
    signal w_sign   : std_logic_vector (3 downto 0);
    signal w_hund   : std_logic_vector (3 downto 0);
    signal w_flag   : std_logic_vector (2 downto 0);    
    signal w_tens   : std_logic_vector (3 downto 0);
    signal w_ones   : std_logic_vector (3 downto 0);
    signal w_data   : std_logic_vector (3 downto 0);
    signal w_sel    : STD_LOGIC_VECTOR (3 downto 0);

	-- declare components and signals
component controller_fsm is
        Port(
            i_reset  : in std_logic;
            i_next   : in std_logic;
            i_clk    : in std_logic;
            o_state  : out std_logic_vector(3 downto 0)
            );
    end component controller_fsm;
    
component sevenSegDecoder is
        
        Port ( i_D : in STD_LOGIC_VECTOR (3 downto 0);
               o_S : out STD_LOGIC_VECTOR (6 downto 0)
               );  
    end component sevenSegDecoder;
    
component twoscomp_decimal is
        port (
            i_binary: in std_logic_vector(7 downto 0);
            o_negative: out std_logic_vector (3 downto 0);
            o_hundreds: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twoscomp_decimal;
    
component clock_divider is
        generic ( constant k_DIV : natural := 2    ); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port (     i_clk    : in std_logic;
                i_reset  : in std_logic;           -- asynchronous
                o_clk    : out std_logic           -- divided (slow) clock
        );
    end component clock_divider;
    
component TDM4 is
        generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port (
               i_clk        : in  STD_LOGIC;
               i_reset        : in  STD_LOGIC; -- asynchronous
               i_D3         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data        : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel        : out STD_LOGIC_VECTOR (3 downto 0)    -- selected data line (one-cold)
        );
    end component TDM4;

component ALU is
    Port ( 
           i_op     : in STD_LOGIC_VECTOR (2 downto 0);
           i_A      : in STD_LOGIC_VECTOR (8 downto 0);
           i_B      : in STD_LOGIC_VECTOR (8 downto 0);
           o_flag   : out STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0)
           
           );

    -- TODO
end component ALU;
  
begin
	-- PORT MAPS ----------------------------------------
    w_reset <= btnU;
    w_next <= btnC;
	
	sevenSegDecoder_inst : sevenSegDecoder
    port map(
       i_D => w_data,
       o_S => seg
    );    
    clkdivcontroller_inst : clock_divider         
    generic map ( k_DIV => 25000000 ) 
    port map (                          
       i_clk    => clk,
       i_reset  => '0',       
       o_clk    => w_clkC      
    );    
    clkdivtdm_inst : clock_divider         
    generic map ( k_DIV => 100000 ) 
    port map (                          
	   i_clk    => clk,
       i_reset  => w_reset,       
       o_clk    => w_clkT      
    ); 
       
    tdm4_inst : TDM4         
    generic map (k_WIDTH => 4 )
    port map (  
        i_clk        => w_clkT,
        i_reset      => w_reset,
        i_D3         => w_sign,
        i_D2         => w_hund,
        i_D1         => w_tens,
        i_D0         => w_ones,
        o_data       => w_data,
        o_sel        => w_sel                        
      
    );    
    
    
	controller_inst : controller_fsm
    port map(
       i_reset => w_reset,
       i_next  => w_next,
       i_clk   => w_clkC,
       o_state => w_state
    );
    
	twoscomp_inst : twoscomp_decimal
    port map(
        i_binary => w_bin,
        o_negative => w_sign,
        o_hundreds => w_hund,
        o_tens => w_tens,
        o_ones => w_ones
    );
    
	ALU_inst : ALU
    port map(
        i_op     => sw(2 downto 0),
        i_A      => w_A,
        i_B      => w_B,
        o_flag   => w_flag,
        o_result => w_result
    );
    
	-- CONCURRENT STATEMENTS ----------------------------
    register_A_proc: process (w_state(0), w_reset)
    begin
        if (w_reset = '1') then 
            w_A(7 downto 0) <= "00000000";
        elsif (rising_edge(w_state(0))) then
            w_A(7 downto 0) <= sw(7 downto 0);
        end if;
    end process;
    
    register_B_proc: process (w_state(1), w_reset)
    begin
        if (w_reset = '1') then 
            w_B(7 downto 0) <= "00000000";
        elsif (rising_edge(w_state(1))) then
            w_B(7 downto 0) <= sw(7 downto 0);
        end if;
    end process;	       
	
	w_A(8) <= '0';
	w_B(8) <= '0';
    
	w_bin <= w_A(7 downto 0) when (w_state = "0001") else
             w_B(7 downto 0) when (w_state = "0010") else
             w_result when (w_state = "0100") else
             "00000000" when (w_state = "1000") else
             "00000000";  
       led(3 downto 0) <= w_state;
    an(3 downto 0) <= w_sel;
    led(15) <= w_flag(2);
    led(14) <= w_flag(1);
    led(13) <= w_flag(0);
    led(12 downto 4) <= (others => '0');   
    end top_basys3_arch;

