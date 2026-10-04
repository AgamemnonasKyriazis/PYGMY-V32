module system(
    input  wire i_CLK,
    input  wire i_RST,
    input  wire i_UART_TXD,
    output wire o_UART_RXD,
    output wire o_GPIO_0,
    output wire o_GPIO_1
);

wire CLK = i_CLK;
wire RSTn = ~i_RST;

wire [31:0] pc_0;
wire [31:0] instruction_0;

wire [31:0] pc_1;
wire [31:0] instruction_1;

/* AXI-Lite Interface */

wire [31:0] axilt_m_awaddr_0,  axilt_m_awaddr_1;
wire        axilt_m_awvalid_0, axilt_m_awvalid_1;
wire        axilt_m_awready_0, axilt_m_awready_1;

wire [31:0] axilt_m_wdata_0,  axilt_m_wdata_1;
wire [3:0]  axilt_m_wstrb_0,  axilt_m_wstrb_1;
wire        axilt_m_wvalid_0, axilt_m_wvalid_1;
wire        axilt_m_wready_0, axilt_m_wready_1;

wire [1:0]  axilt_m_bresp_0,  axilt_m_bresp_1;
wire        axilt_m_bvalid_0, axilt_m_bvalid_1;
wire        axilt_m_bready_0, axilt_m_bready_1;

wire [31:0] axilt_m_araddr_0,  axilt_m_araddr_1;
wire        axilt_m_arvalid_0, axilt_m_arvalid_1;
wire        axilt_m_arready_0, axilt_m_arready_1;

wire [31:0] axilt_m_rdata_0,  axilt_m_rdata_1;
wire [1:0]  axilt_m_rresp_0,  axilt_m_rresp_1;
wire        axilt_m_rvalid_0, axilt_m_rvalid_1;
wire        axilt_m_rready_0, axilt_m_rready_1;

wire [31:0] axilt_s_awaddr_0,  axilt_s_awaddr_1,  axilt_s_awaddr_2;
wire        axilt_s_awvalid_0, axilt_s_awvalid_1, axilt_s_awvalid_2;
wire        axilt_s_awready_0, axilt_s_awready_1, axilt_s_awready_2;

wire [31:0] axilt_s_wdata_0,  axilt_s_wdata_1,  axilt_s_wdata_2;
wire [3:0]  axilt_s_wstrb_0,  axilt_s_wstrb_1,  axilt_s_wstrb_2;
wire        axilt_s_wvalid_0, axilt_s_wvalid_1, axilt_s_wvalid_2;
wire        axilt_s_wready_0, axilt_s_wready_1, axilt_s_wready_2;

wire [1:0]  axilt_s_bresp_0,  axilt_s_bresp_1,  axilt_s_bresp_2;
wire        axilt_s_bvalid_0, axilt_s_bvalid_1, axilt_s_bvalid_2;
wire        axilt_s_bready_0, axilt_s_bready_1, axilt_s_bready_2;

wire [31:0] axilt_s_araddr_0,  axilt_s_araddr_1,  axilt_s_araddr_2;
wire        axilt_s_arvalid_0, axilt_s_arvalid_1, axilt_s_arvalid_2;
wire        axilt_s_arready_0, axilt_s_arready_1, axilt_s_arready_2;

wire [31:0] axilt_s_rdata_0,  axilt_s_rdata_1,  axilt_s_rdata_2;
wire [1:0]  axilt_s_rresp_0,  axilt_s_rresp_1,  axilt_s_rresp_2;
wire        axilt_s_rvalid_0, axilt_s_rvalid_1, axilt_s_rvalid_2;
wire        axilt_s_rready_0, axilt_s_rready_1, axilt_s_rready_2;

