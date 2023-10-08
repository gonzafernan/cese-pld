-- Module: I2C Master
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
        enable: in std_logic;
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
        -- External serial clock (SCL)
        serial_clock: inout std_logic;
        -- External serial data (SDA)
        serial_data: inout std_logic
    );
end i2c_master;

architecture i2c_master_arq of i2c_master is

    constant IDLE: std_logic_vector(2 downto 0) := "000";
    constant START: std_logic_vector(2 downto 0) := "001";
    constant WRITE_ADDR_W: std_logic_vector(2 downto 0) := "010";
    constant CHECK_ACK: std_logic_vector(2 downto 0) := "011";
    constant WRITE_REG_ADDR: std_logic_vector(2 downto 0) := "100";
    constant WRITE_REG_DATA: std_logic_vector(2 downto 0) := "101";
    constant SEND_STOP: std_logic_vector(2 downto 0) := "111";
    signal state: std_logic_vector(2 downto 0); -- FSM state
    signal next_state: std_logic_vector(2 downto 0); -- To manage FSM state sequence

    signal serial_data_reg: std_logic;
    signal next_serial_data: std_logic;
    signal serial_clock_reg: std_logic;

    signal saved_slave_address: std_logic_vector(ADDRESS_WIDTH downto 0);
    signal saved_register_address: std_logic_vector(REGISTER_WIDTH-1 downto 0);
    signal saved_mosi_data: std_logic_vector(DATA_WIDTH-1 downto 0);
    signal saved_read_write: std_logic;
    signal acknowledge: std_logic; -- 1 if acknowledge from slave device

    signal process_counter: std_logic_vector(1 downto 0);
    signal bit_counter: std_logic_vector(7 downto 0);

