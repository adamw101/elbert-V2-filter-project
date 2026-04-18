--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:52:24 04/13/2026
-- Design Name:   
-- Module Name:   /home/adam/lpf/lpf_tb.vhd
-- Project Name:  lpf
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: lpf
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY lpf_tb IS
END lpf_tb;
 
ARCHITECTURE behavior OF lpf_tb IS 
-------------
--files
file stimulus : text open read_mode is ("sinus.csv");
file output_data : text open write_mode is ("output.csv");
 
    COMPONENT lpf
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         byte_in : IN  std_logic_vector(7 downto 0);
         new_bt_in_flag : IN  std_logic;
         byte_out : OUT  std_logic_vector(6 downto 0);
         new_bt_out_flag : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal byte_in : std_logic_vector(7 downto 0) := (others => '0');
   signal new_bt_in_flag : std_logic := '0';

 	--Outputs
   signal byte_out : std_logic_vector(6 downto 0);
   signal new_bt_out_flag : std_logic;
   signal new_bt_out_flag_last_val : std_logic;
   signal output_byte_cntr: integer:=0;
   -- Clock period definitions
   constant clk_period : time := 10 ns;
   
   procedure feed_byte(constant byte : in std_logic_vector(7 downto 0);
   						  constant delay : in time;
   						  signal data_out : out std_logic_vector(7 downto 0);
   						  signal data_ready : out std_logic) is
   begin
      data_ready<='1';
      data_out<= byte;
      wait for delay;
      data_ready<='0';
      wait for delay;
   end procedure; 
BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: lpf PORT MAP (
          clk => clk,
          reset => reset,
          byte_in => byte_in,
          new_bt_in_flag => new_bt_in_flag,
          byte_out => byte_out,
          new_bt_out_flag => new_bt_out_flag
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   process(clk,new_bt_out_flag_last_val,new_bt_out_flag)
      variable output_line : line;
   begin
      if rising_edge(clk) then
         new_bt_out_flag_last_val<=new_bt_out_flag;
         if new_bt_out_flag_last_val='0' and new_bt_out_flag='1' then
            output_byte_cntr<= output_byte_cntr+1;
            write(output_line,to_integer(unsigned(byte_out)),left,7);
            writeline(output_data,output_line);
            report "Bytes written: " & integer'image(output_byte_cntr+1);
         end if ;
      end if ;
      
   end process;

   -- Stimulus process
   stim_proc: process
   variable input_byte : integer;
   variable input_line :line;
   variable bit_input_v : bit;
   variable bit_input : bit_vector(7 downto 0);
   begin		

		reset<= '1';
      wait for 100 ns;	
		reset<= '0';
      wait for clk_period*10;
      while (not endfile(stimulus)) loop
         readline(stimulus,input_line);
         read(input_line,input_byte);
         
         feed_byte(std_logic_vector(to_signed(input_byte,8)),10*clk_period,byte_in,new_bt_in_flag);
         
      end loop;
      assert (false) report "Reading operation completed!" severity failure;

      wait;
   end process;

END;
