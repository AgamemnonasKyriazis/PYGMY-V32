module axilt_sram_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input  i_RST,
    input  i_CLK,

    input  [ADDR_WIDTH-1:0] i_AWADDR,
    input  i_AWVALID,
    output logic o_AWREADY,

    input  [DATA_WIDTH-1:0] i_WDATA,
    input  [3:0] i_WSTRB,
    input  i_WVALID,
    output logic o_WREADY,

    output logic [1:0] o_BRESP,
    output logic o_BVALID,
    input  i_BREADY,

    input  [ADDR_WIDTH-1:0] i_ARADDR,
    input  i_ARVALID,
    output logic o_ARREADY,

    output logic [DATA_WIDTH-1:0] o_RDATA,
    output logic [1:0] o_RRESP,
    output logic o_RVALID,
    input  i_RREADY
);

`include "axilt.vh"

typedef enum {
    IDLE,
    WDATA,
    WRESP,
    RDATA
} state_t;

state_t state;

logic [ADDR_WIDTH-1:0] waddr;

logic ram_ce;
logic [3:0] ram_we;
logic [ADDR_WIDTH-1:0] ram_addr;
logic [DATA_WIDTH-1:0] ram_wdata;
wire  [DATA_WIDTH-1:0] ram_rdata;
wire  ram_valid;

always_ff @(posedge i_CLK) begin
    if (i_RST) begin
        state <= IDLE;
    end
    else begin
        case (state)
        IDLE : begin
            if (i_AWVALID == 1'b1) begin
                waddr <= i_AWADDR;
                state <= WDATA;
            end
            else if (i_ARVALID == 1'b1) begin
                state <= RDATA;
            end
        end
        WDATA : begin
            if (i_WVALID == 1'b1) begin
                state <= WRESP;
            end
        end
        WRESP : begin
            if (o_BVALID & i_BREADY) begin
                state <= IDLE;
            end
        end
        RDATA : begin
            if (o_RVALID & i_RREADY) begin
                state <= IDLE;
            end
        end
        endcase
    end
end

assign o_AWREADY = (state == IDLE);
assign o_ARREADY = (state == IDLE) & ~i_AWVALID;
assign o_WREADY  = (state == WDATA);

always_comb begin
    ram_ce    = 1'b0;
    ram_we    = 4'b0000;
    ram_addr  = {ADDR_WIDTH{1'b0}};
    ram_wdata = {DATA_WIDTH{1'b0}};

    case (state)
    IDLE : begin
        if (i_ARVALID == 1'b1 && i_AWVALID == 1'b0) begin
            ram_ce   = 1'b1;
            ram_addr = i_ARADDR >> 2;
        end
    end
    WDATA : begin
        if (i_WVALID == 1'b1) begin
            ram_ce    = 1'b1;
            ram_we    = i_WSTRB;
            ram_addr  = waddr >> 2;
            ram_wdata = i_WDATA;
        end
    end
    default : ;
    endcase
end

pram #(.SRAM_DEPTH(4096)) block_ram (
    .i_CE(ram_ce),
    .i_CLK(i_CLK),
    .i_WDATA(ram_wdata),
    .i_ADDR(ram_addr),
    .i_WE(ram_we),
    .o_RDATA(ram_rdata),
    .o_VALID(ram_valid)
);

always_ff @(posedge i_CLK) begin
    if (i_RST) begin
        o_BVALID <= 1'b0;
        o_BRESP  <= AXI_OKAY;
    end
    else begin
        if (ram_valid == 1'b1 && state == WRESP) begin
            o_BVALID <= 1'b1;
            o_BRESP  <= AXI_OKAY;
        end
        else if (o_BVALID == 1'b1 && i_BREADY == 1'b1) begin
            o_BVALID <= 1'b0;
        end
    end
end

always_ff @(posedge i_CLK) begin
    if (i_RST) begin
        o_RVALID <= 1'b0;
        o_RRESP  <= AXI_OKAY;
        o_RDATA  <= {DATA_WIDTH{1'b0}};
    end
    else begin
        if (ram_valid == 1'b1 && state == RDATA) begin
            o_RVALID <= 1'b1;
            o_RRESP  <= AXI_OKAY;
            o_RDATA  <= ram_rdata;
        end
        else if (o_RVALID == 1'b1 && i_RREADY == 1'b1) begin
            o_RVALID <= 1'b0;
        end
    end
end

endmodule
