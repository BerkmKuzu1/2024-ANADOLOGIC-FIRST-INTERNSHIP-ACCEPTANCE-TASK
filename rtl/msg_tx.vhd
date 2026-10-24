library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.msg_pkg.all;

entity msg_tx is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        result_i   : in  std_logic_vector(15 downto 0);
        valid_i    : in  std_logic;
        tx_data_o  : out std_logic_vector(7 downto 0);
        tx_valid_o : out std_logic;
        tx_ready_i : in  std_logic
    );
end entity;

architecture rtl of msg_tx is

    type byte_array_t is array (0 to 4) of std_logic_vector(7 downto 0);

    signal buf  : byte_array_t := (others => (others => '0'));
    signal idx  : natural range 0 to 4 := 0;
    signal busy : std_logic := '0';

begin

    process (clk)
        variable sum : unsigned(7 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                busy <= '0';
                idx  <= 0;
            elsif busy = '0' then
                if valid_i = '1' then
                    sum := unsigned(C_TX_HEADER(15 downto 8)) + unsigned(C_TX_HEADER(7 downto 0))
                         + unsigned(result_i(15 downto 8)) + unsigned(result_i(7 downto 0));
                    -- checksum makes the sum of all 5 bytes 0 (mod 256)
                    buf  <= (C_TX_HEADER(15 downto 8), C_TX_HEADER(7 downto 0),
                             result_i(15 downto 8), result_i(7 downto 0),
                             std_logic_vector(0 - sum));
                    idx  <= 0;
                    busy <= '1';
                end if;
            elsif tx_ready_i = '1' then  -- byte accepted by uart_tx
                if idx = 4 then
                    busy <= '0';
                else
                    idx <= idx + 1;
                end if;
            end if;
        end if;
    end process;

    tx_data_o  <= buf(idx);
    tx_valid_o <= busy;

end architecture;