begin

    -- Open-drain SDA
    serial_data <= 'Z' when serial_data_reg = '1' else '0'; -- 0/1 to 0/Z
    serial_clock <= 'Z' when serial_clock_reg = '1' else '0'; -- 0/1 to 0/Z

    process(clock)
    begin
        if rising_edge(clock) then
            if reset = '0' then
                -- Reset action
                state <= IDLE;
            else
                case state is
                    when IDLE =>
                        -- The device address is sent with a 0 appended to the LSB to signify
                        -- a write operation
                        -- Save slave address
                        saved_slave_address <= slave_address & "0";
                        -- Save target register address
                        saved_register_address <= register_address;
                        -- Save data to be written (valid in write op)
                        saved_mosi_data <= mosi_data; 
                        -- Save read/write status bit
                        saved_read_write <= read_write; 

                        serial_data_reg <= '1'; -- Hold SDA high
                        serial_clock_reg <= '1'; -- Hold SCL high
                        next_serial_data <= '0';

                        process_counter <= "00"; -- Init internal process
                        bit_counter <= std_logic_vector(to_unsigned(0, 8));
                        acknowledge <= '0';

                        if enable = '1' then
                            state <= START; -- Proceed to START
                            next_state <= WRITE_ADDR_W; -- Write address after START squence
                        else
                            state <= IDLE; -- Stay IDLE
                            next_state <= IDLE;
                        end if;
                    
                    when START =>
                        -- Generate START sequence
                        case process_counter is
                            when "00" =>
                                process_counter <= "01";
                            when "01" =>
                                process_counter <= "10";
                                serial_data_reg <= '0'; -- SDA low
                            when "10" =>
                                process_counter <= "11";
                                bit_counter <= std_logic_vector(to_unsigned(8, 8));
                            when "11" =>
                                process_counter <= "00";
                                state <= next_state; -- Proceed to the next state
                                serial_clock_reg <= '0'; -- SCL low
                                -- Most significant bit is transmitted first
                                serial_data_reg <= saved_slave_address(ADDRESS_WIDTH);
                            when others =>
                                state <= IDLE;
                        end case;
                    
                    when WRITE_ADDR_W =>
                        case process_counter is
                            when "00" =>
                                process_counter <= "01";
                                serial_clock_reg <= '1'; -- SCL high
                            when "01" =>
                                -- chck for clock stretching
                                if serial_clock /= '0' then
                                    process_counter <= "10";
                                end if;
                            when "10" =>
                                serial_clock_reg <= '0';
                                process_counter <= "11";
                                bit_counter <= std_logic_vector(to_unsigned(to_integer(unsigned(bit_counter)) - 1, 8));
                            when "11" =>
                                if bit_counter = "00000000" then
                                    next_serial_data <= saved_register_address(REGISTER_WIDTH-1);
                                    next_state <= WRITE_REG_ADDR;
                                    state <= CHECK_ACK;
                                    bit_counter <= std_logic_vector(to_unsigned(8, 8));
                                else
                                    serial_data_reg <= saved_slave_address(to_integer(unsigned(bit_counter)) - 1);
                                end if;
                                process_counter <= "00";

                            when others =>
                                state <= IDLE;
                        end case;

                    when CHECK_ACK =>
                        case process_counter is
                            when "00" =>
                                serial_clock_reg <= '1';
                                process_counter <= "01";
                            when "01" =>
                                -- check for clock stretching
                                if serial_clock /= '0' then
                                    acknowledge <= '0';
                                    process_counter <= "10";
                                end if;
                            when "10" =>
                                serial_clock_reg <= '0';
                                process_counter <= "11";
                                if serial_data_reg = '0' then
                                    acknowledge <= '1';
                                end if;
                            when "11" =>
                                if acknowledge = '1' then
                                    acknowledge <= '0';
                                    serial_data_reg <= next_serial_data;
                                    state <= next_state;
                                else
                                    state <= IDLE;
                                end if;
                                process_counter <= "00";

                            when others =>
                                state <= IDLE;
                        end case;
                    
                    when WRITE_REG_ADDR =>
                        case process_counter is
                            when "00" =>
                                serial_clock_reg <= '1';
                                process_counter <= "01";
                            when "01" =>
                                -- check for clock stretching
                                if serial_clock /= '0' then
                                    acknowledge <= '0';
                                    process_counter <= "10";
                                end if;
                            when "10" =>
                                serial_clock_reg <= '0';
                                bit_counter <= std_logic_vector(to_unsigned(to_integer(unsigned(bit_counter)) - 1, 8));
                                process_counter <= "11";
                            when "11" =>
                                if bit_counter = "00000000" then
                                    if read_write = '0' then -- write op
                                        next_serial_data <= saved_mosi_data(DATA_WIDTH-1);
                                        next_state <= WRITE_REG_DATA;
                                    else -- read op
                                        next_state <= IDLE;
                                        next_serial_data <= '1';
                                    end if;
                                    bit_counter <= std_logic_vector(to_unsigned(8, 8));
                                    serial_data_reg <= '0';
                                    state <= CHECK_ACK;
                                else
                                    serial_data_reg <= saved_register_address(to_integer(unsigned(bit_counter)) - 1);
                                end if;
                                process_counter <= "00";
                            when others =>
                                state <= IDLE;
                        end case;

                    when WRITE_REG_DATA =>
                        case process_counter is
                            when "00" =>
                                serial_clock_reg <= '1';
                                process_counter <= "01";
                            when "01" =>
                                -- check for clock stretching
                                if serial_clock /= '0' then
                                    acknowledge <= '0';
                                    process_counter <= "10";
                                end if;
                            when "10" =>
                                serial_clock_reg <= '0';
                                bit_counter <= std_logic_vector(to_unsigned(to_integer(unsigned(bit_counter)) - 1, 8));
                                process_counter <= "11";
                            when "11" =>
                                if bit_counter = "00000000" then
                                    state <= CHECK_ACK;
                                    next_state <= SEND_STOP;
                                    next_serial_data <= '0';
                                    bit_counter <= std_logic_vector(to_unsigned(8, 8));
                                    serial_data_reg <= '0';
                                else
                                    serial_data_reg <= saved_mosi_data(to_integer(unsigned(bit_counter)) - 1);
                                end if;
                                process_counter <= "00";
                            when others =>
                                state <= IDLE;
                        end case;

                    when SEND_STOP =>
                        case process_counter is
                            when "00" =>
                                serial_clock_reg <= '1';
                                process_counter <= "01";
                            when "01" =>
                                -- check for clock stretching
                                if serial_clock /= '0' then
                                    acknowledge <= '0';
                                    process_counter <= "10";
                                end if;
                            when "10" =>
                                serial_data_reg <= '1';
                                process_counter <= "11";
                            when "11" =>
                                state <= IDLE;
                            when others =>
                                state <= IDLE;

                        end case;

                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end;
