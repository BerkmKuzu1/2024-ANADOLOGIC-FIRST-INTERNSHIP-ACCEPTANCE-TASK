library ieee;
use ieee.std_logic_1164.all;

entity uart_rx is
    generic (
        G_CLKS_PER_BIT : positive := 868
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        rx_i    : in  std_logic;
        data_o  : out std_logic_vector(7 downto 0);
        valid_o : out std_logic
    );
end entity;

architecture rtl of uart_rx is

    type state_t is (S_IDLE, S_START, S_DATA, S_STOP);

    signal state   : state_t := S_IDLE;
    signal rx_meta : std_logic := '1';
    signal rx_sync : std_logic := '1';
    signal clk_cnt : natural range 0 to G_CLKS_PER_BIT - 1 := 0;
    signal bit_cnt : natural range 0 to 7 := 0;
    signal shreg   : std_logic_vector(7 downto 0) := (others => '0');

begin

    process (clk)
    begin
        if rising_edge(clk) then
            -- 2-FF synchronizer
            rx_meta <= rx_i;
            rx_sync <= rx_meta;

            valid_o <= '0';

            if rst = '1' then
                state   <= S_IDLE;
                clk_cnt <= 0;
                bit_cnt <= 0;
            else
                case state is
                    when S_IDLE =>
                        clk_cnt <= 0;
                        bit_cnt <= 0;
                        if rx_sync = '0' then
                            state <= S_START;
                        end if;

                    when S_START =>
                        -- start bit must still be low at mid-bit
                        if clk_cnt = (G_CLKS_PER_BIT - 1) / 2 then
                            clk_cnt <= 0;
                            if rx_sync = '0' then
                                state <= S_DATA;
                            else
                                state <= S_IDLE;
                            end if;
                        else
                            clk_cnt <= clk_cnt + 1;
                        end if;

                    when S_DATA =>
                        if clk_cnt = G_CLKS_PER_BIT - 1 then
                            clk_cnt <= 0;
                            shreg   <= rx_sync & shreg(7 downto 1);  -- LSB first
                            if bit_cnt = 7 then
                                state <= S_STOP;
                            else
                                bit_cnt <= bit_cnt + 1;
                            end if;
                        else
                            clk_cnt <= clk_cnt + 1;
                        end if;

                    when S_STOP =>
                        if clk_cnt = G_CLKS_PER_BIT - 1 then
                            clk_cnt <= 0;
                            state   <= S_IDLE;
                            if rx_sync = '1' then  -- bad stop bit: drop byte
                                valid_o <= '1';
                            end if;
                        else
                            clk_cnt <= clk_cnt + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    data_o <= shreg;

end architecture;
