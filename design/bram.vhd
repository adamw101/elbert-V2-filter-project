----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.03.2026 13:48:16
-- Design Name: 
-- Module Name: bram - Behavioral
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

--use std.env.finish;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity bram is
port (clk : in std_logic;
      we : in std_logic;
      a : in std_logic_vector(9 downto 0);
      dpra : in std_logic_vector(9 downto 0);
      di : in std_logic_vector(6 downto 0);
      dpo : out std_logic_vector(6 downto 0));
end bram;
architecture syn of bram is
--ram_type array size(623) is equal to the number of pixels vertically
--memory is asynchronous, we're inferring bram
type ram_type is array (622 downto 0) of std_logic_vector (6 downto 0);
signal RAM : ram_type := (others => (others=>'0'));
signal read_dpra : std_logic_vector(9 downto 0):=(others=>'0');

attribute ram_style : string;
attribute ram_style of RAM : signal is "block";

begin
process (clk)
begin
    if (clk'event and clk = '1') then
        if (we = '1') then
            RAM(to_integer(unsigned(a))) <= di;
        end if;
        read_dpra <= dpra;
    end if;
end process;

dpo <= RAM(to_integer(unsigned(read_dpra)));
end syn;