core #(.HART_ID(32'd0)) core0 (
    .i_CLK(CLK),
    .i_RSTn(RSTn),

    .i_INSTRUCTION(instruction_0),
    .o_PC(pc_0),

    .i_MEI_0(uart_irq[0]),
    .i_MEI_1(1'b0),
    .i_MEI_2(1'b0),
    .i_MEI_3(1'b0),
    .i_MEI_4(1'b0),
    .i_MEI_5(1'b0),

    .o_AWADDR(axilt_m_awaddr_0),
    .o_AWVALID(axilt_m_awvalid_0),
    .i_AWREADY(axilt_m_awready_0),

    .o_WDATA(axilt_m_wdata_0),
    .o_WSTRB(axilt_m_wstrb_0),
    .o_WVALID(axilt_m_wvalid_0),
    .i_WREADY(axilt_m_wready_0),

    .i_BRESP(axilt_m_bresp_0),
    .o_BREADY(axilt_m_bready_0),
    .i_BVALID(axilt_m_bvalid_0),

    .o_ARADDR(axilt_m_araddr_0),
    .o_ARVALID(axilt_m_arvalid_0),
    .i_ARREADY(axilt_m_arready_0),

    .i_RDATA(axilt_m_rdata_0),
    .i_RRESP(axilt_m_rresp_0),
    .i_RVALID(axilt_m_rvalid_0),
    .o_RREADY(axilt_m_rready_0)
);

core #(.HART_ID(32'd1)) core1 (
    .i_CLK(CLK),
    .i_RSTn(RSTn),

    .i_INSTRUCTION(instruction_1),
    .o_PC(pc_1),

    .i_MEI_0(1'b0),
    .i_MEI_1(1'b0),
    .i_MEI_2(1'b0),
    .i_MEI_3(1'b0),
    .i_MEI_4(1'b0),
    .i_MEI_5(1'b0),

    .o_AWADDR(axilt_m_awaddr_1),
    .o_AWVALID(axilt_m_awvalid_1),
    .i_AWREADY(axilt_m_awready_1),

    .o_WDATA(axilt_m_wdata_1),
    .o_WSTRB(axilt_m_wstrb_1),
    .o_WVALID(axilt_m_wvalid_1),
    .i_WREADY(axilt_m_wready_1),

    .i_BRESP(axilt_m_bresp_1),
    .o_BREADY(axilt_m_bready_1),
    .i_BVALID(axilt_m_bvalid_1),

    .o_ARADDR(axilt_m_araddr_1),
    .o_ARVALID(axilt_m_arvalid_1),
    .i_ARREADY(axilt_m_arready_1),

    .i_RDATA(axilt_m_rdata_1),
    .i_RRESP(axilt_m_rresp_1),
    .i_RVALID(axilt_m_rvalid_1),
    .o_RREADY(axilt_m_rready_1)
);

axilt_interconnect_wrapper #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32),
    .N_MASTERS(2),
    .N_SLAVES(3),
    .MEM_BASE_0(32'h80000000), .MEM_SIZE_0(32'h10000000), /* UROM */
    .MEM_BASE_1(32'h90000000), .MEM_SIZE_1(32'h10000000), /* SRAM */
    .MEM_BASE_2(32'hA0000000), .MEM_SIZE_2(32'h10000000)  /* UART */
) axilt_ic_wrapper (

    .i_RST(~RSTn),
    .i_CLK(CLK),

    .i_s_AWADDR_0(axilt_m_awaddr_0),
    .i_s_AWVALID_0(axilt_m_awvalid_0),
    .o_s_AWREADY_0(axilt_m_awready_0),
    .i_s_WDATA_0(axilt_m_wdata_0),
    .i_s_WSTRB_0(axilt_m_wstrb_0),
    .i_s_WVALID_0(axilt_m_wvalid_0),
    .o_s_WREADY_0(axilt_m_wready_0),
    .o_s_BRESP_0(axilt_m_bresp_0),
    .o_s_BVALID_0(axilt_m_bvalid_0),
    .i_s_BREADY_0(axilt_m_bready_0),
    .i_s_ARADDR_0(axilt_m_araddr_0),
    .i_s_ARVALID_0(axilt_m_arvalid_0),
    .o_s_ARREADY_0(axilt_m_arready_0),
    .o_s_RDATA_0(axilt_m_rdata_0),
    .o_s_RRESP_0(axilt_m_rresp_0),
    .o_s_RVALID_0(axilt_m_rvalid_0),
    .i_s_RREADY_0(axilt_m_rready_0),

    .i_s_AWADDR_1(axilt_m_awaddr_1),
    .i_s_AWVALID_1(axilt_m_awvalid_1),
    .o_s_AWREADY_1(axilt_m_awready_1),
    .i_s_WDATA_1(axilt_m_wdata_1),
    .i_s_WSTRB_1(axilt_m_wstrb_1),
    .i_s_WVALID_1(axilt_m_wvalid_1),
    .o_s_WREADY_1(axilt_m_wready_1),
    .o_s_BRESP_1(axilt_m_bresp_1),
    .o_s_BVALID_1(axilt_m_bvalid_1),
    .i_s_BREADY_1(axilt_m_bready_1),
    .i_s_ARADDR_1(axilt_m_araddr_1),
    .i_s_ARVALID_1(axilt_m_arvalid_1),
    .o_s_ARREADY_1(axilt_m_arready_1),
    .o_s_RDATA_1(axilt_m_rdata_1),
    .o_s_RRESP_1(axilt_m_rresp_1),
    .o_s_RVALID_1(axilt_m_rvalid_1),
    .i_s_RREADY_1(axilt_m_rready_1),

    .o_m_AWADDR_0(axilt_s_awaddr_0),
    .o_m_AWVALID_0(axilt_s_awvalid_0),
    .i_m_AWREADY_0(axilt_s_awready_0),
    .o_m_WDATA_0(axilt_s_wdata_0),
    .o_m_WSTRB_0(axilt_s_wstrb_0),
    .o_m_WVALID_0(axilt_s_wvalid_0),
    .i_m_WREADY_0(axilt_s_wready_0),
    .i_m_BRESP_0(axilt_s_bresp_0),
    .i_m_BVALID_0(axilt_s_bvalid_0),
    .o_m_BREADY_0(axilt_s_bready_0),
    .o_m_ARADDR_0(axilt_s_araddr_0),
    .o_m_ARVALID_0(axilt_s_arvalid_0),
    .i_m_ARREADY_0(axilt_s_arready_0),
    .i_m_RDATA_0(axilt_s_rdata_0),
    .i_m_RRESP_0(axilt_s_rresp_0),
    .i_m_RVALID_0(axilt_s_rvalid_0),
    .o_m_RREADY_0(axilt_s_rready_0),

    .o_m_AWADDR_1(axilt_s_awaddr_1),
    .o_m_AWVALID_1(axilt_s_awvalid_1),
    .i_m_AWREADY_1(axilt_s_awready_1),
    .o_m_WDATA_1(axilt_s_wdata_1),
    .o_m_WSTRB_1(axilt_s_wstrb_1),
    .o_m_WVALID_1(axilt_s_wvalid_1),
    .i_m_WREADY_1(axilt_s_wready_1),
    .i_m_BRESP_1(axilt_s_bresp_1),
    .i_m_BVALID_1(axilt_s_bvalid_1),
    .o_m_BREADY_1(axilt_s_bready_1),
    .o_m_ARADDR_1(axilt_s_araddr_1),
    .o_m_ARVALID_1(axilt_s_arvalid_1),
    .i_m_ARREADY_1(axilt_s_arready_1),
    .i_m_RDATA_1(axilt_s_rdata_1),
    .i_m_RRESP_1(axilt_s_rresp_1),
    .i_m_RVALID_1(axilt_s_rvalid_1),
    .o_m_RREADY_1(axilt_s_rready_1),

    .o_m_AWADDR_2(axilt_s_awaddr_2),
    .o_m_AWVALID_2(axilt_s_awvalid_2),
    .i_m_AWREADY_2(axilt_s_awready_2),
    .o_m_WDATA_2(axilt_s_wdata_2),
    .o_m_WSTRB_2(axilt_s_wstrb_2),
    .o_m_WVALID_2(axilt_s_wvalid_2),
    .i_m_WREADY_2(axilt_s_wready_2),
    .i_m_BRESP_2(axilt_s_bresp_2),
    .i_m_BVALID_2(axilt_s_bvalid_2),
    .o_m_BREADY_2(axilt_s_bready_2),
    .o_m_ARADDR_2(axilt_s_araddr_2),
    .o_m_ARVALID_2(axilt_s_arvalid_2),
    .i_m_ARREADY_2(axilt_s_arready_2),
    .i_m_RDATA_2(axilt_s_rdata_2),
    .i_m_RRESP_2(axilt_s_rresp_2),
    .i_m_RVALID_2(axilt_s_rvalid_2),
    .o_m_RREADY_2(axilt_s_rready_2)
);

/* AXI-Lite Interface UROM */
axilt_urom_slave #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32)
) urom_slave_0 (
    .i_RST(~RSTn),
    .i_CLK(CLK),

    .i_PC_0({4'h0, pc_0[27:0]} >> 2),
    .o_INSTRUCTION_0(instruction_0),

    .i_PC_1({4'h0, pc_1[27:0]} >> 2),
    .o_INSTRUCTION_1(instruction_1),

    .i_AWADDR(axilt_s_awaddr_0),
    .i_AWVALID(axilt_s_awvalid_0),
    .o_AWREADY(axilt_s_awready_0),

    .i_WDATA(axilt_s_wdata_0),
    .i_WSTRB(axilt_s_wstrb_0),
    .i_WVALID(axilt_s_wvalid_0),
    .o_WREADY(axilt_s_wready_0),

    .o_BRESP(axilt_s_bresp_0),
    .o_BVALID(axilt_s_bvalid_0),
    .i_BREADY(axilt_s_bready_0),

    .i_ARADDR(axilt_s_araddr_0),
    .i_ARVALID(axilt_s_arvalid_0),
    .o_ARREADY(axilt_s_arready_0),

    .o_RDATA(axilt_s_rdata_0),
    .o_RRESP(axilt_s_rresp_0),
    .o_RVALID(axilt_s_rvalid_0),
    .i_RREADY(axilt_s_rready_0)
);

/* AXI-Lite Interface PRAM */
axilt_sram_slave #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32)
) sram_slave_0 (
    .i_CLK(CLK),
    .i_RST(~RSTn),

    .i_AWADDR(axilt_s_awaddr_1),
    .i_AWVALID(axilt_s_awvalid_1),
    .o_AWREADY(axilt_s_awready_1),

    .i_WDATA(axilt_s_wdata_1),
    .i_WSTRB(axilt_s_wstrb_1),
    .i_WVALID(axilt_s_wvalid_1),
    .o_WREADY(axilt_s_wready_1),

    .o_BRESP(axilt_s_bresp_1),
    .o_BVALID(axilt_s_bvalid_1),
    .i_BREADY(axilt_s_bready_1),

    .i_ARADDR(axilt_s_araddr_1),
    .i_ARVALID(axilt_s_arvalid_1),
    .o_ARREADY(axilt_s_arready_1),

    .o_RDATA(axilt_s_rdata_1),
    .o_RRESP(axilt_s_rresp_1),
    .o_RVALID(axilt_s_rvalid_1),
    .i_RREADY(axilt_s_rready_1)
);

/* UART */
wire [1:0] uart_irq;
uart uart0 (
    .i_RST(~RSTn),
    .i_CLK(CLK),

    .i_RX(i_UART_TXD),
    .o_TX(o_UART_RXD),
    .o_IRQ(uart_irq),

    .i_AWADDR(axilt_s_awaddr_2),
    .i_AWVALID(axilt_s_awvalid_2),
    .o_AWREADY(axilt_s_awready_2),

    .i_WDATA(axilt_s_wdata_2),
    .i_WSTRB(axilt_s_wstrb_2),
    .i_WVALID(axilt_s_wvalid_2),
    .o_WREADY(axilt_s_wready_2),

    .o_BRESP(axilt_s_bresp_2),
    .o_BVALID(axilt_s_bvalid_2),
    .i_BREADY(axilt_s_bready_2),

    .i_ARADDR(axilt_s_araddr_2),
    .i_ARVALID(axilt_s_arvalid_2),
    .o_ARREADY(axilt_s_arready_2),

    .o_RDATA(axilt_s_rdata_2),
    .o_RRESP(axilt_s_rresp_2),
    .o_RVALID(axilt_s_rvalid_2),
    .i_RREADY(axilt_s_rready_2)
);


/* EXT TIMER 
wire        TIMER_CE;
wire        TIMER_WE;
wire [31:0] TIMER_WDATA;
wire        TIMER_REQ;
wire        TIMER_GNT;
wire        TIMER_IRQ;

timer timer_ext
(
    .i_CLK(CLK),
    .i_RSTn(RSTn),
    .i_CE(TIMER_CE),
    .i_WE(TIMER_WE),
    .i_WDATA(TIMER_WDATA),
    .i_REQ(TIMER_REQ),
    .o_GNT(TIMER_GNT),
    .o_IRQ(TIMER_IRQ)
);

assign TIMER_CE     = BUS_CE[3];
assign TIMER_WE     = BUS_WE;
assign TIMER_WDATA  = BUS_WDATA;
assign TIMER_REQ    = BUS_REQ;
*/

/* GPIOs 
wire        GPIO_CE;
wire        GPIO_WE;
wire [31:0] GPIO_WDATA;
wire        GPIO_REQ;
wire        GPIO_GNT;
wire [31:0] GPIO_RDATA;
wire [0:7]  GPIO;
gpio gpio_0
(
    .i_CLK(CLK),
    .i_RSTn(RSTn),
    .i_CE(GPIO_CE),
    .i_WE(GPIO_WE),
    .i_WDATA(GPIO_WDATA),
    .i_REQ(GPIO_REQ),
    .o_GNT(GPIO_GNT),
    .o_RDATA(GPIO_RDATA),
    .o_GPIO(GPIO)
);

assign GPIO_CE      = BUS_CE[4];
assign GPIO_WE      = BUS_WE;
assign GPIO_WDATA   = BUS_WDATA;
assign GPIO_REQ     = BUS_REQ;
*/

/* BUS 
assign BUS_GNT = (UROM_CE&UROM_GNT) | (SRAM_CE&SRAM_GNT) | (UART_CE&UART_GNT) | (TIMER_CE*TIMER_GNT);

always @(*) begin
    case (1'b1)
    UROM_CE     : BUS_RDATA <= UROM_RDATA_DATA;
    SRAM_CE     : BUS_RDATA <= SRAM_RDATA;
    UART_CE     : BUS_RDATA <= UART_RDATA;
    default     : BUS_RDATA <= 32'dx;
    endcase
end

wire o_GPIO_7, o_GPIO_6, o_GPIO_5, o_GPIO_4, o_GPIO_3, o_GPIO_2; 

assign {o_GPIO_7,
        o_GPIO_6,
        o_GPIO_5,
        o_GPIO_4,
        o_GPIO_3,
        o_GPIO_2,
        o_GPIO_1,
        o_GPIO_0 
} = GPIO;
*/

endmodule