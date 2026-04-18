----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.03.2026 22:46:59
-- Design Name: 
-- Module Name: uart_receiver - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity uart_receiver is
Port ( 
    --clk_12mhz  : in std_logic;  
    clk         : in std_logic;
    reset       : in std_logic;
    tx          : out std_logic;
    rx          : in std_logic;
    last_byte   : out std_logic_vector(7 downto 0);
    new_bt_flag : out std_logic;
    checksum_invalid : out std_logic 

);
end uart_receiver;

architecture Behavioral of uart_receiver is

    signal rx_edge_detect : std_logic_vector(2 downto 0);
    signal rx_falling_edge_flag : std_logic;

    signal rx_elapsed_time_cntr : unsigned(20 downto 0);
    signal rx_cntr_active_flag : std_logic:='0';

    constant clk_freq : natural   := 100000000;
    constant baudrate   : natural := 115200;
    constant uart_period : unsigned (24 downto 0) :=to_unsigned(clk_freq/baudrate,25);

    signal byte_sum : unsigned(8 downto 0);
    type state is (IDLE,START_BIT, LOAD_B0,LOAD_B1,LOAD_B2,LOAD_B3, LOAD_B4, LOAD_B5, LOAD_B6, LOAD_B7, CHECKSUM, STOP_BIT);

    signal next_state : state;
    signal current_state : state;

    signal last_byte_reg : std_logic_vector(7 downto 0);

begin

    rx_falling_edge_flag <= '1' when (rx_edge_detect = "011" or rx_edge_detect = "001" ) else '0';
    tx <= '1';

    --this process drives shift register which is later used for detectinge falling edge
    --we're using shift register as rx could potentialu be unstable
    process(clk)
    begin
        if rising_edge(clk) then
            rx_edge_detect(2) <= rx;
            rx_edge_detect(1) <= rx_edge_detect(2);
            rx_edge_detect(0) <= rx_edge_detect(1);
        end if;
    end process;

    --process for generating tx_timer
    process(clk,reset)
    begin
        if reset = '1' then
                    rx_elapsed_time_cntr <= TO_UNSIGNED(0,21);
                    rx_cntr_active_flag <= '0';
        else
            if rising_edge(clk) then
                
                
                    if rx_cntr_active_flag = '1' then
                        if  rx_elapsed_time_cntr < uart_period/2 and rx_edge_detect = "111" then
                            --if rx signal dropped but wasn't low for long enough stop the timer
                            rx_cntr_active_flag <= '0';
                        elsif rx_elapsed_time_cntr > 10*uart_period and rx_edge_detect = "111" then
                            --if you detect stop bit stop the counter
                            rx_cntr_active_flag <= '0';
                        else
                            rx_elapsed_time_cntr <= rx_elapsed_time_cntr+1;
                        end if;
                    else
                        if rx_falling_edge_flag = '1' then
                            rx_cntr_active_flag <= '1';
                            rx_elapsed_time_cntr <= rx_elapsed_time_cntr+2;
                        else
                        rx_elapsed_time_cntr <= TO_UNSIGNED(0,21);
                        end if;
                    end if;
                end if;
            end if;
    end process;
