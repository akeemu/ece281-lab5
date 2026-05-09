----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

    signal w_sub_B    : STD_LOGIC_VECTOR(7 downto 0);
    signal w_cin      : STD_LOGIC;
    signal w_sum      : STD_LOGIC_VECTOR(7 downto 0);
    signal w_result   : STD_LOGIC_VECTOR(7 downto 0);
    signal w_carryout : STD_LOGIC;
    
    component ripple_adder is
        port (
            A    : in STD_LOGIC_VECTOR (7 downto 0);
            B    : in STD_LOGIC_VECTOR (7 downto 0);
            Cin  : in STD_LOGIC;
            S    : out STD_LOGIC_VECTOR (7 downto 0);
            Cout : out STD_LOGIC
        );
    end component ripple_adder;
    
begin

    -- Port maps
    ripple_adder_inst : ripple_adder
        port map (
            A    => i_A,
            B    => w_sub_B,
            Cin  => w_cin,
            S    => w_sum,
            Cout => w_carryout
        );

    -- Concurrent statements
    w_sub_B  <= not i_B when i_op = "001" else i_B;
    w_cin    <= '1' when i_op = "001" else '0';
    w_result <= w_sum when i_op = "000" else
                w_sum when i_op = "001" else
                (i_A and i_B) when i_op = "010" else
                (i_A or i_B) when i_op = "011" else
                "00000000";
    o_result <= w_result;
    
    -- Flags
    o_flags(3) <= w_result(7);      -- N
    o_flags(2) <= '1' when w_result = "00000000" else '0';      -- Z
    o_flags(1) <= w_carryout when (i_op = "000" or i_op = "001") else '0';  --C
    o_flags(0) <= (i_A(7) xor w_result(7)) and (not (i_A(7) xor i_B(7) xor i_op(0)))
                  when i_op = "000" or i_op = "001" else '0';   -- V

end Behavioral;
