module Icache (
    input            wire               clk,
    input            wire               rstn,
    input            wire               r_req,
    input            wire               br,
    input            wire               mem_ready,
    input      wire     [31:0]          addr,
    input      wire     [31:0]          next_addr,
    input      wire     [31:0]          mem_r_data,
    output     wire     [31:0]          r_data,
    output      reg [31:0]          mem_addr,
    output        wire                  miss,
    output        reg                  r_mem
);
//用next_addr计算出tag_index和tag
wire    [9:0]    tag_index;
// reg     [9:0]    w_tag_index;
wire    [19:0]   tag;
assign  tag_index   =   next_addr[11:2];
assign  tag         =   next_addr[31:12];

// 读出tag里的数据，一位valid???20位tag
wire    [19:0]      r_tag_1;
wire    [19:0]      r_tag_2;
wire                valid_1;  
wire                valid_2;  
wire                 tag_we_1;
wire                 tag_we_2;
wire                 valid_w1;
wire                 valid_w2;
//a代表写，b代表读
cache_tag cache_tag_1(
    .clka (clk               ),
    .clkb (clk               ),
    .enb  (r_req             ),
    .ena  (r_req             ),
    .web(0),
    .wea  ( tag_we_1    ),
    .addrb(tag_index         ),
    .addra(addr_buf[11:2]),
    .dina ({valid_w1, addr_buf[31:12]}),
    .doutb({valid_1, r_tag_1})
);
cache_tag cache_tag_2(
    .clka (clk               ),
    .clkb (clk               ),
    .enb  (r_req             ),
    .ena  (r_req             ),
    .wea  (tag_we_2     ),
    .web  (0     ),
    .addrb(tag_index         ),
    .addra(addr_buf[11:2]),
    .dina ({valid_w2, addr_buf[31:12]}),
    .doutb({valid_2, r_tag_2})
);
wire [1:0 ] used;
wire [1:0] used_we;
wire [1:0] history;
history_bram used_1(
    .clka (clk               ),
    .clkb (clk               ),
    .ena  (r_req             ),
    .enb  (r_req             ),
    .wea  (used_we   ),
    .web  (0   ),
    .addrb(tag_index         ),
    .addra(addr_buf[11:2]         ),
    .dina (used),
    .dinb (),
    .doutb(history),
    .douta()
);
// history_bram used_2(
//     .clka (clk               ),
//     .clkb (clk               ),
//     .ena  (r_req             ),
//     .enb  (r_req             ),
//     .wea  (used_we[0]   ),
//     .web  (0   ),
//     .addrb(tag_index         ),
//     .addra(addr_buf[11:2]        ),
//     .dina (used[0]),
//     .dinb (),
//     .doutb(history[0]),
//     .douta()
// );
// 判断是否命中, hit[1] 表示cache_1, hit[0] 表示cache_2 
wire    [1:0]       hit;

assign  hit   =  {valid_1 && (r_tag_1 == tag), valid_2 && (r_tag_2 == tag)};
assign used[1] = (hit[1] && (cs == READ)) || (tag_we_1 &&(cs == MISS)) ? 1'b1 : 1'b0;
assign used[0] = (hit[0] && (cs == READ)) || (tag_we_2 &&(cs == MISS)) ? 1'b1 : 1'b0;
assign used_we[1] = used[1] || used[0];
assign used_we[0] = used[1] || used[0];
//设置状???机
localparam  IDLE = 2'b00;
localparam  READ = 2'b01;
localparam  MISS = 2'b10;
reg       [2:0]     cs;
reg       [2:0]     ns;
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        cs <= IDLE;
    end
    else begin
        cs <= ns;
    end
end
always @(*) begin
        case (cs)
        IDLE: begin
            if(r_req)
                ns = READ;
            else
                ns = IDLE; 
        end 
        READ: begin
            if(miss)
                ns = MISS;
            else if(r_req)
                ns = READ;
            else
                ns = IDLE;
        end
        MISS: begin
            if(br)
                ns = READ;
            else if(mem_ready)
                ns = IDLE;
            else
                ns = MISS;
        end
            default: ns = IDLE;
        endcase
end

// 处理信号
reg         valid_buf_1;
reg         valid_buf_2;

