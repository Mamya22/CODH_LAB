module Dcache(
    input   wire          clk,
    input   wire          rstn,
    input   wire          r_req,  //����������
    input   wire          w_req,  //д��������
    input   wire [31:0]   w_data, //Ҫд������ݣ�CPU����
    input   wire [31:0]   addr,   //Ҫд����߶�ȡ�ĵ�ַ��CPU����
    output  reg [31:0]   mem_addr, //Ҫ������д�ĵ�ַ�� ����mem
    input   wire [31:0]   mem_data, //����������  mem����
    output  reg [31:0]   dirty_mem,
    output  wire [31:0]   r_data,  //���������ݣ� ����CPU
    input   wire          mem_ready,
    output  reg          mem_w, //Ҫд������
    output  wire          mem_r, //���ڴ�����
    output   reg            miss   //  �Ƿ�ȱʧ
);
parameter IDLE       =      3'd0;
parameter READ       =      3'd1;
parameter WRITE      =      3'd2;
parameter MISS       =      3'd3;
parameter W_DIRTY    =      3'd4;

/*
    ��ȡtag�ж��Ƿ�����
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
reg [1:0] used_update; //���º��used
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
// ʹ��valid��ʾ�Ƿ�ʹ�ù�����ʾLRU���ԣ���ʼʱcache��Ϊ0
// ��valid || dirtyʱ��ʾ��Ч
wire [1:0] hit;
assign  hit   =  {(dirty_1 || valid_1) && (r_tag_1 == tag), (dirty_2 || valid_2) && (r_tag_2 == tag)};

/*
    �ж�״̬��
    ��ʼ״̬ΪIDLE����������ʱ��READ�� д����WRITE
    ����READ��WRITE��Ҫ���ж�δhitʱ�Ƿ�dirty��dirty��Ҫ��д�أ�����W_DIRTY״̬
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
            // miss �Ҹ���LRU������Ҫд�صĲ�dirty
            if(miss && ((!dirty_1 && !dirty_2) || (used[1] && !dirty_2) || (used[0] && !dirty_1))) begin
                ns = MISS;
            end
            // miss�Ҹ���LRU������Ҫд��
            else if(miss && ((dirty_1 && used[2]) || (dirty_2 && used[1])))
                ns = W_DIRTY; //��Ҫд��������
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
            //     ns = ;  //MISS �Ҳ���Ҫд��
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
                // ns = MISS; // д�غ�ת��miss
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
    �����ź�
*/

wire data_from_mem;
wire addr_buf_we;
wire ret_buf_we;
wire [31:0] dirty_addr ;
wire [31:0] cache_rdata_1;
wire [31:0] cache_rdata_2;
// reg cache_we_1;
// reg cache_we_2;
// dirty_buf��¼dirtyֵ
// used_buf��¼usedֵ
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
            if(refill) begin  //��Ҫ������������д�ػ��ߴ���CPU
                if(used_buf[1]) begin //��ʾҪд��ڶ���
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
                else begin //���ʱ
                    tag_we_1    = 1'b1;
                    tag_we_2    = 1'b0;
                    w_valid_1   = 1'b1;
                    w_valid_2   = 1'b0;
                    used_update = 2'b10;
                end
                 //��ʾ��cpuд������
                if(we_op && used_buf[1]) begin //д�ڶ���
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
            else begin  //δ����

                miss = 1'b1;
                // addr_buf_we = 1'b0;
                //δ���е����������ݣ�����Ҫд��
                if(((dirty_1 && used[2]) || (dirty_2 && used[1]))) begin
                    mem_w = 1'b1;
                    mem_addr = dirty_addr;
                    //used��Щ���Ǹ����ڶ�����
                    dirty_mem = (dirty_1 && used[2]) ? cache_rdata_1 : cache_rdata_2;
                end
            end
        end 
        MISS: begin
            miss = 1'b1;
            mem_addr = addr_buf;
        end                
        WRITE: begin
           
            if (hit) begin // ����
                miss = 1'b0;
                // addr_buf_we = 1'b1; // �����ַ����дʹ��
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
            end else begin // δ����
                miss = 1'b1;
                // addr_buf_we = 1'b0; 
                if(((dirty_1 && used[2]) || (dirty_2 && used[1]))) begin
                    mem_w = 1'b1;
                    mem_addr = dirty_addr;
                    //used��Щ���Ǹ����ڶ�����
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