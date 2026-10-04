`timescale 1ns / 1ps

module decode #(
    parameter [31:0] HART_ID = 32'h00000000
) (  
    input wire          i_CLK,
    input wire          i_RSTn,

    input wire          i_EN,

    input  wire         i_IRQ,
    output wire [7:0]   o_CORE_STATE,

    input wire          i_INSTRUCTION_VALID,
    input wire  [31:0]  i_INSTRUCTION,
    input wire  [31:0]  i_MTVEC,
    input wire  [31:0]  i_MEPC,
    
    input wire  [31:0]  i_RD,
    input wire  [4:0]   i_RD_PTR,
    input wire          i_REG_WE,

    output reg  [2:0]   o_FUNCT3,
    output reg  [6:0]   o_FUNCT7,
    output reg  [4:0]   o_RD_PTR,

    output reg  [31:0]  o_RS1,
    output reg  [31:0]  o_RS2,
    output reg  [31:0]  o_IMM_VAL,

    output reg  [1:0]   o_ALU_OP,
    output reg          o_REG_WE,
    output reg          o_MEM_WE,
    output reg          o_MEM_RE,
    output reg          o_ECALL,
    output reg          o_IMM,
    output reg          o_JAL,
    output reg          o_LUI,
    output reg          o_AUIPC,

    output wire [31:0]  o_PC,
    output reg  [31:0]  o_PC_PIPELINE,
    output reg  [31:0]  o_INSTRUCTION
    /*-----------------------------------*/
);

`include "core.vh"
`include "control_status_registers.vh"

wire stall = ~i_EN;

wire [31:0] instruction;
wire [6:0]  opcode  = instruction[6:0];

wire isAluReg       = (opcode == ALU_R);
wire isAluImm       = (opcode == ALU_I);
wire isLoad         = (opcode == LOAD);
wire isStore        = (opcode == STORE);
wire isBranch       = (opcode == BRANCH);
wire isJal          = (opcode == JAL);
wire isLui          = (opcode == LUI);
wire isAuipc        = (opcode == AUIPC);
wire isEcall        = (opcode == ECALL);
wire isJalr         = (opcode == JALR);
wire isSystem       = (opcode == SYSTEM);

wire isNoop         = (instruction == NOOP);
wire isWfi          = (instruction == WFI);
wire isMret         = (instruction == MRET);

wire mask_instruction_noop;

wire [2:0] funct3   = instruction[14:12];
wire [6:0] funct7   = instruction[31:25];
wire [7:0] funct3I  = 8'b00000001 << funct3;

wire signed [31:0] rs1;
wire signed [31:0] rs2;

wire [4:0] rd_ptr   = instruction[11:7];
wire [4:0] rs1_ptr  = instruction[19:15];
wire [4:0] rs2_ptr  = instruction[24:20];

wire [4:0]  rd_ptr_i = i_RD_PTR;
wire [31:0] rd_i     = i_RD;
wire        reg_we_i = i_REG_WE;

/* REGISTER FILE */
regfile #(.HART_ID(HART_ID)) registers (
    .i_CLK(i_CLK),
    .i_WE(reg_we_i),
    .i_RD_PTR(rd_ptr_i),
    .i_RD(rd_i),
    .i_RS1_PTR(rs1_ptr),
    .o_RS1(rs1),
    .i_RS2_PTR(rs2_ptr),
    .o_RS2(rs2)
);

/* Equal */
wire EQ  = rs1 == rs2;
/* Not Equal */
wire NE  = ~EQ;
/* Less */
wire LT  = rs1 < rs2;
/* Greater or Equal */
wire GT  = ~LT;
/* Less (unsigned) */
wire LTU = $unsigned(rs1) < $unsigned(rs2);
/* Greater or Equal (unsigned) */
wire GTU = ~LTU;
/* Branch is Followed */
wire isFollowed = 
    (isBranch & 
    ((funct3I[0] & EQ) |
     (funct3I[1] & NE) |
     (funct3I[4] & LT) |
     (funct3I[5] & GT) |
     (funct3I[6] & LTU)|
     (funct3I[7] & GTU)));

wire [31:0] IMM_J   = { {11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0 };
wire [31:0] IMM_B   = { {19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0 };
wire [31:0] IMM_R   = { {20{instruction[31]}}, instruction[31:20] };
wire [31:0] IMM_U   = { instruction[31:12], 12'b0 };
wire [31:0] IMM_S   = { {20{instruction[31]}}, instruction[31:25], instruction[11:7] };
wire [31:0] IMM_SFT = { 25'b0, instruction[24:20] };
wire [31:0] IMM_CSR = { 20'b0, instruction[31:20] };

/* CORE CONTROL */
reg  [7:0]  coreState;
reg  [7:0]  coreStateNext;

reg  [31:0] pc;
reg  [31:0] pc_next;

assign mask_instruction_noop = (
            (i_IRQ == 1'b1 && coreState == CORE_STATE_EXEC && coreStateNext == CORE_STATE_TRAP)
        ||  (coreState == CORE_STATE_HALT)
    );

always @(*) begin
    coreStateNext = coreState;
    case (coreState)
    CORE_STATE_EXEC : begin
        if (i_IRQ) begin
            coreStateNext = CORE_STATE_TRAP;
        end
        else if (isWfi) begin
            coreStateNext = CORE_STATE_HALT;
        end
    end
    CORE_STATE_TRAP : begin
        if (isMret) begin
            coreStateNext = CORE_STATE_EXEC;
        end
    end
    CORE_STATE_HALT : begin
        if (i_IRQ) begin
            coreStateNext = CORE_STATE_TRAP;
        end
    end
    endcase
end

always @(posedge i_CLK) begin
    if (~i_RSTn) begin
        coreState <= CORE_STATE_EXEC;
    end
    else if (i_EN & i_INSTRUCTION_VALID) begin
        coreState <= coreStateNext;
    end
end
assign o_CORE_STATE = coreState;

assign instruction = i_INSTRUCTION;

/* PROGRAM COUNTER CONTROL */
reg  [31:0] pc_op1;
reg  [31:0] pc_op2;

always @(*) begin
    pc_op1 = (isJalr)? rs1 : pc;
end

always @(*) begin : programCounterIncrement
    if (isJal)
        pc_op2 = IMM_J;
    else if (isJalr)
        pc_op2 = IMM_R;
    else if (isFollowed & isBranch)
        pc_op2 = IMM_B;
    else
        pc_op2 = 32'd4;
end

always @(*) begin : prograCounterNext
    pc_next = pc_op1 + pc_op2;
    case (coreState)
    CORE_STATE_EXEC : begin
        if (i_IRQ)
            pc_next = i_MTVEC;
    end
    CORE_STATE_TRAP : begin
        if (isMret)
            pc_next = i_MEPC;
    end
    CORE_STATE_HALT : begin
        if (i_IRQ)
            pc_next = i_MTVEC;
        else
            pc_next = pc;
    end
    endcase
end

always @(posedge i_CLK) begin : ProgramPointer
    if (~i_RSTn) begin
        pc  <= RESET_VECTOR;
    end
    else if (i_EN) begin
        pc  <= pc_next;
    end
end

assign o_PC = pc;


/* SIGNAL DECODE CONTROL */

always @(posedge i_CLK) begin
    if (~i_RSTn) begin
        o_ALU_OP  <= 2'b0;
        o_REG_WE  <= 1'b0;
        o_MEM_WE  <= 1'b0;
        o_MEM_RE  <= 1'b0;
        o_ECALL   <= 1'b0;
        o_IMM     <= 1'b0;
        o_JAL     <= 1'b0;
        o_LUI     <= 1'b0;
        o_AUIPC   <= 1'b0;
    end
    else if (i_EN) begin
        if (mask_instruction_noop == 1'b1) begin
            o_ALU_OP  <= {1'b0, 1'b1};
            o_REG_WE  <= 1'b0;
            o_MEM_WE  <= 1'b0;
            o_MEM_RE  <= 1'b0;
            o_ECALL   <= 1'b0;
            o_IMM     <= 1'b0;
            o_JAL     <= 1'b0;
            o_LUI     <= 1'b0;
            o_AUIPC   <= 1'b0;
        end
        else begin
            o_ALU_OP  <= {1'b0, isAluReg | isAluImm};
            o_REG_WE  <= isAluReg | isAluImm | isLoad | isJal | isJalr | isLui | isAuipc | isEcall;
            o_MEM_WE  <= isStore;
            o_MEM_RE  <= isLoad;
            o_ECALL   <= isEcall;
            o_IMM     <= isAluImm | isLoad | isStore | isJal | isJalr | isLui | isAuipc | isEcall;
            o_JAL     <= isJal | isJalr;
            o_LUI     <= isLui;
            o_AUIPC   <= isAuipc;
        end
    end
end

always @(posedge i_CLK) begin
    if (i_EN) begin
        if (mask_instruction_noop == 1'b1) begin
            o_FUNCT3 <= 3'b0;
            o_FUNCT7 <= 7'b0;    
        end
        else begin
            o_FUNCT3 <= funct3;
            o_FUNCT7 <= funct7;    
        end
    end
end

always @(posedge i_CLK) begin : OutRegs
    if (i_EN) begin
        o_PC_PIPELINE <= pc;
        if (mask_instruction_noop == 1'b1) begin
            o_RS1         <= 32'b0;
            o_RS2         <= 32'b0;
            o_RD_PTR      <= 5'b0;
        end
        else begin
            o_RS1         <= rs1;
            o_RS2         <= rs2;
            o_RD_PTR      <= rd_ptr;
        end
    end
end

always @(posedge i_CLK) begin : OutInstruction
    if (i_EN) begin
        o_INSTRUCTION <= instruction;
        if (mask_instruction_noop == 1'b1) begin
            o_INSTRUCTION <= NOOP;
        end
    end
end

always @(posedge i_CLK) begin
    if (i_EN) begin
        if (mask_instruction_noop == 1'b1) begin
            o_IMM_VAL <= 32'b0;
        end
        else begin
            case (1'b1)
            isLui, isAuipc : 
                o_IMM_VAL <= IMM_U;
            isStore : 
                o_IMM_VAL <= IMM_S;
            isJal, isJalr :
                o_IMM_VAL <= 32'd4;
            isEcall :
                o_IMM_VAL <= IMM_CSR;
            default : 
                o_IMM_VAL <= ( (funct3 == 3'h5) || (funct3 == 3'h1) )? IMM_SFT : IMM_R;
            endcase
        end
    end
end

endmodule