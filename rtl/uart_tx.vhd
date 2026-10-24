library ieee;
use ieee.std_logic_1164.all;

entity uart_tx is
    generic (
        G_CLKS_PER_BIT : positive := 868
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        data_i  : in  std_logic_vector(7 downto 0);
        valid_i : in  std_logic;
        ready_o : out std_logic;
        tx_o    : out std_logic
    );
end entity;

architecture rtl of uart_tx is

    signal busy    : std_logic := '0';
    signal clk_cnt : natural range 0 to G_CLKS_PER_BIT - 1 := 0;
    signal bit_cnt : natural range 0 to 9 := 0;
    signal shreg   : std_logic_vector(9 downto 0) := (others => '1');  -- stop & data & start

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                busy    <= '0';
                clk_cnt <= 0;
                bit_cnt <= 0;
                shreg   <= (others => '1');
            elsif busy = '0' then
                if valid_i = '1' then
                    shreg   <= '1' & data_i & '0';
                    busy    <= '1';
                    clk_cnt <= 0;
                    bit_cnt <= 0;
                end if;
            elsif clk_cnt = G_CLKS_PER_BIT - 1 then
                clk_cnt <= 0;
                shreg   <= '1' & shreg(9 downto 1);  -- LSB first
                if bit_cnt = 9 then
                    busy <= '0';
                else
                    bit_cnt <= bit_cnt + 1;
                end if;
            else
                clk_cnt <= clk_cnt + 1;
            end if;
        end if;
    end process;

    ready_o <= not busy;
    tx_o    <= shreg(0);

end architecture;
