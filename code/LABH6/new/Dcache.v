module Dcache(
    input   wire          clk,
    input   wire          rstn,
    input   wire          r_req,  //读数据请求
    input   wire          w_req,  //写数据请求
    input   wire [31:0]   w_data, //要写入的数据，CPU传来
    input   wire [31:0]   addr,   //要写入或者读取的地址，CPU传来
    output  reg [31:0]   mem_addr, //要读或者写的地址， 传入mem
    input   wire [31:0]   mem_data, //读出的数据  mem传来
    output  reg [31:0]   dirty_mem,
    output  wire [31:0]   r_data,  //读出的数据， 传入CPU
    input   wire          mem_ready,
    output  reg          mem_w, //要写入数据
    output  wire          mem_r, //读内存请求
    output   reg            miss   //  是否缺失
);
parameter IDLE       =      3'd0;
parameter READ       =      3'd1;
parameter WRITE      =      3'd2;
parameter MISS       =      3'd3;
parameter W_DIRTY    =      3'd4;

/*
    读取tag判断是否命中
*/
reg [1:0] used_buf;
reg [1:0] dirty_buf;
reg refill;
reg we_op;
reg w_valid_1;
reg w_valid_2;
reg w_dirty_1;
reg w_dirty_2;
reg [31:0] addr_buf;
wire [19:0]  tag;
wire [9 :0] r_index;
wire [9 :0] w_index;
wire valid_1, valid_2;
wire dirty_1, dirty_2;
wire [19:0] r_tag_1;
wire [19:0] r_tag_2;
assign w_index = addr_buf[11:2];
assign r_index = addr[11:2];
assign tag       = addr_buf[31:12];
reg [1:0] used_update; //更新后的used
reg [31:0]  dirty_mem_addr_buf;
reg [31:0]  dirty_mem_data_buf;
reg tag_we_1;
reg tag_we_2;
wire used_we;
reg [31:0] wb_data; 
Dcache_tag cache_tag_1(
    .clka (clk),
    .ena  (1'b1),
    .wea  (tag_we_1),
    .addra(w_index),
    .dina ({w_valid_1, w_dirty_1, tag}),
    .doutb({valid_1, dirty_1, r_tag_1}),
    .clkb (clk),
    .enb  (1'b1),
    .web  (1'b0),
    .addrb(r_index),
    .dinb (),
    .douta()
);
Dcache_tag cache_tag_2(
    .clka (clk),
    .ena  (1'b1),
    .wea  (tag_we_2),
    .addra(w_index),
    .dina ({w_valid_2 , w_dirty_2, tag}),
    .doutb({valid_2, dirty_2, r_tag_2}),
    .clkb (clk),
    .enb  (1'b1),
    .web  (1'b0),
    .addrb(r_index),
    .dinb (),
    .douta()
);
wire [1:0] used;
history_bram lru(
    .clka (clk),
    .ena  (1'b1),
    .wea  (1'b0),
    .addra(r_index),
    .dina (),
    .douta(used),
    .clkb (clk),
    .enb  (1'b1),
    .web  (used_we),
    .addrb(w_index),
    .dinb (used_update),
    .doutb()
);
// 使用valid表示是否被使用过，表示LRU策略，初始时cache都为0
// 当valid || dirty时表示有效
wire [1:0] hit;
assign  hit   =  {(dirty_1 || valid_1) && (r_tag_1 == tag), (dirty_2 || valid_2) && (r_tag_2 == tag)};

/*
    判断状态机
    初始状态为IDLE，当读请求时到READ， 写请求到WRITE
    对于READ和WRITE需要先判断未hit时是否dirty，dirty需要先写回，即到W_DIRTY状态
*/
reg [1:0] cs;
reg [1:0] ns;
always @(posedge clk or negedge rstn) begin
    if(!rstn)
        cs <= IDLE;
    else
        cs <= ns;
end
always @(*) begin
    case (cs)
        IDLE: begin
            if(r_req) begin
                ns = READ;
            end
            else if(w_req) begin
                ns = WRITE;
            end
            else begin
                ns = IDLE;
            end
        end
        READ: begin
            // miss 且根据LRU策略需要写回的不dirty
            if(miss && ((!dirty_1 && !dirty_2) || (used[1] && !dirty_2) || (used[0] && !dirty_1))) begin
                ns = MISS;
            end
            // miss且根据LRU策略需要写回
            else if(miss && ((dirty_1 && used[2]) || (dirty_2 && used[1])))
                ns = W_DIRTY; //需要写回脏数据
            else if(r_req) begin
                ns = READ;
            end
            else if(w_req) begin
                ns = WRITE;
            end
            else begin
                ns = IDLE;
            end
        end
        MISS:begin
            if(mem_ready) begin
                ns = IDLE;
            end
            else begin
                ns = MISS;
            end
        end
        WRITE: begin
            // if(miss && ((!dirty_1 && !dirty_2) || (used[1] && !dirty_2) || (used[0] && !dirty_1))) begin
            //     ns = ;  //MISS 且不需要写回
            //     // ns = IDLE;
            // end
            if(miss && ((dirty_1 && used[2]) || (dirty_2 && used[1]))) begin
                ns = W_DIRTY;
            end
            else if(r_req) begin
                ns = READ;
            end
            else if(w_req) begin
                ns = WRITE;
            end
            else begin
                ns = IDLE;
            end
        end
        W_DIRTY: begin
            if (mem_ready && !we_op) begin
                // ns = MISS; // 写回后转到miss
                ns = MISS;
            end
            else if(mem_ready && we_op) begin
                ns = IDLE;
            end
            else begin
                ns = W_DIRTY;
            end
        end
        default: ns  = IDLE;
    endcase
end

/*
    各种信号
*/

wire data_from_mem;
wire addr_buf_we;
wire ret_buf_we;
wire [31:0] dirty_addr ;
wire [31:0] cache_rdata_1;
wire [31:0] cache_rdata_2;
// reg cache_we_1;
// reg cache_we_2;
// dirty_buf记录dirty值
// used_buf记录used值
assign dirty_addr = {used[1] ? r_tag_2 : r_tag_1, w_index, 2'b00};
assign addr_buf_we = (cs == IDLE || (cs == READ && hit) || (cs == WRITE && hit)) ? 1'b1: 1'b0;
assign ret_buf_we = (cs == MISS && mem_ready) ? 1'b1 : 1'b0;
assign data_from_mem = (cs == IDLE && refill) ? 1'b1 : 1'b0;
assign used_we = (cs == IDLE && refill) || ((cs == READ || cs == WRITE) && hit) ? 1'b1 : 1'b0;
assign mem_r = (cs == MISS && !mem_ready) ? 1'b1 : 1'b0;
// assign miss = (((cs == READ || cs == WRITE) && !hit[1] && !hit[0]) || (cs == MISS) || (cs == W_DIRTY)) ? 1'b1 : 1'b0;
always @(*) begin
    tag_we_1 = 1'b0;
    tag_we_2 = 1'b0;
    w_dirty_1 = 1'b0;
    w_dirty_2 = 1'b0;
    w_valid_1   = 1'b0; 
    w_valid_2   = 1'b0;
    used_update = 2'b00;
    mem_w = 1'b0;
    dirty_mem   = 32'd0;
    mem_addr = 32'd0;
    case (cs)
        IDLE: begin
            miss        = 1'b0;
            if(refill) begin  //需要将读出的数据写回或者传给CPU
                if(used_buf[1]) begin //表示要写入第二个
                    tag_we_2    = 1'b1;
                    tag_we_1    = 1'b0;
                    w_valid_1   = 1'b1;
                    w_valid_2   = 1'b1;
                    used_update = 2'b01;
                end
                else if(used_buf[0]) begin
                    tag_we_1    = 1'b1;
                    tag_we_2    = 1'b0;
                    w_valid_1   = 1'b1; 
                    w_valid_2   = 1'b0; 
                    used_update = 2'b10;
                end
                else begin //最初时
                    tag_we_1    = 1'b1;
                    tag_we_2    = 1'b0;
                    w_valid_1   = 1'b1;
                    w_valid_2   = 1'b0;
                    used_update = 2'b10;
                end
                 //表示从cpu写回数据
                if(we_op && used_buf[1]) begin //写第二块
                    w_dirty_1  = dirty_buf[1];
                    w_dirty_2  = 1'b1;

                end
                else if(we_op && used_buf[0]) begin
                    w_dirty_1  = 1'b1;
                    w_dirty_2 = dirty_buf[0];
                end
                else if(we_op && !used_buf[1] && !used_buf[0]) begin
                    w_dirty_1 = 1'b1;
                    w_dirty_2 = 1'b0;
                end
                else begin
                    w_dirty_1 = 1'b0;
                    w_dirty_2 = 1'b0;
                end               
            end
        end 
        READ: begin
            if(hit) begin
                miss = 1'b0;
                if(hit[1]) begin
                    used_update = 2'b10;
                end
                else begin
                    used_update = 2'b01;
                end
            end
            else begin  //未命中

                miss = 1'b1;
                // addr_buf_we = 1'b0;
                //未命中但是有脏数据，则需要写回
                if(((dirty_1 && used[2]) || (dirty_2 && used[1]))) begin
                    mem_w = 1'b1;
                    mem_addr = dirty_addr;
                    //used这些都是该周期读出的
                    dirty_mem = (dirty_1 && used[2]) ? cache_rdata_1 : cache_rdata_2;
                end
            end
        end 
        MISS: begin
            miss = 1'b1;
            mem_addr = addr_buf;
        end                
        WRITE: begin
           
            if (hit) begin // 命中
                miss = 1'b0;
                // addr_buf_we = 1'b1; // 请求地址缓存写使能
                // used_we = 1'b1;
                 mem_w   = 1'b0;
                if(hit[1]) begin
                    w_valid_1 = 1'b1;
                    w_valid_2 = valid_2;
                    w_dirty_1 = 1'b1;
                    w_dirty_2 = dirty_2;
                    used_update = 2'b10;
                    tag_we_1 = 1'b1;
                    tag_we_2 = 1'b0;
                end
                else if(hit[0]) begin
                    w_valid_1 = 1'b1;
                    w_valid_2 = valid_2;
                    w_dirty_2 = 1'b1;
                    w_dirty_1 = dirty_1;
                    tag_we_2 = 1'b1;
                    tag_we_1 = 1'b0;
                    used_update = 2'b01;
                end
            end else begin // 未命中
                miss = 1'b1;
                // addr_buf_we = 1'b0; 
                if(((dirty_1 && used[2]) || (dirty_2 && used[1]))) begin
                    mem_w = 1'b1;
                    mem_addr = dirty_addr;
                    //used这些都是该周期读出的
                    dirty_mem = (dirty_1 && used[2]) ? cache_rdata_1 : cache_rdata_2;
                end
                else begin
                    if(used[1]) begin
                        tag_we_2 = 1'b1;
                        tag_we_1 = 1'b0;
                        used_update = 2'b01;
                        w_dirty_2 = 1'b1;
                        w_dirty_1 = 1'b0;
                        w_valid_1 = 1'b1;
                        w_valid_2 = 1'b1;
                    end
                    else if(used[0]) begin
                        tag_we_2 = 1'b0;
                        tag_we_1 = 1'b1;
                        used_update = 2'b10;
                        w_dirty_2 = 1'b0;
                        w_dirty_1 = 1'b1;
                        w_valid_1 = 1'b1;
                        w_valid_2 = 1'b1;                        
                    end
                    else begin
                        tag_we_2 = 1'b0;
                        tag_we_1 = 1'b1;
                        used_update = 2'b10;
                        w_dirty_2 = 1'b0;
                        w_dirty_1 = 1'b1;
                        w_valid_1 = 1'b1;
                        w_valid_2 = 1'b0;
                    end
                end
            end
        end
        W_DIRTY: begin
            // addr_buf_we = 1'b0;
            miss = 1'b1;
            mem_w = 1'b1;
            mem_addr = dirty_mem_addr_buf;
            dirty_mem = dirty_mem_data_buf;
            if (mem_ready) begin
                mem_w = 1'b0;
            end
        end
        default:;
    endcase
end
reg [31:0] ret_buf;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        addr_buf <= 0;
        ret_buf <= 0;
        // w_data_buf <= 0;
        wb_data <= 32'd0;
        we_op <= 0;
        refill <= 0;
    end else begin
        if (addr_buf_we) begin
            wb_data <= w_data;
            addr_buf <= addr;
            we_op <= w_req;
            dirty_mem_addr_buf <= dirty_addr;
            used_buf <= used;
            dirty_buf <= {dirty_1, dirty_2};
        end
        if(cs == READ) begin
            dirty_mem_data_buf <= (dirty_1 && used[2]) ? cache_rdata_1 : cache_rdata_2; 
        end
        if (ret_buf_we) begin
            ret_buf <= mem_data;
        end
        if (cs == MISS && mem_ready) begin
            refill <= 1;
        end
        if(cs == W_DIRTY && we_op && mem_ready) begin
            refill <= 1;
        end
        if (cs == IDLE) begin
            refill <= 0;
        end
    end
end
wire [31:0] true_data;
assign true_data = we_op ? w_data : (data_from_mem ? ret_buf : 
                    ((cs == READ) && hit[1]  ? cache_rdata_1: 
                    (cs == READ) && hit[0] ? cache_rdata_2 : 32'd0));
assign r_data = data_from_mem ? ret_buf : 
((cs == READ) && hit[1]  ? cache_rdata_1: 
(cs == READ) && hit[0] ? cache_rdata_2 : 32'd0);
cache_data cache_data_1(
    .clka (clk),
    .ena  (1'b1),
    .wea  (tag_we_1),
    .addra(w_index),
    .dina (true_data),
    .douta(),
    .clkb (clk),
    .enb  (1'b1),
    .web  (1'b0),
    .addrb(r_index),
    .dinb (),
    .doutb(cache_rdata_1)
);
cache_data cache_data_2(
    .clka (clk),
    .ena  (1'b1),
    .wea  (tag_we_2),
    .addra(w_index),
    .dina (true_data),
    .douta(),
    .clkb (clk),
    .enb  (1'b1),
    .web  (1'b0),
    .addrb(r_index),
    .dinb (),
    .doutb(cache_rdata_2) 
);
endmodule