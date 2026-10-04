module axilt_interconnect #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH/8,
    parameter N_MASTERS  = 2,
    parameter N_SLAVES   = 2,

    /* Icarus Verilog chokes on unpacked/packed array parameters, so each
       target's base/size window is passed as its own scalar parameter
       (up to 8 targets, matching the README's peripheral slot budget)
       instead of an MEM_BASE[]/MEM_SIZE[] array parameter. */
    parameter [ADDR_WIDTH-1:0] MEM_BASE_0 = 0, parameter [ADDR_WIDTH-1:0] MEM_SIZE_0 = 0,
    parameter [ADDR_WIDTH-1:0] MEM_BASE_1 = 0, parameter [ADDR_WIDTH-1:0] MEM_SIZE_1 = 0,
    parameter [ADDR_WIDTH-1:0] MEM_BASE_2 = 0, parameter [ADDR_WIDTH-1:0] MEM_SIZE_2 = 0,
    parameter [ADDR_WIDTH-1:0] MEM_BASE_3 = 0, parameter [ADDR_WIDTH-1:0] MEM_SIZE_3 = 0,
    parameter [ADDR_WIDTH-1:0] MEM_BASE_4 = 0, parameter [ADDR_WIDTH-1:0] MEM_SIZE_4 = 0,
    parameter [ADDR_WIDTH-1:0] MEM_BASE_5 = 0, parameter [ADDR_WIDTH-1:0] MEM_SIZE_5 = 0,
    parameter [ADDR_WIDTH-1:0] MEM_BASE_6 = 0, parameter [ADDR_WIDTH-1:0] MEM_SIZE_6 = 0,
    parameter [ADDR_WIDTH-1:0] MEM_BASE_7 = 0, parameter [ADDR_WIDTH-1:0] MEM_SIZE_7 = 0
) (

    input  i_RST,
    input  i_CLK,

    /* Slave side (initiators attach here) */
    input  [N_MASTERS-1:0] [ADDR_WIDTH-1:0] i_s_AWADDR,
    input  [N_MASTERS-1:0] i_s_AWVALID,
    output logic [N_MASTERS-1:0] o_s_AWREADY,

    input  [N_MASTERS-1:0] [DATA_WIDTH-1:0] i_s_WDATA,
    input  [N_MASTERS-1:0] [STRB_WIDTH-1:0] i_s_WSTRB,
    input  [N_MASTERS-1:0] i_s_WVALID,
    output logic [N_MASTERS-1:0] o_s_WREADY,

    output logic [N_MASTERS-1:0] [1:0] o_s_BRESP,
    output logic [N_MASTERS-1:0] o_s_BVALID,
    input  [N_MASTERS-1:0] i_s_BREADY,

    input  [N_MASTERS-1:0] [ADDR_WIDTH-1:0] i_s_ARADDR,
    input  [N_MASTERS-1:0] i_s_ARVALID,
    output logic [N_MASTERS-1:0] o_s_ARREADY,

    output logic [N_MASTERS-1:0] [DATA_WIDTH-1:0] o_s_RDATA,
    output logic [N_MASTERS-1:0] [1:0] o_s_RRESP,
    output logic [N_MASTERS-1:0] o_s_RVALID,
    input  [N_MASTERS-1:0] i_s_RREADY,

    /* Master side (targets attach here) */
    output logic [N_SLAVES-1:0] [ADDR_WIDTH-1:0] o_m_AWADDR,
    output logic [N_SLAVES-1:0] o_m_AWVALID,
    input  [N_SLAVES-1:0] i_m_AWREADY,

    output logic [N_SLAVES-1:0] [DATA_WIDTH-1:0] o_m_WDATA,
    output logic [N_SLAVES-1:0] [STRB_WIDTH-1:0] o_m_WSTRB,
    output logic [N_SLAVES-1:0] o_m_WVALID,
    input  [N_SLAVES-1:0] i_m_WREADY,

    input  [N_SLAVES-1:0] [1:0] i_m_BRESP,
    input  [N_SLAVES-1:0] i_m_BVALID,
    output logic [N_SLAVES-1:0] o_m_BREADY,

    output logic [N_SLAVES-1:0] [ADDR_WIDTH-1:0] o_m_ARADDR,
    output logic [N_SLAVES-1:0] o_m_ARVALID,
    input  [N_SLAVES-1:0] i_m_ARREADY,

    input  [N_SLAVES-1:0] [DATA_WIDTH-1:0] i_m_RDATA,
    input  [N_SLAVES-1:0] [1:0] i_m_RRESP,
    input  [N_SLAVES-1:0] i_m_RVALID,
    output logic [N_SLAVES-1:0] o_m_RREADY
);

