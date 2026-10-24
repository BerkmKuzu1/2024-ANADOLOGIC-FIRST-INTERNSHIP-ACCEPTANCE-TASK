library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.msg_pkg.all;

entity msg_rx is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        data_i   : in  std_logic_vector(7 downto 0);
        valid_i  : in  std_logic;
        num1_o   : out std_logic_vector(15 downto 0);
        num2_o   : out std_logic_vector(15 downto 0);
        opcode_o : out std_logic_vector(7 downto 0);
        valid_o  : out std_logic
    );
end entity;

architecture rtl of msg_rx is

    type state_t is (S_HEADER_H, S_HEADER_L, S_NUM1_H, S_NUM1_L,
                     S_NUM2_H, S_NUM2_L, S_OPCODE, S_CHECKSUM);

    signal state : state_t := S_HEADER_H;
    signal sum   : unsigned(7 downto 0) := (others => '0');

begin

    process (clk)
    begin
        if rising_edge(clk) then
            valid_o <= '0';

            if rst = '1' then
                state    <= S_HEADER_H;
                sum      <= (others => '0');
                num1_o   <= (others => '0');
                num2_o   <= (others => '0');
                opcode_o <= (others => '0');
            elsif valid_i = '1' then
                sum <= sum + unsigned(data_i);  -- running byte sum

                case state is
                    when S_HEADER_H =>
                        sum <= unsigned(data_i);
                        if data_i = C_RX_HEADER(15 downto 8) then
                            state <= S_HEADER_L;
                        end if;

                    when S_HEADER_L =>
                        if data_i = C_RX_HEADER(7 downto 0) then
                            state <= S_NUM1_H;
                        elsif data_i = C_RX_HEADER(15 downto 8) then
                            sum <= unsigned(data_i);  -- BA BA CD: restart header
                        else
                            state <= S_HEADER_H;
                        end if;

                    when S_NUM1_H =>
                        num1_o(15 downto 8) <= data_i;
                        state <= S_NUM1_L;

                    when S_NUM1_L =>
                        num1_o(7 downto 0) <= data_i;
                        state <= S_NUM2_H;

                    when S_NUM2_H =>
                        num2_o(15 downto 8) <= data_i;
                        state <= S_NUM2_L;

                    when S_NUM2_L =>
                        num2_o(7 downto 0) <= data_i;
                        state <= S_OPCODE;

                    when S_OPCODE =>
                        opcode_o <= data_i;
                        state    <= S_CHECKSUM;

                    when S_CHECKSUM =>
                        -- sum of all 8 bytes must be 0 (mod 256)
                        if sum + unsigned(data_i) = 0 then
                            valid_o <= '1';
                        end if;
                        state <= S_HEADER_H;
                end case;
            end if;
        end if;
    end process;

end architecture;
