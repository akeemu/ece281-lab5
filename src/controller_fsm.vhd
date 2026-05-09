----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is
    signal f_cycle      : std_logic_vector(3 downto 0) :="0001";
    signal f_cycle_next : std_logic_vector(3 downto 0) :="0001";
begin
    -- CONCURRENT STATEMENTS -------	
	-- Next State Logic
	f_cycle_next(3) <= (f_cycle(2) and i_adv) or (f_cycle(3) and not i_adv);
	f_cycle_next(2) <= (f_cycle(1) and i_adv) or (f_cycle(2) and not i_adv);
	f_cycle_next(1) <= (f_cycle(0) and i_adv) or (f_cycle(1) and not i_adv);
	f_cycle_next(0) <= (f_cycle(0) and not i_adv) or (f_cycle(3) and i_adv);
	-- Output Logic
	o_cycle(3) <= f_cycle(3);
	o_cycle(2) <= f_cycle(2);
	o_cycle(1) <= f_cycle(1);
	o_cycle(0) <= f_cycle(0);
	
	
	register_proc : process (i_adv, i_reset)
	begin
	   if i_reset = '1' then
	       f_cycle <= "0001";      --Reset state is blank
	   elsif (rising_edge(i_adv)) then
	       f_cycle <= f_cycle_next;    --next state becomes current state
	   end if;

	end process register_proc;

end FSM;
