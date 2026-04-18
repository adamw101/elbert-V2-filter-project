----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    06:57:47 03/30/2026 
-- Design Name: 
-- Module Name:    vga_display - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

--this module reads values of filtered and unfiltered signals and drives vga signal accordingly
--drawing both plots, titles and frames


entity vga_display is
    port(
    clk         : in  std_logic;
    reset       : in  std_logic;
    v_sync      : out std_logic;
    h_sync      : out std_logic;
    blue        : out std_logic_vector(1 downto 0);
    green       : out std_logic_vector(2 downto 0);
    red         : out std_logic_vector(2 downto 0);
    dpra_top    : out std_logic_vector(9 downto 0);
    dpo_top     : in  std_logic_vector(6 downto 0);
    dpra_bottom : out std_logic_vector(9 downto 0);
    dpo_bottom  : in  std_logic_vector(6 downto 0)
    );
end vga_display;

architecture Behavioral of vga_display is

    type title1 is array (42 downto 0) of std_logic_vector(4 downto 0);
    --title top is an array storing values representing 43 bits wide by 5 bits tall title saying "filter input"
    constant title_top : title1:=(
        42=>"11111",
        41=>"10100",
        40=>"10100",
        39=>"00000",
        38=>"11111",
        37=>"00000",
        36=>"11111",
        35=>"00001",
        34=>"00001",
        33=>"00000",
        32=>"10000",
        31=>"11111",
        30=>"10000",
        29=>"00000",
        28=>"11111",
        27=>"10101",
        26=>"10101",
        25=>"00000",
        24=>"11111",
        23=>"10100",
        22=>"11010",
        21=>"00001",
        20=>"00000",
        19=>"00000",
        18=>"11111",
        17=>"00000",
        16=>"11111",
        15=>"01000",
        14=>"00100",
        13=>"00010",
        12=>"11111",
        11=>"00000",
        10=>"11111",
        9 =>"10100",
        8 =>"11100",
        7 =>"00000",
        6 =>"11111",
        5 =>"00001",
        4 =>"11111",
        3 =>"00000",
        2 =>"10000",
        1 =>"11111",
        0 =>"10000"        
    );

    type title2 is array (46 downto 0) of std_logic_vector(4 downto 0);
    --title top is an array storing values representing 47 bits wide by 5 bits tall title saying "filter output"
    constant title_bottom : title2:=(
        46=>"11111",
        45=>"10100",
        44=>"10100",
        43=>"00000",
        42=>"11111",
        41=>"00000",
        40=>"11111",
        39=>"00001",
        38=>"00001",
        37=>"00000",
        36=>"10000",
        35=>"11111",
        34=>"10000",
        33=>"00000",
        32=>"11111",
        31=>"10101",
        30=>"10101",
        29=>"00000",
        28=>"11111",
        27=>"10100",
        26=>"11010",
        25=>"00001",
        24=>"00000",
        23=>"00000",
        22=>"11111",
        21=>"10001",
        20=>"11111",
        19=>"00000",
        18=>"11111",
        17=>"00001",
        16=>"11111",
        15=>"00000",
        14=>"10000",
        13=>"11111",
        12=>"10000",
        11=>"00000",
        10=>"11111",
        9 =>"10100",
        8 =>"11100",
        7 =>"00000",
        6 =>"11111",
        5 =>"00001",
        4 =>"11111",
        3 =>"00000",
        2 =>"10000",
        1 =>"11111",
        0 =>"10000" 
    );

    constant TOP_PLOT_VERT_BORDER_L     : unsigned := to_unsigned(102,10);
    constant TOP_PLOT_VERT_BORDER_H     : unsigned := to_unsigned(229,10);
    constant BOTTOM_PLOT_VERT_BORDER_L  : unsigned := to_unsigned(351,10);
    constant BOTTOM_PLOT_VERT_BORDER_H  : unsigned := to_unsigned(480,10);
    --horizontal borders are the same for both plots
    constant PLOT_HOR_BORDER_L          : unsigned := to_unsigned(149,10);
    constant PLOT_HOR_BORDER_r          : unsigned := to_unsigned(769,10);


    signal clk_div_cntr: std_logic_vector(1 downto 0):="00";
    signal h_cntr      : unsigned(9 downto 0):=to_unsigned(0,10);
    signal v_cntr      : unsigned(9 downto 0):=to_unsigned(0,10);
    --these two vectors store counter values delayed by one clock cycles.they're used for color adjustment
    --counters without delay generate vertical and horizontal sync signals
    signal h_cntr_r      : unsigned(9 downto 0):=to_unsigned(0,10);
    signal v_cntr_r      : unsigned(9 downto 0):=to_unsigned(0,10);

    signal color_from_uart_top : std_logic_vector(2 downto 0);
    signal color_from_uart_bottom : std_logic_vector(2 downto 0);
    signal bram_addr   : unsigned(9 downto 0);
    signal ver_index_in_top_display_area : unsigned(9 downto 0);
    signal ver_index_in_bottom_display_area : unsigned(9 downto 0);

    signal clk_active : std_logic:='0';
    
    signal top_disp_active : std_logic:='0';
    signal bottom_disp_active : std_logic:='0';
