library IEEE;
use IEEE.std_logic_1164.all;
use std.env.finish;

entity tb_i2c_master is
end;

architecture tb_i2c_master_arch of tb_i2c_master is

    -- Design under test (DUT)
    component i2c_master is
        port(
            clock: in std_logic;
            reset: in std_logic
        );
    end component;

    signal clock: std_logic;
    signal reset: std_logic;

begin

    DUT: i2c_master
        port map(
            clock => clock,
            reset => reset
        );

    process
        variable i: natural := 0;
    begin
        clock <= '0';
        reset <= '0';
        wait for 50 ps;
        while (i < 255) loop
            reset <= '1';
            clock <= not clock;
            wait for 10 ps;
            i := i + 2;
        end loop;
        finish;
    end process;

end;