--process for changing states
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_state <= IDLE;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;
--process for driving signals depending on the current state
--we're sampling rx input in the middle of timeslot
    process(clk)
    begin
        if rising_edge(clk) then
            case current_state is
                when IDLE =>
                    byte_sum<= (others => '0');
                    new_bt_flag<= '0';
                    checksum_invalid <= '0';
                    last_byte_reg <= (others => '0');
                    
                when START_BIT =>

                    
                when LOAD_B0 =>
                    if rx_elapsed_time_cntr = 3*uart_period/2 then
                        
                        last_byte_reg(0) <= rx_edge_detect(0);
                        byte_sum<= byte_sum+resize(unsigned(rx_edge_detect(0 downto 0)), 8);
                    end if;
                when LOAD_B1 =>
                    
                    if rx_elapsed_time_cntr = 5*uart_period/2 then
                        last_byte_reg(1) <= rx_edge_detect(0);
                        byte_sum<= byte_sum+resize(unsigned(rx_edge_detect(0 downto 0)), 8);
                        end if;
                when LOAD_B2 =>
                    
                    if rx_elapsed_time_cntr = 7*uart_period/2 then
                        last_byte_reg(2) <= rx_edge_detect(0);
                        byte_sum<= byte_sum+resize(unsigned(rx_edge_detect(0 downto 0)), 8);
                    end if;
                when LOAD_B3 =>
                    
                    if rx_elapsed_time_cntr = 9*uart_period/2 then
                        last_byte_reg(3) <= rx_edge_detect(0);
                        byte_sum<= byte_sum+resize(unsigned(rx_edge_detect(0 downto 0)), 8);
                    end if;
                when LOAD_B4 =>
                    
                    if rx_elapsed_time_cntr = 11*uart_period/2 then
                        last_byte_reg(4) <= rx_edge_detect(0);
                        byte_sum<= byte_sum+resize(unsigned(rx_edge_detect(0 downto 0)), 8);
                    end if;
                when LOAD_B5 =>
                    
                    if rx_elapsed_time_cntr = 13*uart_period/2 then
                        last_byte_reg(5) <= rx_edge_detect(0);
                        byte_sum<= byte_sum+resize(unsigned(rx_edge_detect(0 downto 0)), 8);
                    end if;
                when LOAD_B6 =>
                    
                    if rx_elapsed_time_cntr = 15*uart_period/2 then
                        last_byte_reg(6) <= rx_edge_detect(0);
                        byte_sum<= byte_sum+resize(unsigned(rx_edge_detect(0 downto 0)), 8);
                    end if;
                when LOAD_B7 =>
                    
                    if rx_elapsed_time_cntr = 17*uart_period/2 then
                        last_byte_reg(7) <= rx_edge_detect(0);
                        byte_sum<= byte_sum+resize(unsigned(rx_edge_detect(0 downto 0)), 8);
                    end if;
                when CHECKSUM =>
                    
                    if rx_elapsed_time_cntr = 19*uart_period/2 then
                        new_bt_flag<='1';
                        last_byte <= last_byte_reg;

                        if byte_sum(0) /= rx_edge_detect(0) then
                            checksum_invalid <= '1';
                        else
                            checksum_invalid <= '0';
                        end if;
                    end if;
                    
                when STOP_BIT =>
                    new_bt_flag<='0';
                        
            end case;
        end if;
    end process;
--this process changes next_state signal when elapsed time counter reaches value corresponding to start of the next bit(for current baudrate)
    process(current_state, rx_elapsed_time_cntr,rx_cntr_active_flag)
    begin
        next_state <= current_state;
        case current_state is
                when IDLE =>
                    if rx_cntr_active_flag ='1'  then
                        next_state <= START_BIT;
                    end if;
                when START_BIT =>
                    if rx_elapsed_time_cntr = uart_period then
                        next_state <= LOAD_B0;
                    end if;
                    if rx_cntr_active_flag = '0' then
                        next_state<= IDLE;
                    end if;
                when LOAD_B0 =>
                    if rx_elapsed_time_cntr = 2*uart_period then
                        next_state <= LOAD_B1;
                    end if;
                when LOAD_B1 =>
                    if rx_elapsed_time_cntr = 3*uart_period then
                        next_state <= LOAD_B2;
                    end if;
                when LOAD_B2 =>
                    if rx_elapsed_time_cntr = 4*uart_period then
                        next_state <= LOAD_B3;
                    end if;
                when LOAD_B3 =>
                    if rx_elapsed_time_cntr = 5*uart_period then
                        next_state <= LOAD_B4;
                    end if;
                when LOAD_B4 =>
                    if rx_elapsed_time_cntr = 6*uart_period then
                        next_state <= LOAD_B5;
                    end if;
                when LOAD_B5 =>
                    if rx_elapsed_time_cntr = 7*uart_period then
                        next_state <= LOAD_B6;
                    end if;
                when LOAD_B6 =>
                    if rx_elapsed_time_cntr = 8*uart_period then
                        next_state <= LOAD_B7;
                    end if;
                when LOAD_B7 =>
                    if rx_elapsed_time_cntr = 9*uart_period then
                        next_state <= CHECKSUM;
                    end if;
                when CHECKSUM =>
                    if rx_elapsed_time_cntr = 10*uart_period then
                        next_state <= STOP_BIT;
                    end if;
                when STOP_BIT =>
                    if rx_cntr_active_flag ='0' then
                        next_state <= IDLE;
                    end if;
            end case;
    end process;
end Behavioral;
