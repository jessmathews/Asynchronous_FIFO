module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                  wr_clk,
    input  wire                  rd_clk,
    input  wire                  rst_n,

    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire                  wr_en,
    output wire                  full,

    output wire [DATA_WIDTH-1:0] rd_data,
    input  wire                  rd_en,
    output wire                  empty
);

    localparam DEPTH = (1 << ADDR_WIDTH);

    //memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    //Binary and Gray pointers
    //Extra bit is used for full/empty detection
    reg [ADDR_WIDTH:0] wr_ptr_bin;
    reg [ADDR_WIDTH:0] wr_ptr_gray;

    reg [ADDR_WIDTH:0] rd_ptr_bin;
    reg [ADDR_WIDTH:0] rd_ptr_gray;

    //synchronized pointers
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync2;

    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync2;

    //Next pointer values
    wire [ADDR_WIDTH:0] wr_ptr_bin_next;
    wire [ADDR_WIDTH:0] wr_ptr_gray_next;

    wire [ADDR_WIDTH:0] rd_ptr_bin_next;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next;

    //Write pointer increment
    assign wr_ptr_bin_next =
                    wr_ptr_bin + ((wr_en && !full) ? 1'b1 : 1'b0);

    assign wr_ptr_gray_next =
                    (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;

    //Read pointer increment
    assign rd_ptr_bin_next =
                    rd_ptr_bin + ((rd_en && !empty) ? 1'b1 : 1'b0);

    assign rd_ptr_gray_next =
                    (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

    //Full detection
    assign full =
        (wr_ptr_gray_next ==
         {
            ~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
             rd_ptr_gray_sync2[ADDR_WIDTH-2:0]
         });

    //Empty detection
    assign empty =
        (rd_ptr_gray_next == wr_ptr_gray_sync2);

    //Write pointer + memory write
    always @(posedge wr_clk or negedge rst_n) begin

        if (!rst_n) begin
            wr_ptr_bin  <= {(ADDR_WIDTH+1){1'b0}};
            wr_ptr_gray <= {(ADDR_WIDTH+1){1'b0}};
        end
        else begin

            if (wr_en && !full)
                mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;

            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;

        end
    end

    //Read pointer
    reg [DATA_WIDTH-1:0] rd_data_reg;

    assign rd_data = rd_data_reg;

    always @(posedge rd_clk or negedge rst_n) begin

        if (!rst_n) begin
            rd_ptr_bin  <= {(ADDR_WIDTH+1){1'b0}};
            rd_ptr_gray <= {(ADDR_WIDTH+1){1'b0}};
            rd_data_reg <= {DATA_WIDTH{1'b0}};
        end
        else begin

            if (rd_en && !empty)
                rd_data_reg <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];

            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;

        end
    end

    //Synchronize read pointer into write clock domain
    always @(posedge wr_clk or negedge rst_n) begin

        if (!rst_n) begin
            rd_ptr_gray_sync1 <= {(ADDR_WIDTH+1){1'b0}};
            rd_ptr_gray_sync2 <= {(ADDR_WIDTH+1){1'b0}};
        end
        else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end

    end

    //Synchronize write pointer into read clock domain
    always @(posedge rd_clk or negedge rst_n) begin

        if (!rst_n) begin
            wr_ptr_gray_sync1 <= {(ADDR_WIDTH+1){1'b0}};
            wr_ptr_gray_sync2 <= {(ADDR_WIDTH+1){1'b0}};
        end
        else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end

    end
    
endmodule