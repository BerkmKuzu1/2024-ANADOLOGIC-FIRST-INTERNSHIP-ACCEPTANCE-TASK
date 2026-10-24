library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.msg_pkg.all;

entity tb_top is
end entity;

architecture sim of tb_top is

    constant C_CLK_FREQ     : positive := 100_000_000;
    constant C_BAUD_RATE    : positive := 115_200;
    constant C_CLK_PERIOD   : time     := 1 sec / C_CLK_FREQ;
    constant C_BIT_PERIOD   : time     := 1 sec / C_BAUD_RATE;
    constant C_RESP_TIMEOUT : time     := 100 * C_BIT_PERIOD;
    constant C_NO_RESP      : std_logic_vector := "";

    type byte_array_t is array (natural range <>) of std_logic_vector(7 downto 0);

    signal clk  : std_logic := '0';
    signal rst  : std_logic := '1';
    signal rx_i : std_logic := '1';
    signal tx_o : std_logic;

    signal resp_bytes : byte_array_t(0 to 255);
    signal resp_count : natural := 0;

    -- 16-bit two's complement, wraps like the hardware
    function to_slv16(n : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(n mod 65536, 16));
    end function;

    -- appends the checksum byte: sum of all bytes = 0 (mod 256)
    function add_checksum(data : std_logic_vector) return std_logic_vector is
        constant d   : std_logic_vector(data'length - 1 downto 0) := data;
        variable sum : unsigned(7 downto 0) := (others => '0');
    begin
        for i in 0 to d'length / 8 - 1 loop
            sum := sum + unsigned(d(i * 8 + 7 downto i * 8));
        end loop;
        return d & std_logic_vector(0 - sum);
    end function;

    function make_msg(num1, num2 : integer; opcode : std_logic_vector) return std_logic_vector is
    begin
        return add_checksum(C_RX_HEADER & to_slv16(num1) & to_slv16(num2) & opcode);
    end function;

    function make_resp(result : integer) return std_logic_vector is
    begin
        return add_checksum(C_TX_HEADER & to_slv16(result));
    end function;

begin

    clk <= not clk after C_CLK_PERIOD / 2;

    dut : entity work.top
        generic map (
            G_CLK_FREQ  => C_CLK_FREQ,
            G_BAUD_RATE => C_BAUD_RATE
        )
        port map (
            clk  => clk,
            rst  => rst,
            rx_i => rx_i,
            tx_o => tx_o
        );

    -- decodes the DUT's tx_o line into resp_bytes
    uart_monitor : process
        variable b : std_logic_vector(7 downto 0);
    begin
        wait until falling_edge(tx_o);
        wait for C_BIT_PERIOD / 2;
        for i in 0 to 7 loop
            wait for C_BIT_PERIOD;
            b(i) := tx_o;
        end loop;
        wait for C_BIT_PERIOD;
        assert tx_o = '1' report "monitor: bad stop bit" severity error;
        resp_bytes(resp_count) <= b;
        resp_count <= resp_count + 1;
    end process;

    stimulus : process
        variable errors : natural := 0;

        procedure uart_write(data : std_logic_vector) is
            constant d : std_logic_vector(data'length - 1 downto 0) := data;
        begin
            for i in d'length / 8 - 1 downto 0 loop
                rx_i <= '0';
                wait for C_BIT_PERIOD;
                for j in 0 to 7 loop
                    rx_i <= d(i * 8 + j);
                    wait for C_BIT_PERIOD;
                end loop;
                rx_i <= '1';
                wait for C_BIT_PERIOD;
            end loop;
        end procedure;

        -- sends msg, waits, compares the received bytes with resp
        procedure run_test(name : string; msg : std_logic_vector; resp : std_logic_vector) is
            constant n     : natural := resp'length / 8;
            variable first : natural;
            variable got   : std_logic_vector(resp'length - 1 downto 0);
        begin
            first := resp_count;
            uart_write(msg);
            wait for C_RESP_TIMEOUT;

            if resp_count - first /= n then
                errors := errors + 1;
                report "FAIL: " & name & ": expected " & integer'image(n)
                     & " bytes, got " & integer'image(resp_count - first) severity error;
                return;
            end if;

            for i in 0 to n - 1 loop
                got(got'high - i * 8 downto got'high - i * 8 - 7) := resp_bytes(first + i);
            end loop;

            if got /= resp then
                errors := errors + 1;
                report "FAIL: " & name & ": expected 0x" & to_hstring(resp)
                     & ", got 0x" & to_hstring(got) severity error;
            elsif n = 0 then
                report "PASS: " & name & ": 0x" & to_hstring(msg) & " -> no response";
            else
                report "PASS: " & name & ": 0x" & to_hstring(msg) & " -> 0x" & to_hstring(got);
            end if;
        end procedure;

    begin
        wait for 10 * C_CLK_PERIOD;
        wait until rising_edge(clk);
        rst <= '0';
        wait for 10 * C_BIT_PERIOD;

        run_test("ADD 16 + 32 (task example)", x"BACD001000200049", x"ABCD003058");
        run_test("SUB 16 - 32 (task example)", x"BACD001000200148", x"ABCDFFF099");
        run_test("Bad checksum",               x"BACD001000200048", C_NO_RESP);
        run_test("ADD -100 + 25",              make_msg(-100, 25, C_OP_ADD), make_resp(-75));
        run_test("ADD 32767 + 1 (overflow)",   make_msg(32767, 1, C_OP_ADD), make_resp(-32768));
        run_test("Unknown opcode",             make_msg(1, 2, x"02"), C_NO_RESP);
        run_test("Garbage before header",      x"00FFBA" & make_msg(1000, -2000, C_OP_SUB), make_resp(3000));

        if errors = 0 then
            report "TEST PASSED";
        else
            report "TEST FAILED: " & integer'image(errors) & " error(s)" severity failure;
        end if;
        std.env.finish;
    end process;

end architecture;
