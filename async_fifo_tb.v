module tb_async_fifo;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;

    reg wr_clk;
    reg rd_clk;
    reg rst_n;

    reg [DATA_WIDTH-1:0] wr_data;
    reg                  wr_en;
    reg                  rd_en;

    wire [DATA_WIDTH-1:0] rd_data;
    wire                  full;
    wire                  empty;

    //DUT
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk  (wr_clk),
        .rd_clk  (rd_clk),
        .rst_n   (rst_n),

        .wr_data (wr_data),
        .wr_en   (wr_en),
        .full    (full),

        .rd_data (rd_data),
        .rd_en   (rd_en),
        .empty   (empty)
    );

    //Write clock = 10 ns
    initial begin
        wr_clk = 1'b0;

        forever #5 wr_clk = ~wr_clk;
    end

    //Read clock = 14 ns
    initial begin
        rd_clk = 1'b0;

        forever #7 rd_clk = ~rd_clk;
    end

    //Reset
    initial begin

        rst_n   = 1'b0;
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        wr_data = 8'h00;

        #30;

        rst_n = 1'b1;

    end

    //Write data
    integer i;

    initial begin

        wait(rst_n);

        for (i = 0; i < 20; i = i + 1) begin

            @(posedge wr_clk);

            if (!full) begin
                wr_en   <= 1'b1;
                wr_data <= i;
            end
            else begin
                wr_en <= 1'b0;
            end

        end

        @(posedge wr_clk);
        wr_en <= 1'b0;

    end

    //Read data
    initial begin

        wait(rst_n);

        #100;

        for (i = 0; i < 20; i = i + 1) begin

            @(posedge rd_clk);

            if (!empty)
                rd_en <= 1'b1;
            else
                rd_en <= 1'b0;

        end

        @(posedge rd_clk);
        rd_en <= 1'b0;

    end

    //Monitor
    initial begin

        $monitor("TIME=%0t WR_EN=%b WR_DATA=%h FULL=%b RD_EN=%b RD_DATA=%h EMPTY=%b",
                 $time,
                 wr_en,
                 wr_data,
                 full,
                 rd_en,
                 rd_data,
                 empty);

    end

    //Finish
    initial begin

        #500;

        $finish;

    end

endmodule