`include "axilt.vh"

localparam N_REQUEST_SLOTS = 2 * N_MASTERS;

function automatic [ADDR_WIDTH-1:0] mem_base_of (input integer idx);
    case (idx)
    0 : mem_base_of = MEM_BASE_0;
    1 : mem_base_of = MEM_BASE_1;
    2 : mem_base_of = MEM_BASE_2;
    3 : mem_base_of = MEM_BASE_3;
    4 : mem_base_of = MEM_BASE_4;
    5 : mem_base_of = MEM_BASE_5;
    6 : mem_base_of = MEM_BASE_6;
    7 : mem_base_of = MEM_BASE_7;
    default : mem_base_of = {ADDR_WIDTH{1'b0}};
    endcase
endfunction

function automatic [ADDR_WIDTH-1:0] mem_size_of (input integer idx);
    case (idx)
    0 : mem_size_of = MEM_SIZE_0;
    1 : mem_size_of = MEM_SIZE_1;
    2 : mem_size_of = MEM_SIZE_2;
    3 : mem_size_of = MEM_SIZE_3;
    4 : mem_size_of = MEM_SIZE_4;
    5 : mem_size_of = MEM_SIZE_5;
    6 : mem_size_of = MEM_SIZE_6;
    7 : mem_size_of = MEM_SIZE_7;
    default : mem_size_of = {ADDR_WIDTH{1'b0}};
    endcase
endfunction

logic [ADDR_WIDTH-1:0] mem_base [0:N_SLAVES-1];
logic [ADDR_WIDTH-1:0] mem_size [0:N_SLAVES-1];

genvar gs;
generate
    for (gs = 0; gs < N_SLAVES; gs = gs + 1) begin : gen_mem_window
        assign mem_base[gs] = mem_base_of(gs);
        assign mem_size[gs] = mem_size_of(gs);
    end
endgenerate

typedef enum {
    IDLE,
    WRITE_REQUEST,
    WRITE_RESPONSE,
    READ_REQUEST,
    READ_RESPONSE
} state_t;

state_t state;

integer round_robin_slot;

integer selected_slot;
integer selected_initiator;
logic   selected_target_valid;
integer selected_target_index;
logic [ADDR_WIDTH-1:0] selected_address;

logic aw_done;
logic w_done;

/* Round-robin arbitration: even slot = that master's write (AW) request,
   odd slot = that master's read (AR) request. */
logic                   arbitration_valid;
integer                 arbitration_slot;
integer                 arbitration_initiator;
logic                   arbitration_write;
logic [ADDR_WIDTH-1:0]  arbitration_address;

always_comb begin : ARBITRATE
    integer offset;
    integer candidate_slot;
    integer candidate_init;
    logic   found;

    arbitration_valid     = 1'b0;
    arbitration_slot      = round_robin_slot;
    arbitration_initiator = round_robin_slot / 2;
    arbitration_write     = 1'b0;
    arbitration_address   = {ADDR_WIDTH{1'b0}};
    found = 1'b0;

    for (offset = 0; offset < N_REQUEST_SLOTS; offset = offset + 1) begin
        candidate_slot = (round_robin_slot + offset) % N_REQUEST_SLOTS;
        candidate_init = candidate_slot / 2;
        if (!found) begin
            if ((candidate_slot % 2) == 0) begin
                if (i_s_AWVALID[candidate_init] == 1'b1) begin
                    arbitration_valid     = 1'b1;
                    arbitration_slot      = candidate_slot;
                    arbitration_initiator = candidate_init;
                    arbitration_write     = 1'b1;
                    arbitration_address   = i_s_AWADDR[candidate_init];
                    found = 1'b1;
                end
            end
            else if (i_s_ARVALID[candidate_init] == 1'b1) begin
                arbitration_valid     = 1'b1;
                arbitration_slot      = candidate_slot;
                arbitration_initiator = candidate_init;
                arbitration_write     = 1'b0;
                arbitration_address   = i_s_ARADDR[candidate_init];
                found = 1'b1;
            end
        end
    end
end

/* Address decode: range-compare against each target's [base, base+size)
   window. No match -> DECERR back to the initiator. */
logic                  decoded_target_valid;
integer                decoded_target_index;
logic [ADDR_WIDTH-1:0] rebased_address;

always_comb begin : DECODE_ADDRESS
    integer index;
    logic   found;

    decoded_target_valid = 1'b0;
    decoded_target_index = 0;
    rebased_address       = {ADDR_WIDTH{1'b0}};
    found = 1'b0;

    for (index = 0; index < N_SLAVES; index = index + 1) begin
        if (!found &&
            (arbitration_address >= mem_base[index]) &&
            (arbitration_address < (mem_base[index] + mem_size[index]))) begin
            decoded_target_valid = 1'b1;
            decoded_target_index = index;
            rebased_address       = arbitration_address - mem_base[index];
            found = 1'b1;
        end
    end
end

always_comb begin : ROUTE_CHANNELS
    integer i, t;

    for (i = 0; i < N_MASTERS; i = i + 1) begin
        o_s_AWREADY[i] = 1'b0;
        o_s_WREADY[i]  = 1'b0;
        o_s_BRESP[i]   = AXI_OKAY;
        o_s_BVALID[i]  = 1'b0;
        o_s_ARREADY[i] = 1'b0;
        o_s_RDATA[i]   = {DATA_WIDTH{1'b0}};
        o_s_RRESP[i]   = AXI_OKAY;
        o_s_RVALID[i]  = 1'b0;
    end

    for (t = 0; t < N_SLAVES; t = t + 1) begin
        o_m_AWADDR[t]  = selected_address;
        o_m_AWVALID[t] = 1'b0;
        o_m_WDATA[t]   = i_s_WDATA[selected_initiator];
        o_m_WSTRB[t]   = i_s_WSTRB[selected_initiator];
        o_m_WVALID[t]  = 1'b0;
        o_m_BREADY[t]  = 1'b0;
        o_m_ARADDR[t]  = selected_address;
        o_m_ARVALID[t] = 1'b0;
        o_m_RREADY[t]  = 1'b0;
    end

    case (state)
    WRITE_REQUEST : begin
        if (selected_target_valid) begin
            o_m_AWVALID[selected_target_index] = i_s_AWVALID[selected_initiator] & ~aw_done;
            o_s_AWREADY[selected_initiator]    = i_m_AWREADY[selected_target_index] & ~aw_done;
            o_m_WVALID[selected_target_index]  = i_s_WVALID[selected_initiator] & ~w_done;
            o_s_WREADY[selected_initiator]     = i_m_WREADY[selected_target_index] & ~w_done;
        end
        else begin
            o_s_AWREADY[selected_initiator] = ~aw_done;
            o_s_WREADY[selected_initiator]  = ~w_done;
        end
    end

    WRITE_RESPONSE : begin
        if (selected_target_valid) begin
            o_s_BRESP[selected_initiator]      = i_m_BRESP[selected_target_index];
            o_s_BVALID[selected_initiator]     = i_m_BVALID[selected_target_index];
            o_m_BREADY[selected_target_index]  = i_s_BREADY[selected_initiator];
        end
        else begin
            o_s_BRESP[selected_initiator]  = AXI_DECERR;
            o_s_BVALID[selected_initiator] = 1'b1;
        end
    end

    READ_REQUEST : begin
        if (selected_target_valid) begin
            o_m_ARVALID[selected_target_index] = i_s_ARVALID[selected_initiator];
            o_s_ARREADY[selected_initiator]    = i_m_ARREADY[selected_target_index];
        end
        else begin
            o_s_ARREADY[selected_initiator] = 1'b1;
        end
    end

    READ_RESPONSE : begin
        if (selected_target_valid) begin
            o_s_RDATA[selected_initiator]     = i_m_RDATA[selected_target_index];
            o_s_RRESP[selected_initiator]     = i_m_RRESP[selected_target_index];
            o_s_RVALID[selected_initiator]    = i_m_RVALID[selected_target_index];
            o_m_RREADY[selected_target_index] = i_s_RREADY[selected_initiator];
        end
        else begin
            o_s_RDATA[selected_initiator]  = {DATA_WIDTH{1'b0}};
            o_s_RRESP[selected_initiator]  = AXI_DECERR;
            o_s_RVALID[selected_initiator] = 1'b1;
        end
    end

    default : ;
    endcase
end

always_ff @(posedge i_CLK) begin : CONTROL
    logic aw_fire;
    logic w_fire;
    logic aw_complete;
    logic w_complete;
    logic response_fire;

    if (i_RST) begin
        state                  <= IDLE;
        round_robin_slot       <= 0;
        selected_slot          <= 0;
        selected_initiator     <= 0;
        selected_target_valid  <= 1'b0;
        selected_target_index  <= 0;
        selected_address       <= {ADDR_WIDTH{1'b0}};
        aw_done                <= 1'b0;
        w_done                 <= 1'b0;
    end
    else begin
        case (state)
        IDLE : begin
            aw_done <= 1'b0;
            w_done  <= 1'b0;
            if (arbitration_valid == 1'b1) begin
                selected_slot          <= arbitration_slot;
                selected_initiator     <= arbitration_initiator;
                selected_target_valid  <= decoded_target_valid;
                selected_target_index  <= decoded_target_index;
                selected_address       <= rebased_address;
                if (arbitration_write == 1'b1) begin
                    state <= WRITE_REQUEST;
                end
                else begin
                    state <= READ_REQUEST;
                end
            end
        end

        WRITE_REQUEST : begin
            aw_fire = i_s_AWVALID[selected_initiator] & o_s_AWREADY[selected_initiator];
            w_fire  = i_s_WVALID[selected_initiator]  & o_s_WREADY[selected_initiator];
            aw_complete = aw_done | aw_fire;
            w_complete  = w_done  | w_fire;

            if (aw_fire) begin
                aw_done <= 1'b1;
            end
            if (w_fire) begin
                w_done <= 1'b1;
            end
            if (aw_complete && w_complete) begin
                state <= WRITE_RESPONSE;
            end
        end

        WRITE_RESPONSE : begin
            response_fire = o_s_BVALID[selected_initiator] & i_s_BREADY[selected_initiator];
            if (response_fire) begin
                round_robin_slot <= (selected_slot + 1) % N_REQUEST_SLOTS;
                state <= IDLE;
            end
        end

        READ_REQUEST : begin
            if (i_s_ARVALID[selected_initiator] == 1'b1 &&
                o_s_ARREADY[selected_initiator] == 1'b1) begin
                state <= READ_RESPONSE;
            end
        end

        READ_RESPONSE : begin
            response_fire = o_s_RVALID[selected_initiator] & i_s_RREADY[selected_initiator];
            if (response_fire) begin
                round_robin_slot <= (selected_slot + 1) % N_REQUEST_SLOTS;
                state <= IDLE;
            end
        end
        endcase
    end
end

endmodule
