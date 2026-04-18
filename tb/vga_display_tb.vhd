-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

  library UNISIM;
  use UNISIM.VComponents.all;
  use std.env.finish;


  ENTITY testbench IS
  END testbench;

  ARCHITECTURE behavior OF testbench IS 

  -- Component Declaration
          COMPONENT vga_display
          PORT(
                clk : in std_logic;
                reset     : in std_logic;
                v_sync    : out std_logic;
                h_sync    : out std_logic;
                blue      : out std_logic_vector(1 downto 0);
                green     : out std_logic_vector(2 downto 0);
                red     : out std_logic_vector(2 downto 0);
		    dpra      : out std_logic_vector(8 downto 0);
		    dpo       : in std_logic_vector(7 downto 0)
                  );
          END COMPONENT;

          component bram is
            port (clk : in std_logic;
                  we : in std_logic;
                  a : in std_logic_vector(8 downto 0);
                  dpra : in std_logic_vector(8 downto 0);
                  di : in std_logic_vector(7 downto 0);
                  dpo : out std_logic_vector(7 downto 0));
            end component;

            component uart_transceiver is
            Port ( 
                clk  : in std_logic;  
                reset       : in std_logic;
                tx          : out std_logic;
                rx          : in std_logic;
                last_byte   : out std_logic_vector(7 downto 0);
                new_bt_flag : out std_logic 

            );    
            end component;

      signal tx_tb : std_logic;
      signal rx_tb : std_logic;
      signal last_byte_tb : std_logic_vector(7 downto 0);
      signal new_bt_flag_tb : std_logic;
      signal we_tb : std_logic;
      signal a_tb : std_logic_vector(8 downto 0);
      
      signal di_tb : std_logic_vector(7 downto 0);
      signal dpo_tb : std_logic_vector(7 downto 0);

	signal clk_tb  :  std_logic;
      signal reset_tb       :  std_logic;
      signal v_sync_tb         :  std_logic;
      signal h_sync_tb         :  std_logic;
      signal blue_tb           : std_logic_vector(1 downto 0);
      signal red_tb           : std_logic_vector(2 downto 0);
      signal green_tb           : std_logic_vector(2 downto 0);
      signal dpra_tb      :  std_logic_vector(8 downto 0);
      
          
        constant clock_period : time := 83.333 ns;

      ------------------------------
      signal clk_ibufg : std_logic;
      signal clk_dcm_out : std_logic;
      signal clk_int : std_logic;

      signal dcm_rst : std_logic;
      signal dcm_status : std_logic_vector(7 downto 0);
      signal dcm_locked: std_logic;
      signal dcm_clkfx_stopped : std_logic;--= dcm_status[2];
      --------------------------------------
      signal prev_val_new_byte_flag : std_logic;
      signal write_byte_flag : std_logic;
      signal write_byte_index : unsigned(8 downto 0);
  BEGIN
      dcm_clkfx_stopped <= dcm_status(2);
	dcm_rst <= reset_tb;

    IBUFG_inst : IBUFG
    generic map (
        IBUF_DELAY_VALUE => "0", -- Specify the amount of added input delay for buffer, "0"-"16" (Spartan-3E    only)
        IOSTANDARD => "DEFAULT")
    port map (
        O => clk_ibufg, -- Clock buffer output
        I => clk_tb -- Clock buffer input (connect directly to top-level port)
    );

    BUFG_inst : BUFG
    port map (
        O => clk_int, -- Clock buffer output
        I => clk_dcm_out -- Clock buffer input
    );

    -- DCM_SP: Digital Clock Manager Circuit for Spartan-3E
