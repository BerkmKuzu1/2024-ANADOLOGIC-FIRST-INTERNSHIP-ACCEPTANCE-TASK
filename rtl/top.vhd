library ieee;
use ieee.std_logic_1164.all;

entity top is
    generic (
        G_CLK_FREQ  : positive := 100_000_000;
        G_BAUD_RATE : positive := 115_200
    );
    port (
        clk  : in  std_logic;
        rst  : in  std_logic;
        rx_i : in  std_logic;
        tx_o : out std_logic
    );
end entity;

architecture rtl of top is

    constant C_CLKS_PER_BIT : positive := G_CLK_FREQ / G_BAUD_RATE;

    signal rx_data      : std_logic_vector(7 downto 0);
    signal rx_valid     : std_logic;
    signal num1         : std_logic_vector(15 downto 0);
    signal num2         : std_logic_vector(15 downto 0);
    signal opcode       : std_logic_vector(7 downto 0);
    signal msg_valid    : std_logic;
    signal result       : std_logic_vector(15 downto 0);
    signal result_valid : std_logic;
    signal tx_data      : std_logic_vector(7 downto 0);
    signal tx_valid     : std_logic;
    signal tx_ready     : std_logic;

begin

    -- rx_i -> uart_rx -> msg_rx -> alu -> msg_tx -> uart_tx -> tx_o

    u_uart_rx : entity work.uart_rx
        generic map (
            G_CLKS_PER_BIT => C_CLKS_PER_BIT
        )
        port map (
            clk     => clk,
            rst     => rst,
            rx_i    => rx_i,
            data_o  => rx_data,
            valid_o => rx_valid
        );

    u_msg_rx : entity work.msg_rx
        port map (
            clk      => clk,
            rst      => rst,
            data_i   => rx_data,
            valid_i  => rx_valid,
            num1_o   => num1,
            num2_o   => num2,
            opcode_o => opcode,
            valid_o  => msg_valid
        );

    u_alu : entity work.alu
        port map (
            clk      => clk,
            rst      => rst,
            num1_i   => num1,
            num2_i   => num2,
            opcode_i => opcode,
            valid_i  => msg_valid,
            result_o => result,
            valid_o  => result_valid
        );

    u_msg_tx : entity work.msg_tx
        port map (
            clk        => clk,
            rst        => rst,
            result_i   => result,
            valid_i    => result_valid,
            tx_data_o  => tx_data,
            tx_valid_o => tx_valid,
            tx_ready_i => tx_ready
        );

    u_uart_tx : entity work.uart_tx
        generic map (
            G_CLKS_PER_BIT => C_CLKS_PER_BIT
        )
        port map (
            clk     => clk,
            rst     => rst,
            data_i  => tx_data,
            valid_i => tx_valid,
            ready_o => tx_ready,
            tx_o    => tx_o
        );

end architecture;
