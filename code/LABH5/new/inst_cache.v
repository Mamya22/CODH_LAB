module inst_cache (
    input               cpu_clk,
    input               rstn,
    input               r_req, // CPU读请求
    input   [31:0]      addr, // 要读的地址   
    output  [31:0]      r_data, // 读出的数据
    output    reg          miss,   // 数据是否缺失
    output     reg         r_mem,  // 内存读请求
    input    [31:0]     mem_r_data, // 内存读出的数据，用于写入cache，返回CPU 
    output  reg [31:0]     mem_addr, // 读内存的地址
    input               mem_ready  // 用于判断内存是否已经被读出
);
reg         reset;
always @(posedge cpu_clk) reset <= ~rstn;
// 设置读cache的index和理论tag
wire    [9:0]       tag_index;  //CPU要读的index
assign  tag_index  =  addr[11:2];
reg [1023:0] history ;
wire    [19:0]      tag;
assign  tag          =  addr[31:12];
// 读取tag
wire    [19:0]      r_tag_1;
wire    [19:0]      r_tag_2;
wire                valid_1; //标记该地址是否有效
wire                valid_2;
wire                used_1;  //标记该地址是否被写入过
wire                used_2;
reg tag_we_1;
reg tag_we_2;
reg [31:0] addr_buf;   //地址缓冲区
reg [31:0] ret_buf;     // 返回数据缓冲
reg        ret_buf_we;  // 内存返回使能
reg [1:0]  tag_buf_we;   // tag写入信号缓存
reg        addr_buf_we;
reg [1:0] valid;
reg [1:0] used;
cache_tag_1 cache_tag_1(
    .clka  (  cpu_clk                 ),   
    .ena   (  1'b1               ),
    .wea   (  {4{tag_we_1}}             ),   
    .addra (  tag_index               ),   
    .dina  ( {valid[1], used[1], ret_buf[31:12]}                ),   
    .douta ({valid_1, used_1, r_tag_1})    
);
cache_tag_2 cache_tag_2(
    .clka  (    cpu_clk               ),   
    .ena   (    1'b1             ),
    .wea   (    {4{tag_we_2}}           ),   
    .addra (    tag_index             ),   
    .dina  ({valid[0],used[0],ret_buf[31:12]}                          ),   
    .douta ({valid_2, used_2, r_tag_2})    
);

// 判断是否命中
wire  [1:0]      hit; // 判断是否有相应地址
assign   hit  = {valid_1 && (r_tag_1 == tag), valid_2 && (r_tag_2 == tag)};
always @(posedge cpu_clk) begin
    if(hit[1])
        history[tag_index] <= 1'b1;
    else if(hit[0])
        history[tag_index] <= 1'b0;
end
// 如果命中则选择，未命中则从内存中读取
reg     data_from_mem;
wire [31:0] cache_rdata_1 ;
wire [31:0] cache_rdata_2 ;
assign  r_data = data_from_mem ? mem_r_data : 
                (hit[1]  ? cache_rdata_1 : cache_rdata_2);
//状态机设置
parameter IDLE = 2'b00;  //空闲状态
parameter READ = 2'b01;  //读状态
parameter MISS = 2'b10;  //未命中
reg [2:0] CS;
reg [2:0] NS;
always @(posedge cpu_clk ) begin
    if(reset) begin
        CS <= IDLE;
    end 
    else 
        CS <= NS;
    if(CS == MISS && miss == 0)begin
        history[tag_index] <= ~history[tag_index];
    end
end
//状态转变
always @(*) begin
    case (CS)
        IDLE: begin
            if(r_req)        NS = READ;
            else             NS = IDLE;
        end 
        READ: begin
            if(miss)         NS = MISS;
            else if(r_req)   NS = READ;
            else             NS = IDLE;
        end
        MISS: begin
            if(mem_ready)   NS = IDLE;
            else            NS = MISS;
        end
        default: NS = IDLE;
    endcase
end

// 处理各种信号

// reg [31:0] addr_buf;   //地址缓冲区
// reg [31:0] ret_buf;     // 返回数据缓冲
// reg        ret_buf_we;  // 内存返回使能
// reg [1:0]  tag_buf_we;   // tag写入信号缓存
// reg        addr_buf_we;
// reg [1:0] valid;
// reg [1:0] used;
// assign valid = (CS == MISS) ? 
reg       refill; //是否需要填充
always @(*) begin
    r_mem = 0;
    mem_addr = 0;
    ret_buf_we  = 1'b0;
    addr_buf_we = 1'b0; 
    miss        = 1'b0;
    tag_buf_we = 0;
    tag_we_1 = 0;
    tag_we_2 = 0;
    case (CS)
        IDLE: begin
            addr_buf_we = 1'b1; //初始不需要缓冲内存
            miss        = 1'b0;
            ret_buf_we  = 1'b0; //从内存缓冲信号为0
            if(refill) begin
                // data_from_mem = 1'b1;
                {tag_we_1, tag_we_2} = tag_buf_we;
            end
        end 
        READ: begin
            data_from_mem = 1'b0; //默认不需要从内存读
            if(hit) begin
                miss = 1'b0; //不缺失
                addr_buf_we = 1'b0; //不需要缓存地址
            end
            else begin
                miss = 1'b1;
                addr_buf_we = 1'b1;
            end
        end
        MISS: begin
            // addr_buf_we = 1'b0;
            miss = 1'b1;
            r_mem = 1'b1;
            mem_addr = addr_buf;
            if(mem_ready) begin  //此时内存准备好了
                ret_buf_we = 1'b1; //下个周期为IDLE， 方便写入
                r_mem = 1'b0;
                // miss = 1'b0;
                data_from_mem = 1'b1;
            end
            // 判断写入tag的路数
            if(miss) begin
            if(!valid_1 ) begin
                tag_buf_we = 2'b10;       
                valid = 2'b10;    
                used = 2'b00;     
            end
            else if(!valid_2) begin
                tag_buf_we = 2'b01;
                valid = 2'b11;
                used = 2'b00;
            end
            else begin
                if(history[tag_index])
                    tag_buf_we = 2'b01;
                else
                    tag_buf_we = 2'b10;                
            end    
        end
        else ;
        end
        default: ;
    endcase
end
always @(posedge cpu_clk  ) begin
    if(reset) begin
        refill <= 1'b0;
        addr_buf <= 32'd0;
        ret_buf <= 32'd0;
    end
    else begin
        if(addr_buf_we) begin
            addr_buf <= addr;
        end
        if(ret_buf_we) begin
            ret_buf <= mem_r_data;
        end
        if((CS == MISS) && mem_ready) begin
            refill <= 1'b1; //说明可以填充数据了
            // {tag_we_1, tag_we_2} <= tag_buf_we;
        end
        if(CS == IDLE) begin
            refill <= 1'b0; //数据写入
        end
    end

end
cache_data_1 cache_data_1(
    .clka  (cpu_clk            ),   
    .ena   (  1'b1     ),
    .wea   (  {4{tag_we_1}}      ),    
    .addra (tag_index               ),   
    .dina  (ret_buf    ),   
    .douta (cache_rdata_1     )    
);
cache_data_2 cache_data_2(
    .clka  (cpu_clk            ),   
    .ena   (  1'b1     ),
    .wea   (  {4{tag_we_2}}     ),   
    .addra (tag_index               ),   
    .dina  (  ret_buf   ),   
    .douta (cache_rdata_2     )    
);
endmodule