
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/10 19:45:42
// Design Name: 
// Module Name: my_cpu_39
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module my_cpu_39(
    input  wire        clk,
    input  wire        resetn,
    input              miss,
    output reg          r_req,
    output wire [31:0]  nextpc,
    output wire         br,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [3 :0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
// reg         reset;
// always @(posedge clk) reset <= ~resetn;
reg         valid;
always @(posedge clk) begin
    if (!resetn) begin
        valid <= 1'b0;
    end
    else begin
        valid <= 1'b1;
    end
end
wire [31:0] true_rf_data_1;
wire [31:0] true_rf_data_2;
wire bubble;
// wire        br;
reg [31:0] ID_EX_br_target;
//////////////////////////////////////////////////////////////////
// FETCH stage -> DECODE                                       ///
//////////////////////////////////////////////////////////////////
wire [31:0] seq_pc;
// wire [31:0] nextpc;
wire [31:0] inst;
reg [31:0] pc;
assign seq_pc = pc + 3'h4;
// reg  [31:0] pc;

assign nextpc       =  br ? ID_EX_br_target : (bubble)   ? pc        :
                         seq_pc;

always @(posedge clk) begin
    if (!resetn) begin
        r_req <= 1'b1;
        pc <= 32'h1bfffffc;     //trick: to make nextpc be 0x1c000000 during reset 
    end
    else if(!miss) begin
        pc <= nextpc;
        r_req <= 1'b1;
    end
end
assign inst_sram_we    = 1'b0;
assign inst_sram_addr  = pc;
assign inst_sram_wdata = 32'b0;
assign inst            = pc == 32'h1bfffffc ? 32'd0: inst_sram_rdata;
reg [31:0] IF_ID_pc;
reg [31:0] IF_ID_inst;
always @(posedge clk) begin
    if(!resetn) begin
        IF_ID_pc <= 32'h1bfffffc;
        IF_ID_inst <= 32'd0;
    end
    else begin
        IF_ID_pc <=  bubble|| miss ||br ? 32'd0 : pc;
        IF_ID_inst <=  bubble || miss|| br ? 32'd0 : inst;
    end
end

//////////////////////////////////////////////////////////////////
//  DECODE stage -> EXECUTE                                    ///
//////////////////////////////////////////////////////////////////
wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [31:0] op_19_15_d;

assign op_31_26  = IF_ID_inst[31:26];
assign op_25_22  = IF_ID_inst[25:22];
assign op_21_20  = IF_ID_inst[21:20];
assign op_19_15  = IF_ID_inst[19:15];

decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

wire        inst_add_w;
wire        inst_sub_w;
wire        inst_slt;
wire        inst_sltu;
wire        inst_nor;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_slli_w;
wire        inst_srli_w;
wire        inst_srai_w;
wire        inst_addi_w;
wire        inst_ld_w;
wire        inst_st_w;
wire        inst_jirl;
wire        inst_b;
wire        inst_bl;
wire        inst_beq;
wire        inst_bne;
wire        inst_lu12i_w;

wire        inst_pcaddu12i;
wire        inst_slti;
wire        inst_sltui;
wire        inst_andi;
wire        inst_ori;
wire        inst_xori;
wire        inst_sll_w;
wire        inst_srl_w;
wire        inst_sra_w;
wire        inst_ld_b;
wire        inst_st_b;
wire        inst_st_h;
wire        inst_ld_h;
wire        inst_ld_hu;
wire        inst_ld_bu;
wire        inst_blt;
wire        inst_bge;
wire        inst_bltu;
wire        inst_bgeu;

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~IF_ID_inst[25];

assign inst_sll_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];
assign inst_srl_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
assign inst_sra_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
assign inst_slti   = op_31_26_d[6'h00] & op_25_22_d[4'h8];
assign inst_sltui  = op_31_26_d[6'h00] & op_25_22_d[4'h9];
assign inst_andi   = op_31_26_d[6'h00] & op_25_22_d[4'hd];
assign inst_ori    = op_31_26_d[6'h00] & op_25_22_d[4'he];
assign inst_xori   = op_31_26_d[6'h00] & op_25_22_d[4'hf];
assign inst_ld_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
assign inst_st_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
assign inst_st_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h5];
assign inst_ld_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
assign inst_ld_hu  = op_31_26_d[6'h0a] & op_25_22_d[4'h9];
assign inst_ld_bu  = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
assign inst_blt    = op_31_26_d[6'h18];
assign inst_bge    = op_31_26_d[6'h19];
assign inst_bltu   = op_31_26_d[6'h1a];
assign inst_bgeu   = op_31_26_d[6'h1b];
assign inst_pcaddu12i = op_31_26_d[6'h07] & ~inst[25];

wire        need_ui12;
wire        need_ui5;
wire        need_si12;
wire        need_si16;
wire        need_si20;
wire        need_si26;
wire        src2_is_4;

assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;
assign need_si12  =  inst_addi_w | inst_ld_w | inst_st_w | inst_ld_b | inst_ld_h|
                     inst_ld_bu  | inst_st_b | inst_st_h | inst_ld_hu;
assign need_ui12  =  inst_andi | inst_ori | inst_xori;
assign need_si16  =  inst_jirl | inst_beq | inst_bne | inst_blt | inst_bge |
                     inst_bltu | inst_bgeu;
assign need_si20  =  inst_lu12i_w | inst_pcaddu12i;
assign need_si26  =  inst_b | inst_bl;
assign src2_is_4  =  inst_jirl | inst_bl;

wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;

assign rd   = IF_ID_inst[ 4: 0];
assign rj   = IF_ID_inst[ 9: 5];
assign rk   = IF_ID_inst[14:10];

wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;

assign i12  = IF_ID_inst[21:10];
assign i20  = IF_ID_inst[24: 5];
assign i16  = IF_ID_inst[25:10];
assign i26  = {IF_ID_inst[ 9: 0], IF_ID_inst[25:10]};
// �õ�����??
wire [31:0] imm;
assign imm = src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
             need_ui12 ? {20'd0, i12[11:0]}         :
             need_ui5  ? {27'd0, rk}                :
            {{20{i12[11]}}, i12[11:0]} ;
wire   src2_is_imm;
assign src2_is_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |
                       inst_addi_w |
                       inst_ld_w   |
                       inst_st_w   |
                       inst_lu12i_w|
                       inst_jirl   |
                       inst_bl     |
                       inst_pcaddu12i |
                       inst_slti   |
                       inst_sltui  |
                       inst_andi   |
                       inst_ori    |
                       inst_xori   |
                       inst_ld_b   |
                       inst_ld_h   |
                       inst_ld_bu  |
                       inst_ld_hu  |
                       inst_st_b   |
                       inst_st_h   ;


wire   src1_is_pc;
assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;
wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

wire        src_reg_is_rd;
assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w | inst_st_h | inst_st_b
                     | inst_blt | inst_bltu | inst_bgeu | inst_bge ;

wire       gr_we;
assign gr_we         = (~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b  & ~inst_st_b &
                       ~inst_st_h & ~inst_bge & ~inst_blt & ~inst_bgeu & ~inst_bltu) && IF_ID_pc;

wire        dst_is_r1;
wire [4: 0] dest;
assign dst_is_r1     = inst_bl;
assign dest          = dst_is_r1 ? 5'd1 : rd;

wire   res_from_mem;
assign res_from_mem  = inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu;

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd :rk;
// ���Ĵ���
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
);
// alu ����
wire [11:0] alu_op;
assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w
                    | inst_jirl | inst_bl | inst_pcaddu12i | inst_ld_b
                    | inst_ld_bu | inst_ld_h | inst_ld_hu | inst_st_b
                    | inst_st_h;

assign alu_op[ 1] = inst_sub_w;
assign alu_op[ 2] = inst_slt    | inst_slti | inst_blt | inst_bge;
assign alu_op[ 3] = inst_sltu   | inst_sltui | inst_bltu | inst_bgeu;
assign alu_op[ 4] = inst_and    | inst_andi;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or     | inst_ori;
assign alu_op[ 7] = inst_xor    | inst_xori;
assign alu_op[ 8] = inst_slli_w | inst_sll_w;
assign alu_op[ 9] = inst_srli_w | inst_srl_w;
assign alu_op[10] = inst_srai_w | inst_sra_w;
assign alu_op[11] = inst_lu12i_w ;
// д�ڴ���??
wire        mem_we;
assign mem_we        = inst_st_w | inst_st_b | inst_st_h;

// ��ת�ź�
wire [31:0] rj_value;
wire [31:0] rkd_value;
assign rj_value  = rf_rdata1;
assign rkd_value = rf_rdata2;
wire [8:0]  br_taken;
// wire        rj_eq_rd;
// assign rj_eq_rd = (rj_value == rkd_value);
assign br_taken = {inst_bgeu ,inst_bge,inst_bltu,inst_blt,inst_beq, inst_bne, inst_jirl, inst_bl, inst_b};

wire [31:0] br_offs;
wire [31:0] br_target;
wire [31:0] jirl_offs;
assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};
assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
          {{14{i16[15]}}, i16[15:0], 2'b0} ;
// assign br_target = (inst_beq || inst_bne || inst_bl || inst_b) ? (IF_ID_pc + br_offs) :(rj_value + jirl_offs);
// ���ܻ����?
assign br_target = (inst_beq || inst_bne || inst_bl || inst_b || inst_blt || inst_bltu || inst_bge || inst_bgeu) ? (IF_ID_pc + br_offs) :
                                                   /*inst_jirl*/ (rj_value + jirl_offs);

reg [31:0] ID_EX_pc;
//reg [31:0] ID_EX_br_target;
reg [ 4:0] ID_EX_rd;
reg [ 4:0] ID_EX_r1;
reg [ 4:0] ID_EX_r2;
reg [ 8:0] ID_EX_br_taken;
reg [31:0] ID_EX_imm;
reg [31:0] ID_EX_rf_rdata1;
reg [31:0] ID_EX_rf_rdata2;
reg [11:0] ID_EX_alu_op;
reg        ID_EX_mem_we;
// reg        ID_EX_br_taken;
reg        ID_EX_gr_we;
reg        ID_EX_src2_is_imm;
reg        ID_EX_src1_is_pc;
reg        ID_EX_res_from_mem;
reg [2:0]  ID_EX_st;   
reg [4:0]  ID_EX_ld;   
always @(posedge clk) begin
    if(!resetn) begin
        ID_EX_pc           <=  32'd0;
        ID_EX_rd           <=  5'd0 ;
        ID_EX_imm          <=  32'd0;
        ID_EX_rf_rdata1    <=  32'd0;
        ID_EX_rf_rdata2    <=  32'd0;
        ID_EX_alu_op       <=  12'd0;
        ID_EX_mem_we       <=  1'b0;
        ID_EX_gr_we        <=  1'b0; 
        ID_EX_src2_is_imm  <=  1'b0;
        ID_EX_src1_is_pc   <=  1'b0;
        ID_EX_res_from_mem <=  1'b0;
        ID_EX_br_target    <=  1'b0;
        ID_EX_br_taken     <=  5'd0;     
        ID_EX_r1           <=  5'd0;  
        ID_EX_r2           <=  5'd0;  
        ID_EX_st           <=  3'd0;
    end
    else begin
        ID_EX_pc           <= (!br) ? IF_ID_pc        : 32'd0;
        ID_EX_rd           <= (!br) ? dest            : 5'd0 ;
        ID_EX_imm          <= (!br) ? imm             : 32'd0;
        ID_EX_rf_rdata1    <= (!br) ? rf_rdata1       : 32'd0;
        ID_EX_rf_rdata2    <= (!br) ? rf_rdata2       : 32'd0;
        ID_EX_alu_op       <= (!br) ? alu_op          : 12'd0;
        ID_EX_mem_we       <= (!br) ? mem_we          : 1'b0;
        // ID_EX_br_taken     (!br) ? <= br_taken;
        ID_EX_gr_we        <= (!br) ? gr_we           : 1'b0; 
        ID_EX_src2_is_imm  <= (!br) ? src2_is_imm     : 1'b0;
        ID_EX_src1_is_pc   <= (!br) ? src1_is_pc      : 1'b0;
        ID_EX_res_from_mem <= (!br) ? res_from_mem    : 1'b0;
        ID_EX_br_target    <= (!br) ? br_target       : 1'b0;
        ID_EX_br_taken     <= (!br) ? br_taken        : 5'd0;
        ID_EX_r1           <= (!br) ? rf_raddr1       : 5'd0;  
        ID_EX_r2           <= (!br) ? rf_raddr2       : 5'd0;     
        ID_EX_st           <= (!br) ? {inst_st_w, inst_st_h, inst_st_b} : 3'd0;
        ID_EX_ld           <= (!br) ? {inst_ld_w, inst_ld_h, inst_ld_hu, inst_ld_b, inst_ld_bu} : 5'd0;
    end

end

//////////////////////////////////////////////////////////////////
//  EXECUTE stage -> MEMORY                                    ///
//////////////////////////////////////////////////////////////////

wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] alu_result ;

assign alu_src1 = ID_EX_src1_is_pc  ? ID_EX_pc[31:0] :  true_rf_data_1;
assign alu_src2 = ID_EX_src2_is_imm ? ID_EX_imm : true_rf_data_2;
alu u_alu(
    .alu_op     (ID_EX_alu_op),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result)
);

wire        rj_eq_rd;
assign rj_eq_rd = (true_rf_data_1 == true_rf_data_2);
//wire        br;
assign      br = ((ID_EX_br_taken[4] && rj_eq_rd) || (ID_EX_br_taken[3] && !rj_eq_rd)
                ||(ID_EX_br_taken[2]) || ID_EX_br_taken[1] || ID_EX_br_taken[0]
                ||(ID_EX_br_taken[5] && alu_result[0]) || (ID_EX_br_taken[6] && alu_result[0])
                ||(ID_EX_br_taken[7] && !alu_result[0]) || (ID_EX_br_taken[8] && !alu_result[0]))?1'b1:1'b0;

reg [31:0] EX_MEM_alu_result;
reg [ 4:0] EX_MEM_rd;
reg [31:0] EX_MEM_pc;
reg [31:0] EX_MEM_rd_value;
reg        EX_MEM_mem_we;
reg        EX_MEM_gr_we;
reg        EX_MEM_res_from_mem;
reg [2:0]  EX_MEM_st;   
reg [4:0]  EX_MEM_ld;   
always @(posedge clk) begin
    if(!resetn) begin
        EX_MEM_alu_result    <= 32'd0;
        EX_MEM_rd            <= 5'd0;
        EX_MEM_pc            <= 32'd0;
        EX_MEM_rd_value      <= 32'd0;
        EX_MEM_mem_we        <= 1'd0;
        EX_MEM_gr_we         <= 1'd0;   
        EX_MEM_res_from_mem  <= 1'd0;      
        EX_MEM_ld            <= 5'd0;
        EX_MEM_st            <= 3'd0;
    end
    else begin
            EX_MEM_alu_result    <= alu_result        ;
            EX_MEM_rd            <= ID_EX_rd          ;
            EX_MEM_pc            <= ID_EX_pc          ;
            EX_MEM_rd_value      <= true_rf_data_2    ;
            EX_MEM_mem_we        <= ID_EX_mem_we      ;
            EX_MEM_gr_we         <= ID_EX_gr_we       ;   
            EX_MEM_res_from_mem  <= ID_EX_res_from_mem;
            EX_MEM_ld            <= ID_EX_ld;   
            EX_MEM_st            <= ID_EX_st;   
    end

end
//////////////////////////////////////////////////////////////////
//  MEMORY stage -> WRITE BACK                                 ///
//////////////////////////////////////////////////////////////////
// wire [31:0] data_sram_rdata;
wire [1:0] ld_half_op;
wire [7:0] ld_b_data;
wire [3:0] ld_byte_op;
assign ld_half_op = EX_MEM_alu_result[1] ? 2'b10 : 2'b01;
assign ld_byte_op = EX_MEM_alu_result[0] ? (EX_MEM_alu_result[1] ? (4'b1000): (4'b0010)):
                    (EX_MEM_alu_result[1] ?(4'b0100) : (4'b0001) );

assign ld_b_data   = ({8{ld_byte_op[0]}} & data_sram_rdata[7:0] ) |
                    ({8{ld_byte_op[1]}} & data_sram_rdata[15:8]) |
                    ({8{ld_byte_op[2]}} & data_sram_rdata[23:16]) |
                    ({8{ld_byte_op[3]}} & data_sram_rdata[31:24]);

wire [15:0] ld_h_data ;

assign ld_h_data  = ({16{ld_half_op[1]}} & data_sram_rdata[31:16]) |
                    ({16{ld_half_op[0]}} & data_sram_rdata[15: 0]);

wire [31:0] st_b_data ;
wire [31: 0] st_half_data ;
wire [31: 0] st_data;
wire  st_dram;
assign st_data = st_dram ? MEM_WB_data : data_sram_rdata;
assign st_b_data   = ld_byte_op[3] ? {EX_MEM_rd_value[7:0], st_data[23:0]}:
                     (ld_byte_op[2] ? {st_data[31:24], EX_MEM_rd_value[7:0], st_data[15:0]} :
                     (ld_byte_op[1] ? {st_data[31:16], EX_MEM_rd_value[7:0],  st_data[7:0]} :
                     {st_data[31:8], EX_MEM_rd_value[7:0]}));
assign st_half_data = ld_half_op[0] ? {st_data[31:16], EX_MEM_rd_value[15:0]}:{EX_MEM_rd_value[15:0],st_data[15:0]};

assign data_sram_we    = EX_MEM_mem_we && valid  ;
assign data_sram_addr  = EX_MEM_alu_result;
// assign data_sram_wdata = EX_MEM_rd_value  ;
assign data_sram_wdata = EX_MEM_st[2] ? EX_MEM_rd_value :
                        (EX_MEM_st[1] ? st_half_data     :
                        st_b_data);
// ({32{EX_MEM_st[2]}} & EX_MEM_rd_value) | 
//                          ({32{EX_MEM_st[1]}} & st_half_data) |
//                          ({32{EX_MEM_st[0]}} & st_b_data);


wire [31:0] mem_result;
assign mem_result   = EX_MEM_ld[4]   ? data_sram_rdata       :
                      EX_MEM_ld[1]   ? {{24{ld_b_data[7]}} ,ld_b_data}:
                      EX_MEM_ld[3]   ? {{16{ld_h_data[15]}}, ld_h_data} :
                      EX_MEM_ld[0]   ? {24'd0, ld_b_data} :
                      {16'd0, ld_h_data};

reg [31:0] MEM_WB_result;
reg [31:0] MEM_WB_pc;
reg [31:0] MEM_WB_alu_result;
reg [ 4:0] MEM_WB_rd;
reg        MEM_WB_gr_we;
reg        MEM_WB_res_from_mem;
reg [31:0] MEM_WB_data;
reg        MEM_WB_mem_we;
always @(posedge clk) begin
    if(!resetn) begin
        MEM_WB_alu_result   <= 32'd0;
        MEM_WB_result       <= 32'd0;
        MEM_WB_gr_we        <= 1'd0;
        MEM_WB_rd           <= 5'd0;
        MEM_WB_res_from_mem <= 1'd0;
        MEM_WB_pc           <= 32'd0;       
        MEM_WB_mem_we       <= 1'd0;
        MEM_WB_data         <= 32'd0;
    end
    else begin
        MEM_WB_alu_result   <= EX_MEM_alu_result  ;
        MEM_WB_result       <= mem_result         ;
        MEM_WB_gr_we        <= EX_MEM_gr_we       ;
        MEM_WB_rd           <= EX_MEM_rd          ;
        MEM_WB_res_from_mem <= EX_MEM_res_from_mem;
        MEM_WB_pc           <= EX_MEM_pc          ;        
        MEM_WB_mem_we       <= EX_MEM_mem_we      ;
        MEM_WB_data         <= data_sram_wdata    ;
    end

end
//////////////////////////////////////////////////////////////////
//  WRITE BACK                                                 ///
//////////////////////////////////////////////////////////////////
wire [31:0] final_result;
assign final_result = MEM_WB_res_from_mem ? MEM_WB_result : MEM_WB_alu_result;
assign rf_we = MEM_WB_gr_we;
assign rf_waddr = MEM_WB_rd;
assign rf_wdata = final_result;
reg [31:0] WB_rd;
reg [31:0] result;
reg  WB_rd_we;
always @(posedge clk) begin
    if(!resetn) begin
        WB_rd <=0;        
        WB_rd_we <=0;        
        result <= 32'd0;
    end
    else begin
        WB_rd <= MEM_WB_rd;        
        WB_rd_we <= MEM_WB_gr_we;    
        result <=final_result;    
    end 

end
//////////////////////////////////////////////////////////////////
//  ���?                                                       ///
//////////////////////////////////////////////////////////////////
wire EX_MEM_forward_op_rj;
wire EX_MEM_forward_op_rk;

wire MEM_WB_forward_op_rj;
wire MEM_WB_forward_op_rk;

wire ID_EX_forward_op_rj;
wire ID_EX_forward_op_rk;

// wire ST_LD;

assign ID_EX_forward_op_rj  = (WB_rd == ID_EX_r1)      ? 1'b1 : 1'b0;
assign ID_EX_forward_op_rk  = (WB_rd == ID_EX_r2)      ? 1'b1 : 1'b0;
assign EX_MEM_forward_op_rj = (ID_EX_r1 == EX_MEM_rd ) ? 1'b1 : 1'b0;      
assign EX_MEM_forward_op_rk = (ID_EX_r2 == EX_MEM_rd ) ? 1'b1 : 1'b0;
assign MEM_WB_forward_op_rj = (ID_EX_r1 == MEM_WB_rd)  ? 1'b1 : 1'b0;
assign MEM_WB_forward_op_rk = (ID_EX_r2 == MEM_WB_rd)  ? 1'b1 : 1'b0;

// wire [31:0] EX_MEM_alu_result_wire;
// wire [31:0] ID_EX_rf_rdata1_wire;
// wire [31:0] ID_EX_rf_rdata2_wire;


assign true_rf_data_1 = (EX_MEM_gr_we && EX_MEM_forward_op_rj) ? EX_MEM_alu_result : 
                        ((MEM_WB_gr_we && MEM_WB_forward_op_rj) ? final_result      :
                        (WB_rd_we && ID_EX_forward_op_rj)      ? result             : ID_EX_rf_rdata1);
assign true_rf_data_2 = (EX_MEM_gr_we && EX_MEM_forward_op_rk) ? EX_MEM_alu_result : 
                        ((MEM_WB_gr_we && MEM_WB_forward_op_rk) ? final_result :
                        (WB_rd_we && ID_EX_forward_op_rk)     ? result  : ID_EX_rf_rdata2);

// wire st_dram;
assign st_dram = (MEM_WB_alu_result[31:2] == EX_MEM_alu_result[31:2]) && MEM_WB_mem_we ? 1'b1: 1'b0;
//////////////////////////////////////////////////////////////////
//  Bubble                                                     ///
//////////////////////////////////////////////////////////////////
//wire bubble;
assign bubble = (res_from_mem) ? 1'b1 :1'b0;
assign debug_wb_pc       = MEM_WB_pc;
assign debug_wb_rf_we   = {4{rf_we}};
assign debug_wb_rf_wnum  = MEM_WB_rd;
assign debug_wb_rf_wdata = final_result;
endmodule
