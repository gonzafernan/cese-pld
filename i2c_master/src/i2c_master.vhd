-- Author: Ing. Gonzalo Fernandez

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity i2c_master is
    generic(
        DATA_WIDTH: integer := 8;
        REGISTER_WIDTH: integer := 8;
        ADDRESS_WIDTH: integer := 7
    );
    port(
        -- Clock input
        clock: in std_logic;
        -- Active high reset
        reset: in std_logic;
        -- I2C master module enable
        -- enable: in std_logic;
        -- (0) write, (1) read
        read_write: in std_logic;
        -- Data to be written to a register during an I2C write operation
        mosi_data: in std_logic_vector(DATA_WIDTH-1 downto 0);
        -- Register where data is read/written
        register_address: in std_logic_vector(REGISTER_WIDTH-1 downto 0);
        -- Slave I2C address
        slave_address: in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        -- Data to be read during a I2C read operation
        -- miso_data: out std_logic_vector(DATA_WIDTH-1 downto 0);
        -- External serial data (SDA)
        serial_data: inout std_logic;
        -- External serial clock (SCL)
        serial_clock: inout std_logic
    );
end i2c_master;

architecture i2c_master_arq of i2c_master is

    constant IDLE: std_logic_vector(1 downto 0) := "00";
    signal state: std_logic_vector(1 downto 0); -- FSM state
    signal saved_slave_address: std_logic_vector(ADDRESS_WIDTH downto 0);
    signal saved_register_address: std_logic_vector(REGISTER_WIDTH-1 downto 0);
    signal saved_mosi_data: std_logic_vector(DATA_WIDTH-1 downto 0);
    signal saved_read_write: std_logic;

begin

    process(clock)
    begin
        if rising_edge(clock) then
            if reset = '0' then
                -- Reset action
                state <= IDLE;
            else
                case state is
                    when IDLE =>
                        saved_slave_address <= slave_address & "0"; -- Save slave address
                        saved_register_address <= register_address; -- Save target register address
                        saved_mosi_data <= mosi_data; -- Save data to be written (valid in write op)
                        saved_read_write <= read_write; -- Save read/write status bit

                        serial_data <= '1'; -- Hold SDA high
                        serial_clock <= '1'; -- Hold SCL high
                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end;