-- Author: Ing. Gonzalo Fernandez

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity i2c_master is
    -- generic(
        -- DATA_WIDTH: integer := 8;
        -- REGISTER_WIDTH: integer := 8;
        -- ADDRESS_WIDTH: integer := 7
    -- );
    port(
        -- Clock input
        clock: in std_logic;
        -- Active high reset
        reset: in std_logic
        -- I2C master module enable
        -- enable: in std_logic;
        -- (0) write, (1) read
        -- read_write: in std_logic;
        -- Data to be written to a register during an I2C write operation
        -- mosi_data: in std_logic_vector(DATA_WIDTH-1 downto 0);
        -- Register where data is read/written
        -- register_address: in std_logic_vector(REGISTER_WIDTH-1 downto 0);
        -- Slave I2C address
        -- slave_address: in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        -- Data to be read during a I2C read operation
        -- miso_data: out std_logic_vector(DATA_WIDTH-1 downto 0);
    );
end;

architecture i2c_master_arq of i2c_master is

    constant S_IDLE: integer := 16#00#;
    signal state: std_logic_vector(3 downto 0); -- FSM state

begin

    process(clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then
                -- Reset action
                state <= std_logic_vector(to_unsigned(S_IDLE, 4));
            else
                case state is

                end case;
            end if;
        end if;
    end process;

end;