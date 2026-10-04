module core #( 
    parameter [31:0] HART_ID    = 32'h00000000
) (
    input   wire        i_CLK,
    input   wire        i_RSTn,
    
    input   wire [31:0] i_INSTRUCTION,
    output  wire [31:0] o_PC,

    input   wire        i_MEI_0,
    input   wire        i_MEI_1,
    input   wire        i_MEI_2,
    input   wire        i_MEI_3,
    input   wire        i_MEI_4,
    input   wire        i_MEI_5,

    output  wire [31:0] o_AWADDR,
    output  wire        o_AWVALID,
    input   wire        i_AWREADY,

    output  wire [31:0] o_WDATA,
    output  wire [3:0]  o_WSTRB,
    output  wire        o_WVALID,
    input   wire        i_WREADY,

    input   wire [1:0]  i_BRESP,
    output  wire        o_BREADY,
    input   wire        i_BVALID,

    output  wire [31:0] o_ARADDR,
    output  wire        o_ARVALID,
    input   wire        i_ARREADY,

    input   wire [31:0] i_RDATA,
    input   wire [1:0]  i_RRESP,
    input   wire        i_RVALID,
    output  wire        o_RREADY
);

`include "core.vh"

/*------------------------------------ CONTROL UNIT ---------------------------------------*/
wire [7:0]  coreState;

/*---------------------------------- INSTRUCTION FETCH ------------------------------------*/
wire instruction_valid = 1'b1;
wire [31:0] instruction = i_INSTRUCTION;
wire [31:0] pc;

/*------------------------------ DECODE - EXECUTE STAGE -----------------------------------*/
wire [31:0] decode_execute_pc;
wire [31:0] decode_execute_instruction;

wire [31:0] decode_execute_rs1;
wire [31:0] decode_execute_rs2;
wire [31:0] decode_execute_imm_val;
wire [4:0]  decode_execute_rd_ptr;

wire [2:0]  decode_execute_funct3;
wire [6:0]  decode_execute_funct7;

wire [1:0]  decode_execute_alu_op;
wire        decode_execute_reg_we;
wire        decode_execute_mem_we;
wire        decode_execute_mem_re;
wire        decode_execute_ecall;
wire        decode_execute_imm;
wire        decode_execute_jal;
wire        decode_execute_lui;
wire        decode_execute_auipc;

/*------------------------ EXECUTE - WRITEBACK - DECODE STAGE -----------------------------*/
wire [31:0] rd;
wire [4:0]  rd_ptr;
wire        reg_we;

/*---------------------------- CONTROL STATUS REGISTERS -----------------------------------*/
wire        csr_irq;
wire [31:0] csr_mtvec;
wire [31:0] csr_mepc;

/*------------------------------------ DECODE ---------------------------------------------*/
wire en_decode = ~( (lsu_req) & (~lsu_gnt) );
wire en_execute = 1'b1;

decode #(.HART_ID(HART_ID)) decodeUnit (
    .i_CLK(i_CLK),
    .i_RSTn(i_RSTn),

    .i_EN(en_decode),

    .i_IRQ(csr_irq),
    .o_CORE_STATE(coreState),

    .i_INSTRUCTION_VALID(instruction_valid),
    .i_INSTRUCTION(instruction),
    .i_MTVEC(csr_mtvec),
    .i_MEPC(csr_mepc),

    .i_RD(rd),
    .i_RD_PTR(rd_ptr),
    .i_REG_WE(reg_we),
    
    .o_FUNCT3(decode_execute_funct3),
    .o_FUNCT7(decode_execute_funct7),
    .o_RD_PTR(decode_execute_rd_ptr),
    
    .o_RS1(decode_execute_rs1),
    .o_RS2(decode_execute_rs2),
    .o_IMM_VAL(decode_execute_imm_val),

    .o_ALU_OP(decode_execute_alu_op),
    .o_REG_WE(decode_execute_reg_we),
    .o_MEM_WE(decode_execute_mem_we),
    .o_MEM_RE(decode_execute_mem_re),
    .o_ECALL(decode_execute_ecall),
    .o_IMM(decode_execute_imm),
    .o_JAL(decode_execute_jal),
    .o_LUI(decode_execute_lui),
    .o_AUIPC(decode_execute_auipc),
        
    .o_PC(pc),
    .o_PC_PIPELINE(decode_execute_pc),
    .o_INSTRUCTION(decode_execute_instruction)
);

/*-----------------------------------------------------------------------------------------*/

/*------------------------------------ EXECUTE --------------------------------------------*/

wire [31:0] lsu_rdata;
wire [31:0] lsu_wdata;
wire [31:0] lsu_addr;
wire lsu_we;
wire [1:0] lsu_byte_en;
wire lsu_req;
wire lsu_gnt;

execute #(.HART_ID(HART_ID)) executeUnit (
    .i_CLK(i_CLK),
    .i_RSTn(i_RSTn),

    .i_EN(~stall_execute),

    .i_CORE_STATE(coreState),

    .i_PC(decode_execute_pc),
    .i_INSTRUCTION(decode_execute_instruction),

    .i_FUNCT3(decode_execute_funct3),
    .i_FUNCT7(decode_execute_funct7),
    
    .i_RD_PTR(decode_execute_rd_ptr),
    .i_RS1(decode_execute_rs1),
    .i_RS2(decode_execute_rs2),
    .i_IMM_VAL(decode_execute_imm_val),
    
    /* CTRL */
    .i_ALU_OP(decode_execute_alu_op),
    .i_REG_WE(decode_execute_reg_we),
    .i_MEM_WE(decode_execute_mem_we),
    .i_MEM_RE(decode_execute_mem_re),
    .i_ECALL(decode_execute_ecall),
    .i_IMM(decode_execute_imm),
    .i_JAL(decode_execute_jal),
    .i_LUI(decode_execute_lui),
    .i_AUIPC(decode_execute_auipc),

    /* WRITEBACK */
    .o_RD(rd),
    .o_RD_PTR(rd_ptr),
    .o_REG_WE(reg_we),

    /* BUS */
    .i_LSU_RDATA(lsu_rdata),
    .o_LSU_WDATA(lsu_wdata), 
    .o_LSU_ADDR(lsu_addr),
    .o_LSU_WE(lsu_we),
    .o_LSU_HB(lsu_byte_en),
    .o_LSU_REQ(lsu_req),
    .i_LSU_GNT(lsu_gnt),

    /* EXTERNAL INTERRUPTS */
    .i_MEI_0(i_MEI_0),
    .i_MEI_1(i_MEI_1),
    .i_MEI_2(i_MEI_2),
    .i_MEI_3(i_MEI_3),
    .i_MEI_4(i_MEI_4),
    .i_MEI_5(i_MEI_5),

    /* IRQ */
    .o_CSR_IRQ(csr_irq),
    /* TRAP HANDLER BASE ADDRESS */
    .o_CSR_MTVEC(csr_mtvec),
    /* TRAP RETURN ADDRESS */
    .o_CSR_MEPC(csr_mepc)
);

/*----------------------------- AXI-LITE MASTER INTERFACE ----------------------------------*/

axilt_master #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32)
) axilt_m (
    .i_RST(~i_RSTn),
    .i_CLK(i_CLK),

    .o_AWADDR(o_AWADDR),
    .o_AWVALID(o_AWVALID),
    .i_AWREADY(i_AWREADY),

    .o_WDATA(o_WDATA),
    .o_WSTRB(o_WSTRB),
    .o_WVALID(o_WVALID),
    .i_WREADY(i_WREADY),

    .i_BRESP(i_BRESP),
    .o_BREADY(o_BREADY),
    .i_BVALID(i_BVALID),

    .o_ARADDR(o_ARADDR),
    .o_ARVALID(o_ARVALID),
    .i_ARREADY(i_ARREADY),

    .i_RDATA(i_RDATA),
    .i_RRESP(i_RRESP),
    .i_RVALID(i_RVALID),
    .o_RREADY(o_RREADY),

    .i_LSU_REQ(lsu_req),
    .i_LSU_ADDR(lsu_addr),
    .i_LSU_DATA(lsu_wdata),
    .i_LSU_WE(lsu_we),
    .i_LSU_HB(lsu_byte_en),
    .o_LSU_DATA(lsu_rdata),
    .o_LSU_GNT(lsu_gnt)
);

/*-----------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*/
assign o_PC = pc;

endmodule