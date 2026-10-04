localparam [31:0] AXILT_DATA_WIDTH = 32'd32;
localparam [31:0] AXILT_STRB_WIDTH = AXILT_DATA_WIDTH / 32'd8;
localparam [31:0] AXILT_ADDR_WIDTH = 32'd32;

localparam [1:0] AXI_OKAY   = 2'b00;
localparam [1:0] AXI_SLVERR = 2'b10;
localparam [1:0] AXI_DECERR = 2'b11;
