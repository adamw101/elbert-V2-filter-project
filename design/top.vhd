----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.03.2026 13:48:16
-- Design Name: 
-- Module Name: top - Behavioral
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

entity top is
Port(
    clk_12mhz       : in  std_logic;
    reset           : in  std_logic;
    tx              : out std_logic;
    rx              : in  std_logic;
    red             : out std_logic_vector(2 downto 0);
    green           : out std_logic_vector(2 downto 0);
    blue            : out std_logic_vector(1 downto 0);
    h_sync          : out std_logic;
    v_sync          : out std_logic
);
end top;

architecture Behavioral of top is

signal last_byte_top   : std_logic_vector(7 downto 0);
signal new_bt_flag_top : std_logic;

signal byte_filt_out : std_logic_vector(6 downto 0);
signal filt_byte_flag : std_logic;
signal byte_out_nofiltr_top : std_logic_vector(6 downto 0);
signal new_bt_out_flag_nofiltr : std_logic;
signal new_bt_out_flag_nofiltr_last : std_logic;

component lpf is 
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
end component;

COMPONENT vga_display
PORT(
    clk : in std_logic;
    reset     : in std_logic;
    v_sync    : out std_logic;
    h_sync    : out std_logic;
    blue      : out std_logic_vector(1 downto 0);
    green     : out std_logic_vector(2 downto 0);
    red     : out std_logic_vector(2 downto 0);
    dpra_top      : out std_logic_vector(9 downto 0);
    dpo_top       : in std_logic_vector(6 downto 0);
    dpra_bottom      : out std_logic_vector(9 downto 0);
    dpo_bottom       : in std_logic_vector(6 downto 0)
    );
END COMPONENT;

component bram is
port (clk : in std_logic;
      we : in std_logic;
      a : in std_logic_vector(9 downto 0);
      dpra : in std_logic_vector(9 downto 0);
      di : in std_logic_vector(6 downto 0);
      dpo : out std_logic_vector(6 downto 0));
end component;

component uart_receiver is
Port ( 
    clk         : in std_logic;
    reset       : in std_logic;
    tx          : out std_logic;
    rx          : in std_logic;
    last_byte   : out std_logic_vector(7 downto 0);
    new_bt_flag : out std_logic;
    checksum_invalid : out std_logic 

);
end component;
    --signal tx_top : std_logic;
    --signal rx_top : std_logic;

    signal we_bottom : std_logic;
    signal a_bottom : std_logic_vector(9 downto 0);    
    signal di_bottom : std_logic_vector(6 downto 0);
    signal dpo_bottom : std_logic_vector(6 downto 0):="0000000";
    signal dpra_bottom : std_logic_vector(9 downto 0);

    signal we_top : std_logic;
    signal a_top : std_logic_vector(9 downto 0);    
    signal di_top : std_logic_vector(6 downto 0);
    signal dpo_top : std_logic_vector(6 downto 0):="0000000";
    signal dpra_top : std_logic_vector(9 downto 0);

 ------------------------------
    signal clk_ibufg : std_logic;
    signal clk_dcm_out : std_logic;
    signal clk_int : std_logic;

    signal dcm_rst : std_logic;
    signal dcm_status : std_logic_vector(7 downto 0);
    signal dcm_locked: std_logic;
    signal dcm_clkfx_stopped : std_logic;
--------------------------------------
    signal prev_val_new_byte_flag : std_logic;
    signal write_byte2_flag : std_logic;
    signal write_byte1_flag : std_logic;
    signal write_byte_top_index : unsigned(9 downto 0);
    signal write_byte_bottom_index : unsigned(9 downto 0);
    type fsm_state is  (IDLE,SUPPLY_ADDR_DATA,ASSERT_WE);
	signal state1 : fsm_state := IDLE;
    signal state2 : fsm_state := IDLE;
begin


