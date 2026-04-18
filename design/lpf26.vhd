----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.03.2026 13:48:16
-- Design Name: 
-- Module Name: lpf26 - Behavioral
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

entity lpf is 
Port(
    clk : in std_logic;
    reset : in std_logic;
    byte_in : in std_logic_vector(7 downto 0);
    new_bt_in_flag :in std_logic;
    byte_out : out std_logic_vector(6 downto 0);
    new_bt_out_flag : out std_logic;
    byte_out_nofiltr : out std_logic_vector(6 downto 0);
    new_bt_out_flag_nofiltr : out std_logic
);
end lpf;

architecture Behavioral of lpf is

type coeffisients is array (25 downto 0 ) of signed(7 downto 0);
--these coefficients correspond to low FIR pass filter with 26 taps with sampling frequency at 500 Hz and cutof frequency at 20 Hz
constant lpf_coefs : coeffisients:=(
    25 => to_signed(  0, 8),
    24 => to_signed( -1, 8),
    23 => to_signed( -1, 8),
    22 => to_signed(  0, 8),
    21 => to_signed(  1, 8),
    20 => to_signed(  2, 8),
    19 => to_signed(  3, 8),
    18 => to_signed(  6, 8),
    17 => to_signed(  8, 8),
    16 => to_signed( 10, 8),
    15 => to_signed( 11, 8),
    14 => to_signed( 12, 8),
    13 => to_signed( 13, 8),
    12 => to_signed( 13, 8),
    11 => to_signed( 12, 8),
    10 => to_signed( 11, 8),
     9 => to_signed( 10, 8),
     8 => to_signed(  8, 8),
     7 => to_signed(  6, 8),
     6 => to_signed(  3, 8),
     5 => to_signed(  2, 8),
     4 => to_signed(  1, 8),
     3 => to_signed(  0, 8),
     2 => to_signed( -1, 8),
     1 => to_signed( -1, 8),
     0 => to_signed(  0, 8)
);

type samples is array (25 downto 0) of signed(7 downto 0);
signal lpf_samples : samples:=(others=>(others=>'0'));
signal byte_in_last_val : std_logic; 
signal byte_in_flag : std_logic;

type prod_arr is array (25 downto 0) of signed(15 downto 0);
signal product : prod_arr:=(others=>(others=>'0'));

type sum_arr is array (12 downto 0) of signed(16 downto 0);
--array for adding up products
signal sum1 : sum_arr;

type sum2_arr is array (5 downto 0) of signed(17 downto 0);
--array for adding up sum1 
signal sum2 : sum2_arr;

--array for adding up sum2
signal sum3_0 : signed(18 downto 0);
signal sum3_1 : signed(18 downto 0);
signal sum3_2 : signed(18 downto 0);

--array for adding up sum3
signal sum4_0 : signed(19 downto 0);
signal sum4_1 : signed(19 downto 0);

signal sum_tot : signed(20 downto 0);
signal sum_tot_scaled : signed(8 downto 0);
signal samples_cntr : signed(5 downto 0);
signal output_valid : std_logic;

signal count_cycle_active : std_logic:='0';
signal case_counter: integer range 0 to 7:=0;



signal byte_out_nofiltr_signed : signed(8 downto 0);

begin
--this process scales/rounds unfiltered samples from signed 8 bit signal to unsigned 7 bit signal and shifts them out
process(byte_out_nofiltr_signed)
begin
    if (byte_out_nofiltr_signed > 0 and byte_out_nofiltr_signed < 256) then
        byte_out_nofiltr<= std_logic_vector(byte_out_nofiltr_signed(7 downto 1));
    elsif byte_out_nofiltr_signed >=256 then
       byte_out_nofiltr<="1111111";
    else
        byte_out_nofiltr<="0000000";
    end if ;
    
end process;

process(clk)
begin
	if rising_edge(clk) then
	byte_in_last_val<= new_bt_in_flag;
	end if;
end process;

byte_in_flag<= (not byte_in_last_val) and new_bt_in_flag;

