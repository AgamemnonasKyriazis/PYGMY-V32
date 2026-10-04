module axilt_urom_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input  i_RST,
    input  i_CLK,

    input  [ADDR_WIDTH-1:0] i_PC_0,
    output logic [DATA_WIDTH-1:0] o_INSTRUCTION_0,

    input  [ADDR_WIDTH-1:0] i_PC_1,
    output logic [DATA_WIDTH-1:0] o_INSTRUCTION_1,

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

/* UROM is read-only over the bus, exactly like the Wishbone slave it
   replaces (which never even wired up a write-enable input). Writes are
   accepted and acked so they never stall the interconnect, but they
   never touch memory. */

typedef enum {
    IDLE,
    WDATA,
    WRESP,
    RDATA
} state_t;

state_t state;

logic rom_ce;
logic [ADDR_WIDTH-1:0] rom_addr;
wire  [DATA_WIDTH-1:0] rom_rdata;
wire  rom_valid;

always_ff @(posedge i_CLK) begin
    if (i_RST) begin
        state <= IDLE;
    end
    else begin
        case (state)
        IDLE : begin
            if (i_AWVALID == 1'b1) begin
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
            if (i_BREADY == 1'b1) begin
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

assign o_BVALID = (state == WRESP);
assign o_BRESP  = AXI_OKAY;

assign rom_ce   = (state == IDLE) & i_ARVALID & ~i_AWVALID;
assign rom_addr = i_ARADDR >> 2;

urom #(
    .UROM_DEPTH(4096)
) block_rom (
    .i_CE(rom_ce),
    .i_CLK(i_CLK),
    .i_PC_0(i_PC_0),
    .o_INSTRUCTION_0(o_INSTRUCTION_0),
    .i_PC_1(i_PC_1),
    .o_INSTRUCTION_1(o_INSTRUCTION_1),
    .i_ADDR(rom_addr),
    .o_RDATA(rom_rdata),
    .o_VALID(rom_valid)
);

always_ff @(posedge i_CLK) begin
    if (i_RST) begin
        o_RVALID <= 1'b0;
        o_RRESP  <= AXI_OKAY;
        o_RDATA  <= {DATA_WIDTH{1'b0}};
    end
    else begin
        if (rom_valid == 1'b1 && state == RDATA) begin
            o_RVALID <= 1'b1;
            o_RRESP  <= AXI_OKAY;
            o_RDATA  <= rom_rdata;
        end
        else if (o_RVALID == 1'b1 && i_RREADY == 1'b1) begin
            o_RVALID <= 1'b0;
        end
    end
end

endmodule