wire         ret_buf_we;  //返回值缓冲使???
reg [31:0]  ret_buf;
reg [31:0]  addr_buf;
wire         addr_buf_we; // 地址缓冲使能
wire         data_from_mem; //从内存读取数据，数据准备???
reg  refill;  //是否??????
assign miss = br ? 1'b0 : (cs == READ && hit == 2'b00) || (cs == MISS) ? 1'b1 : 1'b0;
assign addr_buf_we = (cs == READ && hit == 2'b00) ? 1'b1 : 1'b0;
always @(*) begin
    case (cs)
        IDLE: begin
            r_mem           =    1'b0;
        end 
        READ:begin
            if(hit[1] || hit[0])begin
                r_mem           =    1'b0;
            end
            else if(br)begin
                r_mem           =    1'b0;
            end
            else r_mem = 1'b1;
                
        end
        MISS:begin
            if(mem_ready || br) begin
                r_mem           =    1'b0;
            end
            else begin   
                r_mem           =    1'b1;       
            end
        end
        default: begin  
           r_mem = 1'b0;
        end 
    endcase
end
// assign mem_addr = addr;
always @(posedge clk) begin
    if(!rstn) begin
        mem_addr <= 32'd0;
    end
    else
        mem_addr <= addr;
end
assign data_from_mem = (cs == IDLE && refill) ? 1'b1 : 1'b0;
assign ret_buf_we = ((cs == MISS) && mem_ready) ? 1'b1 : 1'b0;
assign tag_we_1 = ((cs == MISS) && mem_ready) ? (valid_buf_1 ? (valid_buf_2 ? (history[1] ? 1'b0 : 1'b1) : 1'b0) : 1'b1) : 1'b0;
assign tag_we_2 = ((cs == MISS) && mem_ready) ? (valid_buf_1 ? (valid_buf_2 ? (history[1] ? 1'b1 : 1'b0) : 1'b1) : 1'b0) : 1'b0;
assign valid_w1 = 1'b1;
assign valid_w2 = valid_buf_1 ? 1'b1 : 1'b0;
// always @(*) begin
//     case (cs)
//         IDLE: begin
//             tag_we_1        =    1'b0;
//             tag_we_2        =    1'b0;
//             valid_w1        =    1'b0;
//             valid_w2        =    1'b0;
//         end 
//         READ: begin
//             tag_we_1        =    1'b0;
//             tag_we_2        =    1'b0;
//             valid_w1        =    1'b0;
//             valid_w2        =    1'b0;
//             ret_buf_we      =    1'b0;
//             ret_buf_we  = 1'b0;
//             // data_from_mem  =  1'b0;
//         end
//         MISS: begin
//             // data_from_mem   =    1'b0;
//              //MISS状???下要从内存读数???
//             if(mem_ready) begin
//                 // // ret_buf_we = 1'b1;
//                 // tag_we_1 = valid_buf_1 ? (valid_buf_2 ? (history[1] ? 1'b0 : 1'b1) : 1'b0) : 1'b1;
//                 // tag_we_2 = valid_buf_1 ? (valid_buf_2 ? (history[1] ? 1'b1 : 1'b0) : 1'b1) : 1'b0;
//                 valid_w1 = 1'b1;
//                 valid_w2 = valid_buf_1 ? 1'b1 : 1'b0;
//             end
//             else  begin
//                 tag_we_1        =    1'b0;
//                 tag_we_2        =    1'b0;
//                 valid_w1        =    1'b0;
//                 valid_w2        =    1'b0;
//                 // ret_buf_we  = 1'b0;
//             end
//         end
//         default: ;
//     endcase
// end


// reg [1023:0]   history;
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        refill      <= 1'b0;
        ret_buf     <= 32'd0;
        valid_buf_1 <= 1'b0;
        valid_buf_2 <= 1'b0;
        addr_buf    <= 32'd0;
    end
    else begin
        if(ret_buf_we) begin
            ret_buf <= mem_r_data;
        end
        if(cs == MISS && mem_ready) begin
            refill <= 1'b1;
        end
        if(cs == IDLE) begin
            refill <= 1'b0;
            valid_buf_1 <= valid_1;
            valid_buf_2 <= valid_2;
        end
        else if(cs == READ) begin
            valid_buf_1 <= valid_1;
            valid_buf_2 <= valid_2;
        end
        if(addr_buf_we) begin
            addr_buf <= addr;
        end
        
    end
end
//判断存哪???
// reg [1023:0]   history;
// initial begin
//     history = 1024'd0;
// end

// always @(posedge clk or negedge rstn) begin
//     if(!rstn)
//         history <= 1024'd0;
//     else if(cs == READ && hit)begin
//         if(hit[1])
//             history[addr[11:2]] <= 1'b1;
//         else
//             history[addr[11:2]] <= 1'b0; 
//     end
//     else if(cs == MISS && mem_ready) begin
//         history[addr_buf[11:2]] <= tag_we_1 ? 1'b1 : 1'b0;
//     end
// end
// assign tag_we_1 = valid_buf_1 ? (valid_buf_2 ? (history[tag_index_buf] ? 1'b0 : 1'b1) : 1'b0) : 1'b1;
// assign tag_we_2 = valid_buf_1 ? (valid_buf_2 ? (history[tag_index_buf] ? 1'b0 : 1'b1) : 1'b0) : 1'b1;
wire [31:0] cache_rdata_1 ;
wire [31:0] cache_rdata_2 ;
assign  r_data = data_from_mem ? ret_buf : 
                ((cs == READ) && hit[1]  ? cache_rdata_1: 
                (cs == READ) && hit[0] ? cache_rdata_2 : 32'd0);
// always @(*) begin
//     r_data = 32'd0;
//     if(cs == READ && hit) begin
//         if(hit[1])
//             r_data = cache_rdata_1;
//         else
//             r_data = cache_rdata_2;
//     end
//     else if(data_from_mem)begin
//         r_data = ret_buf;
//     end
//     else 
//         r_data = 32'd0;
// end
cache_data cache_data_1(
    .clka  (clk            ),   
    .clkb  (clk            ),   
    .ena   (r_req    ),
    .enb   (r_req    ),
    .wea   (tag_we_1     ),    
    .web   (0     ),    
    .addra (addr_buf[11:2]              ),   
    .addrb (tag_index               ),   
    .dina  (mem_r_data    ),   
    .dinb  (    ),   
    .douta (     )   , 
    .doutb (cache_rdata_1     )    
);
cache_data cache_data_2(
    .clka  (clk            ),   
    .clkb  (clk            ),   
    .ena   (  r_req     ),
    .enb   (  r_req     ),
    .wea   (  tag_we_2   ),   
    .web  ( 0   ),   
    .addra (addr_buf[11:2]             ),   
    .addrb (tag_index               ),   
    .dina  (  mem_r_data   ),   
    .dinb  (    ),   
    .douta (     )    ,
    .doutb (cache_rdata_2     )    
);
endmodule