--ussually to produce one clock frequency from another we would use a clocking wizard.
--unfortunately we're using legacy fpga and software so this is not an option anymore
--we're manually instantiating dcm(digital clock manager) block and setting it up to produce 100Mhz clock from 12Mhz oscilator on the board 
dcm_clkfx_stopped <= dcm_status(2);
dcm_rst <= reset;

    IBUFG_inst : IBUFG
    generic map (
        IBUF_DELAY_VALUE => "0", -- Specify the amount of added input delay for buffer, "0"-"16" (Spartan-3E    only)
        IOSTANDARD => "DEFAULT")
    port map (
        O => clk_ibufg, -- Clock buffer output
        I => clk_12mhz -- Clock buffer input (connect directly to top-level port)
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

lpf_block: lpf PORT MAP (
         clk => clk_int,
         reset => reset,
         byte_in => last_byte_top,
         new_bt_in_flag => new_bt_flag_top,
         byte_out => byte_filt_out,
         new_bt_out_flag => filt_byte_flag,
         byte_out_nofiltr => byte_out_nofiltr_top,
         new_bt_out_flag_nofiltr => new_bt_out_flag_nofiltr
       );

vga_block: vga_display PORT MAP(
    clk=>clk_int,
    reset=>reset,    
    v_sync=>v_sync,   
    h_sync=>h_sync,   
    blue=>blue,     
    green=>green,    
    red=>red,
    dpra_top=> dpra_top,
    dpo_top=> dpo_top    ,
    dpra_bottom=> dpra_bottom,
    dpo_bottom => dpo_bottom
);

bram_block_1: bram port map (
    clk=> clk_int, 
    we=>we_top, 
    a=>a_top, 
    dpra=>dpra_top, 
    di=>di_top, 
    dpo=>dpo_top);

    ---------------------

bram_block_2: bram port map (
    clk=> clk_int, 
    we=>we_bottom, 
    a=>a_bottom, 
    dpra=>dpra_bottom, 
    di=>di_bottom, 
    dpo=>dpo_bottom);

    ---------------------


uart_block: uart_receiver
port map(
    clk=>clk_int,  
    reset=>reset,      
    tx=> tx,         
    rx=> rx,         
    last_byte=> last_byte_top,  
    new_bt_flag=>new_bt_flag_top,
    checksum_invalid=> open
);
 
--process for detecting new bytes from filter module
process(clk_int)
      begin
          if rising_edge(clk_int) then
              prev_val_new_byte_flag<= filt_byte_flag;
              new_bt_out_flag_nofiltr_last<= new_bt_out_flag_nofiltr;
          end if;
      end process;
          write_byte2_flag <= (not prev_val_new_byte_flag) and filt_byte_flag;
          write_byte1_flag<=  (not new_bt_out_flag_nofiltr_last) and new_bt_out_flag_nofiltr;


--this process saves unfiltered data from filter module to top plot bram
write_data_top_plot: process(clk_int,reset)
begin
    if reset ='1' then
        state1 <= IDLE;
        write_byte_top_index <= (others => '0');
        we_top<= '0';
        a_top<= (others=> '0');
        di_top <= (others=> '0');
    else
        if rising_edge(clk_int) then
            we_top<='0';
            --we're first supplying data and address to bram and only then asserting write enable
            case( state1 ) is
                
                when IDLE =>
                    
                    if write_byte1_flag = '1' then
                        state1<= SUPPLY_ADDR_DATA;
                    end if ;
            
                when SUPPLY_ADDR_DATA =>
                    a_top<=  std_logic_vector(write_byte_top_index);
                    di_top <= byte_out_nofiltr_top;

                    state1<= ASSERT_WE;
                when ASSERT_WE =>
                    we_top<= '1';
                    if(write_byte_top_index < 622) then
                         write_byte_top_index <= write_byte_top_index +1;
                     else
                         write_byte_top_index <= to_unsigned(0,10);
                     end if;

                    state1<= IDLE;
            end case ;
        end if;
    end if ;

end process write_data_top_plot;

--this process saves filtered data from filter module to bottom plot bram
write_data_bottom_plot: process(clk_int,reset)
begin
    if reset ='1' then
        state2 <= IDLE;
        write_byte_bottom_index <= (others => '0');
        we_bottom<= '0';
        a_bottom<= (others=> '0');
        di_bottom <= (others=> '0');
    else
        if rising_edge(clk_int) then
            we_bottom<='0';
            --we're first supplying data and address to bram and only then asserting write enable
            case( state2 ) is
                
                when IDLE =>
                    
                    if write_byte2_flag = '1' then
                        state2<= SUPPLY_ADDR_DATA;
                    end if ;
            
                when SUPPLY_ADDR_DATA =>
                    a_bottom<=  std_logic_vector(write_byte_bottom_index);
                    di_bottom <= byte_filt_out;

                    state2<= ASSERT_WE;
                when ASSERT_WE =>
                    we_bottom<= '1';
                    if(write_byte_bottom_index < 622) then
                         write_byte_bottom_index <= write_byte_bottom_index +1;
                     else
                         write_byte_bottom_index <= to_unsigned(0,10);
                     end if;

                    state2<= IDLE;
            end case ;
        end if;
    end if ;

end process write_data_bottom_plot;



end Behavioral;