--this process samples input 8 bit vector, calculates filter response and scales it to appropriate format
process(clk,reset)
begin
    if reset = '1' then
        samples_cntr<= (others=>'0');
        output_valid<= '0';
        new_bt_out_flag<= '0';
        byte_out<=(others=> '0');
        product <=(others=>(others=>'0'));
        lpf_samples<=(others=>(others=>'0'));
        sum1<=(others=>(others=>'0'));
        sum2 <=(others=>(others=>'0'));
       

        sum3_0 <=(others=>'0');
        sum3_1 <=(others=>'0');
        sum3_2 <=(others=>'0');

        sum4_0 <=(others=>'0');
        sum4_1 <=(others=>'0');

        sum_tot <=(others=>'0');
        sum_tot_scaled<=(others=> '0');
        
       
    else
        if rising_edge(clk) then    
            if count_cycle_active = '0' then
                new_bt_out_flag<= '0';
                new_bt_out_flag_nofiltr<='0';
                if byte_in_flag = '1' then
                    if samples_cntr < 26 then
                        --we're counting samples being shifted into the filter because filter output is not valid until at least 26 samples arrived 
                        samples_cntr<= samples_cntr+1;
                        output_valid<= '0';
                    else
                        output_valid<= '1';
                        count_cycle_active<= '1';
                    end if ;
                    lpf_samples(0) <= signed(byte_in);
                    for i in 1 to 25 loop
                        lpf_samples(i) <= lpf_samples(i-1);                
                    end loop ;
                    
                    if output_valid = '1' then
                        byte_out_nofiltr_signed<= resize(lpf_samples(12), 9) + to_signed(128, 9);
                        new_bt_out_flag_nofiltr<= '1';
                    end if;
                end if ;
            else
                --between next arriving bytes we're calculating the filter response
                --even with the fastest posiible uart baudrate receiving one byte from rx will be slower than calculating filter response
                case( case_counter ) is
                
                    when 0 =>
                       for j in 0 to 25 loop
                        product(j)<= lpf_coefs(j) * lpf_samples(j);
                        end loop; 
                        case_counter<= case_counter+1;
                    when 1 =>
                        for k in 0 to 12 loop
                        sum1(k) <= resize(product(2*k),17)+resize(product(2*k+1),17);    
                        end loop;
                        case_counter<= case_counter+1;
                    when 2 =>
                        for l in 0 to 5 loop
                            sum2(l)<=resize(sum1(2*l),sum2(l)'length)+resize(sum1(2*l+1),sum2(l)'length);
                        end loop;
                        case_counter<= case_counter+1;
                    when 3=>
                        sum3_0<= resize(sum2(0),sum3_0'length) + resize(sum2(1),sum3_0'length);
                        sum3_1<= resize(sum2(2),sum3_1'length)+  resize(sum2(3),sum3_1'length);
                        sum3_2<= resize(sum2(4),sum3_2'length) + resize(sum2(5),sum3_2'length);
                        --sum3_3<= resize(sum2(6),sum3_1'length)+  resize(sum1(14),sum3_1'length);
                        case_counter<= case_counter+1;
                    when 4=>
                        sum4_0<= resize(sum3_0,sum4_0'length) + resize(sum3_1,sum4_0'length);
                        sum4_1<= resize(sum3_2,sum4_1'length) + resize(sum1(12),sum4_1'length);
                        case_counter<= case_counter+1;
                    when 5=>
                        sum_tot<= resize(sum4_0,sum_tot'length) + resize(sum4_1,sum_tot'length);
                        case_counter<= case_counter+1;
                    when 6=>
                        --we're changing signed sum of all components into unsigned(positive) 9 bit value
                        sum_tot_scaled <= resize(shift_right(sum_tot, 8), 9) + to_signed(64, 9);
                        case_counter<= case_counter+1;
                    when 7=>
                        --we're further scaling 9 bit signed vector into 7 bit unsigned vector and checking for overflow
                        if sum_tot_scaled < 0 then
                            byte_out<= "0000000";

                        elsif sum_tot_scaled > 255 then
                            byte_out<= "1111111";
                        else 
                            byte_out <= std_logic_vector(sum_tot_scaled(6 downto 0));
                        end if ;
                    
                    new_bt_out_flag<= '1';
                    case_counter<= 0;
                    count_cycle_active<= '0';
                end case ;
            end if ;
        end if;
    end if;
end process;

end Behavioral;