begin

    --this process iterates horizontal and vertical counters for 640x480 screen
    process(clk)
    begin
        if rising_edge(clk) then
            clk_active<= '1';
            if reset = '1' then
                h_cntr<= to_unsigned(0,10);
                v_cntr <= to_unsigned(0,10);
                clk_div_cntr<="00";
            else    
                clk_div_cntr<= std_logic_vector(unsigned(clk_div_cntr)+ 1);
                if clk_div_cntr = "00" then
                    if h_cntr < 799 then
                        h_cntr<= h_cntr+1;
                    else
                        h_cntr<= to_unsigned(0,10);
                        if v_cntr < 524 then
                            v_cntr <= v_cntr+1;
                        else
                            v_cntr <= to_unsigned(0,10);
                        end if ;

                    end if ;
                end if ;
            end if ;
        end if ;
    end process;

    --h sync and v sync generation
    process(h_cntr,v_cntr,reset)
    begin
        if reset ='1' or clk_active = '0' then
            h_sync<= '0';
            v_sync<='0';
        else
            if h_cntr < 96 then
                h_sync<= '1';
            else
                h_sync<= '0';
            end if ;

            if v_cntr < 2 then
                v_sync<= '1';
            else
                v_sync<= '0';
            end if ;
        end if ;
    end process;

    --read data from memory and pick colour. we're drawing one plot at a time so we can use one signal for calculating bram addres
    bram_addr<= (h_cntr- PLOT_HOR_BORDER_L) when (h_cntr >(PLOT_HOR_BORDER_L-to_unsigned(1,10)) and h_cntr < (PLOT_HOR_BORDER_r+1)) else to_unsigned(622,10);
    --this signal calculates coordinates inside bottom plot based on current values of horizontal and vertical counter
    ver_index_in_bottom_display_area <= (BOTTOM_PLOT_VERT_BORDER_H-to_unsigned(1,10)) - v_cntr_r when (v_cntr_r >BOTTOM_PLOT_VERT_BORDER_L and v_cntr_r <BOTTOM_PLOT_VERT_BORDER_H ) else to_unsigned(0,10);
    
    dpra_bottom<= std_logic_vector(bram_addr(9 downto 0));
    process(clk,reset)
    begin
        if rising_edge(clk) then
            if reset ='1' then
                h_cntr_r<=(others=>'0');
                v_cntr_r<=(others=>'0');
            else
                
                h_cntr_r<=h_cntr;
                v_cntr_r<=v_cntr;
            end if;
        end if;
    end process;

    --this process chooses hte color to be displayed. if we're in the top display arrea we're checking if current value read from top display bram is equal to current index insde plot arrea
    --this fpga doesn't have enough memory to store 640x480 picture so we're storing 623 7bit values and comparing them withindex value(0-127) inside the plot
    --colours for bottom plot are picked in a similar way.
    process(bram_addr, dpo_bottom, dpo_top, ver_index_in_bottom_display_area, ver_index_in_top_display_area,bottom_disp_active,top_disp_active)
    begin    
            color_from_uart_top <= "000";
            color_from_uart_bottom <= "000";
            if bram_addr /= to_unsigned(622,10)  then
                if (dpo_bottom =  std_logic_vector(ver_index_in_bottom_display_area(6 downto 0))) and bottom_disp_active ='1' then
                    color_from_uart_bottom <= "101";
                elsif  (dpo_top =  std_logic_vector(ver_index_in_top_display_area(6 downto 0))) and top_disp_active ='1' then
                    color_from_uart_top <= "101";
                else
                    color_from_uart_top <= "000";
                    color_from_uart_bottom <= "000";
                end if ;
            end if ;
    end process;

    --this signal calculates coordinates inside top plot based on current values of horizontal and vertical counter
    ver_index_in_top_display_area <= TOP_PLOT_VERT_BORDER_H - v_cntr_r when (v_cntr_r >(TOP_PLOT_VERT_BORDER_L-to_unsigned(1,10)) and v_cntr_r <(TOP_PLOT_VERT_BORDER_H+to_unsigned(1,10)) ) else to_unsigned(0,10);
   
    dpra_top<= std_logic_vector(bram_addr(9 downto 0));
    --colour adjustment
    process(h_cntr_r,v_cntr_r,reset,color_from_uart_top,color_from_uart_bottom,bottom_disp_active,top_disp_active)
    begin
        if reset ='1' then
            red <= (others => '0');
            green <= (others => '0');
            blue <= (others => '0');
            top_disp_active<='0';
            bottom_disp_active<='0';
        else
            if (((v_cntr_r >BOTTOM_PLOT_VERT_BORDER_L) and (v_cntr_r < BOTTOM_PLOT_VERT_BORDER_H))and((h_cntr_r >(PLOT_HOR_BORDER_L-to_unsigned(1,10))) and (h_cntr_r < (PLOT_HOR_BORDER_r+to_unsigned(1,10)))))  then
                --drawing bottom plot
                bottom_disp_active<='1';
                top_disp_active<='0';
                red<="000";
                green<=color_from_uart_bottom;
                blue<="00";
            elsif (((v_cntr_r >(TOP_PLOT_VERT_BORDER_L-to_unsigned(1,10))) and (v_cntr_r < (TOP_PLOT_VERT_BORDER_H+to_unsigned(1,10))))and((h_cntr_r >(PLOT_HOR_BORDER_L-to_unsigned(1,10))) and (h_cntr_r < (PLOT_HOR_BORDER_r+to_unsigned(1,10)))))  then
                --drawing top plot
                top_disp_active<='1';
                bottom_disp_active<='0';
                red<="000";
                green<=color_from_uart_top;
                blue<="00";
            elsif ((h_cntr_r >(PLOT_HOR_BORDER_L-to_unsigned(1,10))) and (h_cntr_r < (PLOT_HOR_BORDER_r+to_unsigned(1,10)))) and (v_cntr_r = BOTTOM_PLOT_VERT_BORDER_L or v_cntr_r = (BOTTOM_PLOT_VERT_BORDER_H+to_unsigned(2,10)) ) then
                --drawing horizontal lines for bottom display frame
                top_disp_active<='0';
                bottom_disp_active<='0';                
                red<="111";
                green<="111";
                blue<="11";
            elsif ((h_cntr_r =(PLOT_HOR_BORDER_L-to_unsigned(1,10))) or (h_cntr_r = (PLOT_HOR_BORDER_r+to_unsigned(1,10)))) and ((v_cntr_r >BOTTOM_PLOT_VERT_BORDER_L) and (v_cntr_r < (BOTTOM_PLOT_VERT_BORDER_H+to_unsigned(2,10)))) then
                --drawing vertical lines for bottom display frame
                top_disp_active<='0';
                bottom_disp_active<='0';
                red<="111";
                green<="111";
                blue<="11";
            elsif ((h_cntr_r >(PLOT_HOR_BORDER_L-1)) and (h_cntr_r < (PLOT_HOR_BORDER_r+to_unsigned(1,10)))) and (v_cntr_r = (TOP_PLOT_VERT_BORDER_L-to_unsigned(1,10)) or v_cntr_r = (TOP_PLOT_VERT_BORDER_H+to_unsigned(2,10)) ) then 
                --drawing horizontal lines for top display frame
                top_disp_active<='0';
                bottom_disp_active<='0';
                red<="111";
                green<="111";
                blue<="11";
            elsif ((h_cntr_r =(PLOT_HOR_BORDER_L-to_unsigned(1,10))) or (h_cntr_r = (PLOT_HOR_BORDER_r+to_unsigned(1,10)))) and ((v_cntr_r >(TOP_PLOT_VERT_BORDER_L-to_unsigned(1,10))) and (v_cntr_r < (TOP_PLOT_VERT_BORDER_H+to_unsigned(2,10)))) then
                --drawing vertical lines for top display frame
                top_disp_active<='0';
                bottom_disp_active<='0';
                red<="111";
                green<="111";
                blue<="11";
            elsif ((v_cntr_r > (TOP_PLOT_VERT_BORDER_L - to_unsigned(8,10)) and v_cntr_r < (TOP_PLOT_VERT_BORDER_L - to_unsigned(2,10))) and (h_cntr_r >(PLOT_HOR_BORDER_L-to_unsigned(1,10)) and h_cntr_r < (PLOT_HOR_BORDER_L+to_unsigned(43,10)))) then
                --drawing top plot title
                top_disp_active<='0';
                bottom_disp_active<='0';
                green<="000";
                red <= (others => title_top(42 - to_integer(h_cntr_r - PLOT_HOR_BORDER_L))
                       (4 - to_integer(v_cntr_r - (TOP_PLOT_VERT_BORDER_L - to_unsigned(7,10)))));
                blue<="00";
            elsif ((v_cntr_r > (BOTTOM_PLOT_VERT_BORDER_L - to_unsigned(8,10)) and v_cntr_r < (BOTTOM_PLOT_VERT_BORDER_L - to_unsigned(2,10))) and (h_cntr_r >(PLOT_HOR_BORDER_L-to_unsigned(1,10)) and h_cntr_r < (PLOT_HOR_BORDER_L+to_unsigned(47,10)))) then
                --drawing bottom plot title
                top_disp_active<='0';
                bottom_disp_active<='0';
                green<="000";
                red <= (others => title_bottom(46 - to_integer(h_cntr_r - PLOT_HOR_BORDER_L))
                       (4 - to_integer(v_cntr_r - (BOTTOM_PLOT_VERT_BORDER_L - to_unsigned(7,10)))));
                blue<="00";  
            else
                --drawing black background
                top_disp_active<='0';
                bottom_disp_active<='0';
                red <= (others => '0');
                green <= (others => '0');
                blue <= (others => '0');
            end if ;
        end if;
    end process;
end Behavioral;

