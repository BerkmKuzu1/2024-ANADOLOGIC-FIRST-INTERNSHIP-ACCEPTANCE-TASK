library ieee;
use ieee.std_logic_1164.all;

package msg_pkg is

    constant C_RX_HEADER : std_logic_vector(15 downto 0) := x"BACD";
    constant C_TX_HEADER : std_logic_vector(15 downto 0) := x"ABCD";

    constant C_OP_ADD : std_logic_vector(7 downto 0) := x"00";
    constant C_OP_SUB : std_logic_vector(7 downto 0) := x"01";

end package;
