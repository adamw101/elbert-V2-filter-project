--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:30:12 04/03/2026
-- Design Name:   
-- Module Name:   /home/adam/top/top_tb.vhd
-- Project Name:  top
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: top
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
 use std.env.finish;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 library std;
use std.textio.all;



ENTITY top_tb IS
END top_tb;
 
ARCHITECTURE behavior OF top_tb IS 
 file stimulus : text open read_mode is ("input_data.csv");
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top
    PORT(
         clk_12mhz : IN  std_logic;
         reset : IN  std_logic;
         tx : OUT  std_logic;
         rx : IN  std_logic;
         red : OUT  std_logic_vector(2 downto 0);
         green : OUT  std_logic_vector(2 downto 0);
         blue : OUT  std_logic_vector(1 downto 0);
			h_sync          : out std_logic;
			v_sync          : out std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_12mhz_tb : std_logic := '0';
   signal reset_tb : std_logic := '0';
   signal rx_tb : std_logic := '0';

 	--Outputs
   signal tx_tb : std_logic;
   signal red_tb : std_logic_vector(2 downto 0);
   signal green_tb : std_logic_vector(2 downto 0);
   signal blue_tb : std_logic_vector(1 downto 0);
	signal h_sync_tb : std_logic;
	signal v_sync_tb : std_logic;

   -- Clock period definitions
   constant clk_12mhz_period : time := 83.333 ns;
   -------------------------------------
   --signals for simulation
   constant period_25mhz : time := 40 ns;
   constant uart_period : time :=8681 ns;
   signal clk_25mhz : std_logic;
   signal clk25start : std_logic:='0';
   signal case_counter: integer range 1 to 2:=1;
   procedure feed_byte(constant byte : in std_logic_vector(7 downto 0);
							constant period : in time;
							signal data_out : out std_logic
							) is
 begin
   --start bit
      data_out<= '0';
      wait for period;
      --b0
      data_out<= byte(0);
      wait for period;   
      --b1
      data_out<= byte(1);
      wait for period;   
      --b2
      data_out<= byte(2);
      wait for period;   
      --b3
      data_out<= byte(3);
      wait for period;   
      --b4
      data_out<= byte(4);
      wait for period;   
      --b5
      data_out<= byte(5);
      wait for period;   
      --b6
      data_out<= byte(6);
      wait for period;   
      --b7
      data_out<= byte(7);
      wait for period;   
      --checksum
      if byte(0) = '0' then
         data_out<= '1';
      else
         data_out<= '0';
      end if ;
      
      wait for period;
      --stop bit
      data_out<= '1';
      wait for period;
 end procedure; 

BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top PORT MAP (
          clk_12mhz => clk_12mhz_tb,
          reset => reset_tb,
          tx => tx_tb,
          rx => rx_tb,
          red => red_tb,
          green => green_tb,
          blue => blue_tb,
			 h_sync=> h_sync_tb,
			 v_sync=> v_sync_tb
        );
	process is
      variable input_byte : bit_vector(7 downto 0);
      variable input_line :line;
	begin
      reset_tb <= '1';
      rx_tb<= '1';
      wait for 1000ns;
      reset_tb<= '0';
      wait for 1000ns;
      while (not endfile(stimulus)) loop
           readline(stimulus,input_line);
           read(input_line,input_byte);
           feed_byte(to_stdlogicvector(input_byte),uart_period,rx_tb);


        end loop;
        --assert (false) report "Reading operation completed!" severity failure;
      wait for 50ms;
        finish;
	end process;
   -- Clock process definitions
   clk_12mhz_process :process
   begin
		clk_12mhz_tb <= '0';
		wait for clk_12mhz_period/2;
		clk_12mhz_tb <= '1';
		wait for clk_12mhz_period/2;
   end process;

    clk_25mhz_process :process
   begin
      if now >= 1874.970 ns then
		   clk_25mhz <= '0';
		   wait for period_25mhz/2;
		   clk_25mhz <= '1';
		   wait for period_25mhz/2;
      else
         wait for 1874.970 ns;
      end if;
   end process;

    save_output_process: process(clk_25mhz)
    variable output_line : line;
    variable file_cntr : integer:=0;
    variable write_cycle_acive : bit := '0';
    variable one : bit := '1';
    variable zero : bit := '0';
    file output_data : text open write_mode is ("screen.txt");

    begin
       if rising_edge(clk_25mhz) then
          case( case_counter ) is
             when 1 =>
                if v_sync_tb = '1' and h_sync_tb = '1' then
                  
                      output_line := null;
                      writeline(output_data,output_line);
                      writeline(output_data,output_line);
                      writeline(output_data,output_line);
                      report "new page";
                      case_counter<=2;
                  
                end if;

               
             when 2 =>
                   if v_sync_tb = '0' and h_sync_tb = '0' then
                      if green_tb(0) = '1' then
                         write(output_line,one,left,1);
                      else
                         write(output_line,zero,left,1);
                      end if;
                      --report "saved bit";
                   elsif v_sync_tb = '0' and h_sync_tb = '1' then 
                      if output_line /=null then
                         writeline(output_data,output_line);
                         --report "wrote line";
                      end if;   
                   elsif v_sync_tb = '1' and h_sync_tb = '1' and output_line /=null then
                      case_counter<=1;
                   end if;
          end case ;
      end if;
   end process;

END;
