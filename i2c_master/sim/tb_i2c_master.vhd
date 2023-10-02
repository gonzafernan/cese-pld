library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.env.finish;

entity tb_i2c_master is
end;

architecture tb_i2c_master_arch of tb_i2c_master is

    -- Design under test (DUT)
    component i2c_master is
        port(
            clock: in std_logic;
            reset: in std_logic;
            read_write: in std_logic;
            mosi_data: in std_logic_vector(7 downto 0);
            register_address: in std_logic_vector(7 downto 0);
            slave_address: in std_logic_vector(6 downto 0)
        );
    end component;

    signal clock: std_logic;
    signal reset: std_logic;
    signal read_write: std_logic;
    signal mosi_data: std_logic_vector(7 downto 0);

    constant slave_address: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(16#42#, 7));
    constant register_address: std_logic_vector(7 downto 0) := "01010101";

begin

    DUT: i2c_master
        port map(
            clock => clock,
            reset => reset,
            read_write => read_write,
            mosi_data => mosi_data,
            register_address => register_address,
            slave_address => slave_address
        );

    process
        variable i: natural := 0;
    begin
        clock <= '0';
        reset <= '0';
        read_write <= '0';
        mosi_data <= "00000011";
        wait for 50 ps;
        reset <= '1';
        while (i < 255) loop
            clock <= not clock;
            wait for 10 ps;
            i := i + 2;
        end loop;
        read_write <= '1';
        mosi_data <= "00110000";
        i := 0;
        while (i < 255) loop
            clock <= not clock;
            wait for 10 ps;
            i := i + 2;
        end loop;
        finish;
    end process;

end;