library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity axilt_ram is
    generic (
        DATA_WIDTH : integer := 32;
        ADDR_WIDTH : integer := 13
    );
    port (
        aclk            : in    std_logic;
        areset_n        : in    std_logic;
        
        s_axilt_awaddr  : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
        s_axilt_awvalid : in    std_logic;
        s_axilt_awready : out   std_logic;

        s_axilt_wdata   : in    std_logic_vector(DATA_WIDTH-1 downto 0);
        s_axilt_wstrb   : in    std_logic_vector((DATA_WIDTH/8)-1 downto 0);
        s_axilt_wvalid  : in    std_logic;
        s_axilt_wready  : out   std_logic;

        s_axilt_bresp   : out   std_logic_vector(1 downto 0);
        s_axilt_bvalid  : out   std_logic;
        s_axilt_bready  : in    std_logic;

        s_axilt_araddr  : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
        s_axilt_arvalid : in    std_logic;
        s_axilt_arready : out   std_logic;

        s_axilt_rdata   : out   std_logic_vector(DATA_WIDTH-1 downto 0);
        s_axilt_rresp   : out   std_logic_vector(1 downto 0);
        s_axilt_rvalid  : out   std_logic;
        s_axilt_rready  : in    std_logic
    );
end axilt_ram;

architecture behavioural of axilt_ram is

    constant STRB_WIDTH : integer := DATA_WIDTH/8;
    constant ADDR_LSB : integer := integer(ceil(log2(real(STRB_WIDTH))));

    type ram is array (0 to (2**(ADDR_WIDTH-ADDR_LSB))-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mem : ram := (others => (others => '0'));

    attribute ram_style : string;
    attribute ram_style of mem : signal is "block";

    type axilt_state is (IDLE, WDATA, WRESP, RDATA);
    signal state : axilt_state := IDLE;

    constant AXI_OKAY : std_logic_vector(1 downto 0) := "00";
    constant AXI_ERR  : std_logic_vector(1 downto 0) := "10";

    signal axilt_awready    : std_logic := '0';
    signal axilt_wready     : std_logic := '0';
    signal axilt_bresp      : std_logic_vector(1 downto 0) := AXI_OKAY;
    signal axilt_bvalid     : std_logic := '0';
    signal axilt_arready    : std_logic := '0';
    signal axilt_rdata      : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal axilt_rresp      : std_logic_vector(1 downto 0) := AXI_OKAY;
    signal axilt_rvalid     : std_logic := '0';

    signal raddr            : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal waddr            : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');

    function mem_index (
        axilt_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0))        
        return integer is 
            variable axilt_idx : integer := 0;
    begin
        axilt_idx := to_integer(shift_right(unsigned(axilt_addr), ADDR_LSB));
        return axilt_idx;
    end function mem_index;

    signal re    : std_logic := '0';
    signal we    : std_logic := '0';
    
begin

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                raddr <= (others => '0');
            else
                if s_axilt_arvalid = '1' and axilt_arready = '1' then
                    raddr <= s_axilt_araddr;
                end if;
            end if;
        end if;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                waddr <= (others => '0');
            else
                if s_axilt_awvalid = '1' and axilt_awready = '1' then
                    waddr <= s_axilt_awaddr;
                end if;
            end if;
        end if;
    end process;

    AXI_STATE : process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                state <= IDLE;
            else
            case state is
                when IDLE   =>
                    if s_axilt_awvalid = '1' then
                        state <= WDATA;
                    elsif s_axilt_arvalid = '1' then
                        state <= RDATA;
                    else
                        state <= IDLE;
                    end if;
                when WDATA  =>
                    if (s_axilt_wvalid and axilt_wready) = '1' then
                        state <= WRESP;
                    else
                        state <= WDATA;
                    end if;
                when WRESP  =>
                    if (s_axilt_bready and axilt_bvalid) = '1' then
                        state <= IDLE;
                    else
                        state <= WRESP;
                    end if;
                when RDATA  =>
                    if (s_axilt_rready and axilt_rvalid) = '1' then
                        state <= IDLE;
                    else
                        state <= RDATA;
                    end if;
                when others =>
                    null;
            end case;
            end if;
        end if;
    end process AXI_STATE;

    AXI_SIGNAL : process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                axilt_awready   <= '0';
                axilt_wready    <= '0';
                axilt_bresp     <= "00";
                axilt_bvalid    <= '0';
                axilt_arready   <= '1';
                axilt_rresp     <= "00";
                axilt_rvalid    <= '0';
            else
                case state is
                    when IDLE   =>
                        axilt_wready    <= '0';
                        axilt_bresp     <= "00";
                        axilt_bvalid    <= '0';
                        axilt_rresp     <= "00";
                        axilt_rvalid    <= '0';
                        axilt_arready   <= '1';
                        axilt_awready   <= '0';
                        if s_axilt_awvalid = '1' then
                            axilt_arready   <= '0';
                            axilt_awready   <= '1';
                        elsif s_axilt_arvalid = '1' then
                            axilt_rvalid    <= '1';
                            axilt_rresp     <= AXI_OKAY;
                        end if;
                    when WDATA  =>
                        axilt_wready        <= '1';
                        if we = '1' then
                            axilt_bvalid    <= '1';
                        end if;
                    when WRESP  =>
                        axilt_awready   <= '0';
                        axilt_wready    <= '0';
                        axilt_bvalid    <= '0';
                        axilt_bresp     <= AXI_OKAY;
                    when RDATA  =>
                        axilt_rvalid    <= '0';
                        axilt_rresp     <= AXI_OKAY;
                        axilt_arready   <= '0';
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process AXI_SIGNAL;

    s_axilt_awready   <= axilt_awready;
    s_axilt_wready    <= axilt_wready;
    s_axilt_bresp     <= axilt_bresp;
    s_axilt_bvalid    <= axilt_bvalid;
    s_axilt_arready   <= axilt_arready;
    s_axilt_rdata     <= axilt_rdata;
    s_axilt_rresp     <= axilt_rresp;
    s_axilt_rvalid    <= axilt_rvalid;

    re <= axilt_arready and s_axilt_arvalid;
    we <= axilt_wready and s_axilt_wvalid;

    PMEM : process (aclk)
    begin
        if rising_edge(aclk) then
            if (areset_n = '0') then
                axilt_rdata <= (others => '0');
            elsif re = '1' then
                axilt_rdata <= mem (mem_index(s_axilt_araddr));
            elsif we = '1' then
                for i in 0 to STRB_WIDTH-1 loop
                    if s_axilt_wstrb(i) = '1' then
                        mem (mem_index(waddr)) (((i+1)*8)-1 downto (i*8) ) <= 
                            s_axilt_wdata( ((i+1)*8)-1 downto (i*8) );
                    end if;
                end loop;
            end if;
        end if;
    end process PMEM;

end behavioural;