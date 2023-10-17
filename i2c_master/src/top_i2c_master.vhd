-- Module: I2C Master with VIO and ILA
-- Author: Gonzalo G. Fernandez

library IEEE;
use IEEE.std_logic_1164.all;

entity top_i2c_master is
    port(
        clock: in std_logic
    );
end;

architecture top_i2c_master_arch of top_i2c_master is
    signal reset: std_logic_vector(0 downto 0);
    signal enable: std_logic_vector(0 downto 0);
    signal read_write: std_logic_vector(0 downto 0);
    
    signal i2c_enable: std_logic;
    
    signal sda: std_logic_vector(0 downto 0);
    signal scl: std_logic_vector(0 downto 0);
    signal sda_reg: std_logic;
    signal scl_reg: std_logic;
    
    signal mosi_data: std_logic_vector(7 downto 0);
    signal register_address: std_logic_vector(7 downto 0);
    signal slave_address: std_logic_vector(6 downto 0);
    
    -- Debug signals
    signal i2c_state: std_logic_vector(2 downto 0);
    
    component prescaler
        port(
            clock: in std_logic;    -- Clock input
            reset: in std_logic;    -- Active high reset, synchronous to clock
            enable: out std_logic  -- Prescaler output
        );
    end component;
    
    component i2c_master
        port(
            clock: in std_logic;
            reset: in std_logic;
            enable: in std_logic;
            read_write: in std_logic;
            mosi_data: in std_logic_vector(7 downto 0);
            register_address: in std_logic_vector(7 downto 0);
            slave_address: in std_logic_vector(6 downto 0);
            o_state: out std_logic_vector(2 downto 0);
            serial_clock: out std_logic;
            serial_data: out std_logic
        );
    end component;

    component vio
        port(
            clk_0: in std_logic;
            probe_out0_0: out std_logic_vector(0 downto 0);
            probe_out1_0: out std_logic_vector(0 downto 0); 
            probe_out2_0: out std_logic_vector(0 downto 0); 
            probe_out3_0: out std_logic_vector(7 downto 0); 
            probe_out4_0: out std_logic_vector(7 downto 0); 
            probe_out5_0: out std_logic_vector(6 downto 0)
        );
    end component;

    component ila
        port(
            clk_0: in std_logic;
            probe0_0: in std_logic;
            probe1_0: in std_logic;
            probe2_0: in std_logic_vector(2 downto 0)
        );
    end component;
    
begin

    sda_reg <= '0' when sda(0) = '0' else '1';
    scl_reg <= '0' when scl(0) = '0' else '1';
    
    u_prescaler: prescaler
        port map(
            clock => clock,
            reset => reset(0),
            enable => i2c_enable
        );

    u_i2c_master: i2c_master
        port map(
            clock => i2c_enable,
            reset => reset(0),
            enable => enable(0),
            read_write => read_write(0),
            mosi_data => mosi_data,
            register_address => register_address,
            slave_address => slave_address,
            o_state => i2c_state,
            serial_clock => scl(0),
            serial_data => sda(0)
        );

    u_vio: vio
        port map(
            clk_0 => clock,
            probe_out0_0 => reset,
            probe_out1_0 => enable,
            probe_out2_0 => read_write,
            probe_out3_0 => mosi_data,
            probe_out4_0 => register_address,
            probe_out5_0 => slave_address
        );
        
    u_ila: ila
        port map(
            clk_0 => clock,
            probe0_0 => scl_reg,
            probe1_0 => sda_reg,
            probe2_0 => i2c_state
        );

end;