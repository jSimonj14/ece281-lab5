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

entity ALU is
    port(
        i_op    :   in std_logic_vector(2 downto 0);
        i_A     :   in std_logic_vector(8 downto 0);
        i_B     :   in std_logic_vector(8 downto 0);
        o_result:   out std_logic_vector(7 downto 0);
        o_flag  :   out std_logic_vector(2 downto 0)
    );
end ALU;

architecture behavioral of ALU is 
    signal w_op : std_logic_vector(8 downto 0) := (others => '0');
    signal w_add : std_logic_vector(8 downto 0) := (others => '0');
    signal w_tot : std_logic_vector(8 downto 0) := (others => '0');
    signal w_Cout, w_sign, w_zero: std_logic;
    signal w_PN   : std_logic_vector(8 downto 0);
    signal w_shiftR : std_logic_vector(8 downto 0) := (others => '0');
    signal w_shiftL : std_logic_vector(8 downto 0) := (others => '0');
    signal w_shift, w_and, w_or : std_logic_vector(8 downto 0) := (others => '0');
    
    
begin

	
    
	-- CONCURRENT STATEMENTS ----------------------------
	
   w_op <=    "000000001" when i_op = "000000001" else
                   "000000000";
    w_PN <= not(i_B) when (i_op = "000000001") else i_B;
    
    w_add <= std_logic_vector(signed(i_A) + signed(w_PN) + signed(w_op));
	
	w_shiftR <= std_logic_vector (shift_right(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0)))));
    w_shiftL <= std_logic_vector (shift_left(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0)))));
    w_shift  <= w_shiftR when (i_op(0) = '0') else
                w_shiftL;
                
                
    w_and <= i_A and i_B;
    w_or <= i_A or i_B;   

    
   w_tot <= w_add when (i_op(2 downto 1) = "00") else
             w_or when (i_op(2 downto 1) = "10") else
             w_and when (i_op(2 downto 1) = "01") else
             w_shift when (i_op(2 downto 1) = "11"); 
 
    o_result <= w_tot(7 downto 0);
 
    w_Cout <= w_tot(8);
    w_sign <= w_tot(7);
    
    o_flag(0) <= w_cout;
    o_flag(1) <= '0';
    o_flag(2) <= w_sign;
	
end behavioral;

