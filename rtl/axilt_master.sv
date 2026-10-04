module axilt_master #(
    parameter DATA_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH/8,
    parameter ADDR_WIDTH = 32
) (
    input  i_RST,
    input  i_CLK,

    input  i_LSU_REQ,
    input  [ADDR_WIDTH-1:0] i_LSU_ADDR,
    input  [DATA_WIDTH-1:0] i_LSU_DATA,
    input  i_LSU_WE,
    input  [1:0] i_LSU_HB,
    output logic [DATA_WIDTH-1:0] o_LSU_DATA,
    output logic o_LSU_GNT,

    /* Write Address Channel */
    output logic [ADDR_WIDTH-1:0] o_AWADDR,
    output logic o_AWVALID,
    input        i_AWREADY,
    /* Write Data Channel */
    output logic [DATA_WIDTH-1:0] o_WDATA,
    output logic [STRB_WIDTH-1:0] o_WSTRB,
    output logic o_WVALID,
    input        i_WREADY,
    /* Write Response Channel */
    input [1:0]  i_BRESP,
    output logic o_BREADY,
    input  logic i_BVALID,
    /* Read Address Channel */
    output logic [ADDR_WIDTH-1:0] o_ARADDR,
    output logic o_ARVALID,
    input        i_ARREADY,
    /* Read Data-Response Channel */
    input        [DATA_WIDTH-1:0] i_RDATA,
    input [1:0]  i_RRESP,
    input        i_RVALID,
    output logic o_RREADY

);

enum bit[1:0] {
    QWORD = 2'b00,
    HWORD = 2'b01,
    FWORD = 2'b10
} mode;

typedef enum {
    IDLE,
    LD_REQ_ADDR,
    LD_RESP,
    ST_REQ_ADDR,
    ST_REQ_DATA,
    ST_RESP
} state_t;

state_t state;

wire valid_request = i_LSU_REQ;

logic [1:0] ptr2;
logic [DATA_WIDTH-1:0] rdata_byte_00, rdata_byte_01, rdata_byte_10, rdata_byte_11;
logic [DATA_WIDTH-1:0] rdata_half_00, rdata_half_10;
logic [DATA_WIDTH-1:0] rdata_word_00;

logic [ADDR_WIDTH-1:0] waddr;
logic [DATA_WIDTH-1:0] wdata;
logic [STRB_WIDTH-1:0] wstrb;

logic write_complete;
logic read_complete;

assign write_complete = (state == ST_RESP)  & i_BVALID;
assign read_complete  = (state == LD_RESP)  & i_RVALID;

always_ff @(posedge i_CLK) begin
    if (i_RST) begin
        waddr <= {ADDR_WIDTH{1'b0}};
        wdata <= {DATA_WIDTH{1'b0}};
        wstrb <= {STRB_WIDTH{1'b0}};
    end
    else begin
        if (valid_request == 1'b1) begin
            waddr <= {i_LSU_ADDR[ADDR_WIDTH-1:2], 2'b00};

            case (i_LSU_HB)
            FWORD : begin
                wdata <= i_LSU_DATA;
                wstrb <= {STRB_WIDTH{1'b1}};
            end
            HWORD : begin
                wdata <= {
                    i_LSU_DATA[15:0],
                    i_LSU_DATA[15:0]
                };
                case (i_LSU_ADDR[1:0])
                2'b00 : begin
                    wstrb  <= 4'b0011;
                end
                2'b10 : begin
                    wstrb  <= 4'b1100;
                end
                default : begin
                    wstrb  <= 4'b0000;
                end
                endcase
            end
            QWORD : begin
                wdata <= {
                    i_LSU_DATA[7:0],
                    i_LSU_DATA[7:0],
                    i_LSU_DATA[7:0],
                    i_LSU_DATA[7:0]
                };
                case (i_LSU_ADDR[1:0])
                2'b00 : begin
                    wstrb  <= 4'b0001;
                end
                2'b01 : begin
                    wstrb  <= 4'b0010;
                end
                2'b10 : begin
                    wstrb  <= 4'b0100;
                end
                2'b11 : begin
                    wstrb  <= 4'b1000;
                end
                default : begin
                    wstrb  <= 4'b0000;
                end
                endcase
            end
            default : begin
                wdata <= {DATA_WIDTH{1'b0}};
                wstrb <= {STRB_WIDTH{1'b0}};
            end
            endcase
        end
    end
end

always_ff @(posedge i_CLK) begin
    if (i_RST) begin
        state <= IDLE;
    end
    else begin
        case (state)
        IDLE : begin
            if (valid_request == 1'b1) begin
                if (i_LSU_WE == 1'b1) begin
                    state <= ST_REQ_ADDR;
                end
                else begin
                    state <= LD_REQ_ADDR;
                end
            end
        end

        /* Write Path */
        ST_REQ_ADDR : begin
            if (i_AWREADY == 1'b1) begin
                state <= ST_REQ_DATA;
            end
        end
        ST_REQ_DATA : begin
            if (i_WREADY == 1'b1) begin
                state <= ST_RESP;
            end
        end
        ST_RESP : begin
            if (i_BVALID == 1'b1) begin
                state <= IDLE;
            end
        end

        /* Read Path */
        LD_REQ_ADDR : begin
            if (i_ARREADY == 1'b1) begin
                state <= LD_RESP;
            end
        end
        LD_RESP : begin
            if (i_RVALID == 1'b1) begin
                state <= IDLE;
            end
        end
        endcase

    end
end

always_comb begin
    o_AWADDR  = waddr;
    o_AWVALID = (state == ST_REQ_ADDR);

    o_WDATA   = wdata;
    o_WSTRB   = wstrb;
    o_WVALID  = (state == ST_REQ_DATA);

    o_BREADY  = (state == ST_RESP);

    o_ARADDR  = waddr;
    o_ARVALID = (state == LD_REQ_ADDR);

    o_RREADY  = (state == LD_RESP);
end

assign ptr2 = i_LSU_ADDR[1:0];

assign rdata_word_00 = i_RDATA;

assign rdata_half_00 = {{16{i_RDATA[15]}}, i_RDATA[15:0]};
assign rdata_half_10 = {{16{i_RDATA[31]}}, i_RDATA[31:16]};

assign rdata_byte_00 = {{24{i_RDATA[7]}},  i_RDATA[7:0]};
assign rdata_byte_01 = {{24{i_RDATA[15]}}, i_RDATA[15:8]};
assign rdata_byte_10 = {{24{i_RDATA[23]}}, i_RDATA[23:16]};
assign rdata_byte_11 = {{24{i_RDATA[31]}}, i_RDATA[31:24]};

always_comb begin
    o_LSU_GNT = write_complete | read_complete;
    o_LSU_DATA = 0;
    case (i_LSU_HB)
    FWORD : begin
        o_LSU_DATA = rdata_word_00;
    end
    HWORD : begin
        case (ptr2)
        2'b00 : begin
            o_LSU_DATA = rdata_half_00;
        end
        2'b10 : begin
            o_LSU_DATA = rdata_half_10;
        end
        endcase
    end
    QWORD : begin
        case (ptr2)
        2'b00 : begin
            o_LSU_DATA = rdata_byte_00;
        end
        2'b01 : begin
            o_LSU_DATA = rdata_byte_01;
        end
        2'b10 : begin
            o_LSU_DATA = rdata_byte_10;
        end
        2'b11 : begin
            o_LSU_DATA = rdata_byte_11;
        end
        endcase
    end
    endcase
end

endmodule