-- Xilinx HDL Libraries Guide Version 8.1i
    DCM_inst : DCM_SP
    generic map (
        CLKDV_DIVIDE => 2.0,--ok -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
        -- 7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
        CLKFX_DIVIDE => 3,--ok -- Can be any interger from 1 to 32
        CLKFX_MULTIPLY => 25,--ok -- Can be any Integer from 1 to 32
        CLKIN_DIVIDE_BY_2 => FALSE,--ok -- TRUE/FALSE to enable CLKIN divide by two feature
        CLKIN_PERIOD => 83.3,--ok -- Specify period of input clock
        CLKOUT_PHASE_SHIFT => "NONE",--ok -- Specify phase shift of NONE, FIXED or VARIABLE
        CLK_FEEDBACK => "NONE",--ok -- Specify clock feedback of NONE, 1X or 2X
        DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS",--ok   -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
        -- an Integer from 0 to 15
        DFS_FREQUENCY_MODE => "LOW",--ok -- HIGH or LOW frequency mode for frequency synthesis
        DLL_FREQUENCY_MODE => "LOW",--ok -- HIGH or LOW frequency mode for DLL
        DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
        FACTORY_JF => X"C080",--ok -- FACTORY JF Values
        PHASE_SHIFT => 0,--ok -- Amount of fixed phase shift from -255 to 255
        STARTUP_WAIT => FALSE)--ok -- Delay configuration DONE until DCM_SP LOCK, TRUE/FALSE
    port map (
        CLK0 => open, --ok-- 0 degree DCM_SP CLK ouptput
        CLK180 => open, --ok-- 180 degree DCM_SP CLK output
        CLK270 => open, --ok-- 270 degree DCM_SP CLK output
        CLK2X => open,--ok -- 2X DCM_SP CLK output
        CLK2X180 => open, --ok-- 2X, 180 degree DCM_SP CLK out
        CLK90 => open, --ok-- 90 degree DCM_SP CLK output
        CLKDV => open,--ok -- Divided DCM_SP CLK out (CLKDV_DIVIDE)
        CLKFX => clk_dcm_out,--ok -- DCM_SP CLK synthesis out (M/D)
        CLKFX180 => open,--ok -- 180 degree CLK synthesis out
        LOCKED => dcm_locked,--ok -- DCM_SP LOCK status output
        PSDONE => open,--ok -- Dynamic phase adjust done output
        STATUS => dcm_status,--ok -- 8-bit DCM_SP status bits output
        CLKFB => '0',--ok -- DCM_SP clock feedback
        CLKIN => clk_ibufg,--ok -- Clock input (from IBUFG, BUFG or DCM_SP)
        PSCLK => '0',--ok -- Dynamic phase adjust clock input
        PSEN => '0',--ok -- Dynamic phase adjust enable input
        PSINCDEC => '0',--ok -- Dynamic phase adjust increment/decrement
        RST => dcm_rst--ok -- DCM_SP asynchronous reset input
    );



  -- Component Instantiation
          uut: vga_display PORT MAP(
                clk=>clk_int,
                reset=>reset_tb,    
                v_sync=>v_sync_tb,   
                h_sync=>h_sync_tb,   
                blue=>blue_tb,     
                green=>green_tb,    
                red=>red_tb,
                dpra=> dpra_tb,
                dpo=> dpo_tb    
          );
            
          
          bram_block: bram port map (clk=> clk_int, 
                  we=>we_tb, 
                  a=>a_tb, 
                  dpra=>dpra_tb, 
                  di=>di_tb, 
                  dpo=>dpo_tb);
            
          uart_block : uart_transceiver port map(
                  clk=>clk_int,
                  reset=> reset_tb,       
                  tx=>tx_tb,          
                  rx=>rx_tb,          
                  last_byte=>last_byte_tb,
                  new_bt_flag=>new_bt_flag_tb
          );

        process is
        begin
                clk_tb<= '0';
                wait for clock_period/2;
                clk_tb<= '1';
                wait for clock_period/2;
        end process;


      process(clk_int)
      begin
          if rising_edge(clk_int) then
              prev_val_new_byte_flag<= new_bt_flag_tb;
          end if;
      end process;
          write_byte_flag <= (not prev_val_new_byte_flag) and new_bt_flag_tb;

      write_uart_to_bram: process(clk_int,reset_tb)
      begin
      if reset_tb = '1' then
            we_tb<= '0';
            a_tb<= (others=> '0');
            di_tb <= (others=> '0');
            write_byte_index<= (others=>'0');
      else
          if rising_edge(clk_int) then
              if write_byte_flag = '1' then
                  we_tb <= '1';
                  a_tb<=  std_logic_vector(write_byte_index);
                  di_tb <= last_byte_tb;
                  if(write_byte_index < 499) then
                      write_byte_index <= write_byte_index +1;
                  else
                      write_byte_index <= to_unsigned(0,9);
                  end if;
              else
                  we_tb <= '0';
              end if ;
          end if ;
      end if ;
      end process write_uart_to_bram;
  --  Test Bench Statements
--      tb : PROCESS
--      BEGIN
--         reset_tb<= '1';
--         we_tb<= '0';
-- 		  a_tb<= "000000000";
--         wait for 1000 ns; -- wait until global set/reset completes
--         reset_tb<= '0';
--         -- Add user defined stimulus here

--         wait ; -- will wait forever
--      END PROCESS tb;
      process is
            begin
                reset_tb <= '1';
                rx_tb<= '1';
                --we_tb<= '0';
 		    --a_tb<= "000000000";
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
  --  End Test Bench 

  END;
