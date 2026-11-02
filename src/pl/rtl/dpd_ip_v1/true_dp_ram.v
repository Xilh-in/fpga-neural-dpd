module true_dp_ram
    #(parameter PW_DATA = 32,                  // 数据宽度
      parameter PN_DEPTH = 2048,                // 存储深度
      parameter PW_ADDR = $clog2(PN_DEPTH)     // 地址宽度（自动计算，基于深度�?
    )(
    // A port
    input                               clk_a                     ,// 写时�?
    input                               ena                        ,// 启用信号
    input                               wea                        ,// 写使能信号（1 写，0 读）
    input              [PW_DATA-1: 0]   dina                       ,// 写入数据
    input              [PW_ADDR-1: 0]   addra                      ,// 写入地址
    output reg         [PW_DATA-1: 0]   douta                      ,// 读出数据


    // B port
    input                               clk_b                     ,// 读时�?
    input                               rd_en                      ,// 读使能信�?
    input              [PW_ADDR-1: 0]   addrb                      ,// 读地址
    output reg         [PW_DATA-1: 0]   doutb                       // 读出数据
    );

    // 内存数组，模拟存储器
    (*ram_style="block"*) reg [PW_DATA-1:0] data_mem [0:PN_DEPTH-1];

    // 写操作：在写时钟上升沿进�?
    always @(posedge clk_a) begin
        if (ena) begin
            if (wea == 1'b1) begin
                data_mem[addra] <= dina;  // 写入数据到指定地址
            end
            else begin
                douta <= data_mem[addra];
            end
        end
    end

    // 读操作：在读时钟上升沿进�?
    always @(posedge clk_b) begin
        if (rd_en) begin
            doutb <= data_mem[addrb];  // 从指定地址读取数据
        end
    end

endmodule
