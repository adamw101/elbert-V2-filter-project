----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.03.2026 13:48:16
-- Design Name: 
-- Module Name: uart_transceiver_tb - Behavioral
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

use std.env.finish;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_transceiver_tb is
--  Port ( );
end uart_transceiver_tb;

architecture Behavioral of uart_transceiver_tb is

signal clk_12mhz_tb  :  std_logic;
signal reset_tb       :  std_logic;
signal tx_tb          :  std_logic;
signal rx_tb          :  std_logic;
signal last_byte_tb   :  std_logic_vector(7 downto 0);
signal new_bt_flag_tb :  std_logic; 

constant clock_period : time := 83.333ns;

component uart_transceiver
Port ( 
    clk_12mhz  : in std_logic;
    reset       : in std_logic;
    tx          : out std_logic;
    rx          : in std_logic;
    last_byte   : out std_logic_vector(7 downto 0);
    new_bt_flag : out std_logic 

);
end component;


begin

DUT : uart_transceiver
port map(
    clk_12mhz=>clk_12mhz_tb,
    reset=>reset_tb,
    tx=>tx_tb,
    rx=>rx_tb,
    last_byte=>last_byte_tb,
    new_bt_flag=>new_bt_flag_tb
);

process is
begin
clk_12mhz_tb<= '0';
wait for clock_period/2;
clk_12mhz_tb<= '1';
wait for clock_period/2;
end process;

process is
begin
    reset_tb <= '1';
    rx_tb<= '1';
    wait for 1000ns;
    reset_tb<= '0';
    wait for 100ns;
    rx_tb<= '0';
    wait for 104166ns;
    rx_tb<= '1';   
    wait for 2*104166ns;
    rx_tb<= '0';
    wait for 2*104166ns;
    rx_tb<= '1';  
    wait for 12*104166ns;
    report "Calling 'finish'";
    finish;
end process;


end Behavioral;
