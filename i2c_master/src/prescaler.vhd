-- Author: Ing. Gonzalo G. Fernandez
-- Clock prescaler

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity prescaler is
    generic(
        PRESCALE: integer := 5
    );
    port(
        clock: in std_logic;    -- Clock input
        reset: in std_logic;    -- Active high reset, synchronous to clock
        enable: out std_logic  -- Prescaler output
    );
end;

architecture prescaler_arch of prescaler is

    signal prescaler_counter: std_logic_vector(15 downto 0);
    signal enable_reg: std_logic;

begin

    process(clock)
    begin
        if rising_edge(clock) then
            if (reset = '0') then
                prescaler_counter <= (15 downto 0 => '0');
                enable_reg <= '0';
            else
                if prescaler_counter = std_logic_vector(to_unsigned(PRESCALE-1, 16)) then
                    prescaler_counter <= (15 downto 0 => '0');
                    enable_reg <= '1';
                else
                    prescaler_counter <= std_logic_vector(to_unsigned((to_integer(unsigned(prescaler_counter)) + 1), 16));
                    enable_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    enable <= enable_reg;

end;