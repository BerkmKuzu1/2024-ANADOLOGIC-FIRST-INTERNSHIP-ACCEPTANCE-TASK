library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.msg_pkg.all;

entity alu is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        num1_i   : in  std_logic_vector(15 downto 0);
        num2_i   : in  std_logic_vector(15 downto 0);
        opcode_i : in  std_logic_vector(7 downto 0);
        valid_i  : in  std_logic;
        result_o : out std_logic_vector(15 downto 0);
        valid_o  : out std_logic
    );
end entity;

architecture rtl of alu is
begin

    process (clk)
    begin
        if rising_edge(clk) then
            valid_o <= '0';

            if rst = '1' then
                result_o <= (others => '0');
            elsif valid_i = '1' then
                -- 16-bit two's complement, wraps on overflow
                if opcode_i = C_OP_ADD then
                    result_o <= std_logic_vector(signed(num1_i) + signed(num2_i));
                    valid_o  <= '1';
                elsif opcode_i = C_OP_SUB then
                    result_o <= std_logic_vector(signed(num1_i) - signed(num2_i));
                    valid_o  <= '1';
                end if;  -- unknown opcode: no response
            end if;
        end if;
    end process;

end architecture;
