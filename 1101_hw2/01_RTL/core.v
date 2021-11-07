module core #(                             //Don't modify interface
	parameter ADDR_W = 32,
	parameter INST_W = 32,
	parameter DATA_W = 32
)(
	input                   i_clk,
	input                   i_rst_n,
	output [ ADDR_W-1 : 0 ] o_i_addr,
	input  [ INST_W-1 : 0 ] i_i_inst,
	output                  o_d_wen,
	output [ ADDR_W-1 : 0 ] o_d_addr,
	output [ DATA_W-1 : 0 ] o_d_wdata,
	input  [ DATA_W-1 : 0 ] i_d_rdata,
	output [        1 : 0 ] o_status,
	output                  o_status_valid
);
// ---------------------------------------------------------------------------
//parameter

//state parameter
parameter IDLE = 0;
parameter INSTRUCTION_FETCHIING = 1;
parameter ALU_COMPUTING = 2;
parameter LOAD_DATA = 4;
parameter NEXT_PC_GENERATION = 5;
parameter PROCESS_END = 6;
//op parameter
parameter ADD = 6'd1;
parameter SUB = 6'd2;
parameter ADD_IMMEDIATE = 6'd3;
parameter LOAD_WORD = 6'd4;
parameter STORE_WORD = 6'd5;
parameter AND = 6'd6;
parameter OR = 6'd7;
parameter EXCLUSIVE_OR= 6'd8;
parameter BRANCH_ON_EQUAL = 6'd9;
parameter BRANCH_ON_NOT_EQUAL = 6'd10;
parameter SET_ON_LESS_THAN = 6'd11;
parameter END_OF_FILE = 6'd12;


integer i ;
integer j ;
// ---------------------------------------------------------------------------
// Wires and Registers
//output
reg [ ADDR_W-1 : 0 ] program_counter_w,program_counter_r;
reg o_d_wen_w,o_d_wen_r;
reg [ ADDR_W-1 : 0 ] o_d_addr_w,o_d_addr_r;
reg [ DATA_W-1 : 0 ] o_d_wdata_w,o_d_wdata_r;
reg [        1 : 0 ] o_status_w,o_status_r;
reg o_status_valid_w,o_status_valid_r;

//input
reg [ INST_W-1 : 0 ] i_i_inst_w,i_i_inst_r;



// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
reg [2:0]state_w,state_r;
wire [5:0] opcode;
wire [4:0] s1;
wire [4:0] s2;
wire [4:0] s3;
wire [16:0] im;

//register file
reg [ DATA_W-1 : 0 ] reg_file_w [ DATA_W-1 : 0 ];
reg [ DATA_W-1 : 0 ] reg_file_r [ DATA_W-1 : 0 ];


//counter 
reg [1:0] counter2_w,counter2_r;

// ---------------------------------------------------------------------------
// Continuous Assignment
assign o_i_addr = program_counter_r;
assign o_d_wen = o_d_wen_r;
assign o_d_addr = o_d_addr_r;
assign o_d_wdata = o_d_wdata_r;
assign o_status = o_status_r;
assign o_status_valid = o_status_valid_r;

// Instruction mapping
assign opcode = i_i_inst_r[31:26];
assign s1 = ((opcode == 3)||(opcode == 4)||(opcode == 5)||(opcode == 9)||(opcode == 10))?i_i_inst_r[20:16]:i_i_inst_r[15:11];
assign s2 = i_i_inst_r[25:21];
assign s3 = i_i_inst_r[20:16];
assign im = i_i_inst_r[15:0];


// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //



// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always @(*) begin
	//reg_file
	for(i = 0; i < DATA_W; i = i+1)begin
			reg_file_w [i] = reg_file_r [i];
	end
	o_d_wen_w = o_d_wen_r;
	//state
	state_w = state_r;
	//output
	program_counter_w = program_counter_r;
	o_d_addr_w = o_d_addr_r;
	o_d_wdata_w = o_d_wdata_r;
	o_status_w = o_status_r;
	o_status_valid_w = 1'b0;
	//input
	i_i_inst_w = i_i_inst_r;

	//counter
	counter2_w = counter2_r;

	case (state_r)
		IDLE:begin
			state_w = INSTRUCTION_FETCHIING;
			o_status_valid_w = 1'b0;
			o_status_w = 0;
			o_d_wen_w = 0;
		end
		INSTRUCTION_FETCHIING:begin

			
			state_w = ALU_COMPUTING;
			i_i_inst_w = i_i_inst;
				
			
			
		end 
		ALU_COMPUTING:begin
			//$display("%d" ,i_i_inst[31:26]);
			//$display("j:%d, program_counter_r:%d",j,program_counter_r);
			//$display("%b" ,i_i_inst_r);
			
			// $display("%d" ,i_i_inst[31:26]);
			// $display("%d" ,program_counter_r);
			// $display("($s1:%d $s2:%d" ,reg_file_r[s1],reg_file_r[s2]);
			// for(i = 0; i < DATA_W; i = i+1)begin
			// 		$display("(i:%d-%d " ,i,reg_file_r[i]);
			// end
			//$display("im:%d"  ,i_i_inst_r[15:0]);
			case (opcode)
				6'd1:begin	//add
					
					 reg_file_w[s1] = reg_file_r[s2] + reg_file_r[s3];
					 o_status_w = 2'd0;
					 o_status_valid_w = 1'b1;
					 state_w = IDLE;
					 program_counter_w = program_counter_r + 4;
				end 
				6'd2:begin	//sub
					 reg_file_w[s1] = reg_file_r[s2] - reg_file_r[s3];
					 o_status_w = 2'd0;
					 o_status_valid_w = 1'b1;
					 state_w = IDLE;
					 program_counter_w = program_counter_r + 4;
				end 
				6'd3:begin	//addi
					 reg_file_w[s1] = reg_file_r[s2] + im;
					 o_status_w = 2'd1;
					 o_status_valid_w = 1'b1;
					 state_w = IDLE;
					 program_counter_w = program_counter_r + 4;
				end 
				6'd4:begin	//lw
					 o_d_wen_w = 0;
					 o_d_addr_w = reg_file_r[s2] + im;
					 state_w = LOAD_DATA;
					//  program_counter_w = program_counter_r + 4;
				end 
				6'd5:begin	//sw
					 o_d_wen_w = 1;
					 o_d_addr_w = reg_file_r[s2] + im;
					 o_d_wdata_w = reg_file_r[s1];
					 o_status_w = 2'd1;
					 o_status_valid_w = 1'b1;
					 state_w = IDLE;
					 program_counter_w = program_counter_r + 4;
				end 
				6'd6:begin	//and
					 reg_file_w[s1] = reg_file_r[s2] & reg_file_r[s3];
					 o_status_w = 2'd0;
					 o_status_valid_w = 1'b1;
					 state_w = IDLE;
					 program_counter_w = program_counter_r + 4;
				end 
				6'd7:begin	//or
					 reg_file_w[s1] = reg_file_r[s2] | reg_file_r[s3];
					 o_status_w = 2'd0;
					 o_status_valid_w = 1'b1;
					 state_w = IDLE;
					 program_counter_w = program_counter_r + 4;
				end 
				6'd8:begin	//xor
					//  $display("reg_file_w[s1]:%d"  ,reg_file_r[s2] ^ reg_file_r[s3]);
					 reg_file_w[s1] = ~(reg_file_r[s2] | reg_file_r[s3]);
					 o_status_w = 2'd0;
					 o_status_valid_w = 1'b1;
					 state_w = IDLE;
					 program_counter_w = program_counter_r + 4;
				end 
				6'd9:begin	//beq
					 if(reg_file_r[s1] == reg_file_r[s2])begin
						 program_counter_w = program_counter_r + 4 + im;
					 end
					 else begin
						 program_counter_w = program_counter_r + 4;
					 end
					 o_status_w = 2'd1;
					 o_status_valid_w = 1'b1;
					 state_w = IDLE;
				end 
				6'd10:begin	//bne
					// $display("s1:%d ,s2:%d"  , s1,s2 );
					// $display("reg_file_w[s1]:%d ,reg_file_w[s2]:%d"  , reg_file_w[s1],reg_file_w[s2] );
					 if(reg_file_r[s1] != reg_file_r[s2])begin
						 program_counter_w = program_counter_r + 4 + im;
					 end
					 else begin
						 program_counter_w = program_counter_r + 4;
					 end
					 o_status_w = 2'd1;
					 o_status_valid_w = 1'b1;
					 state_w = IDLE;
					 
				end 
				6'd11:begin	//slt
					 if(reg_file_r[s2] < reg_file_r[s3])begin
						 reg_file_w[s1] = 1;
					 end
					 else begin
						 reg_file_w[s1] = 0;
					 end
					 o_status_w = 2'd0;
					 o_status_valid_w = 1'b1;
					 state_w = IDLE;
					 program_counter_w = program_counter_r + 4;
				end 
				6'd12:begin	//eof
					 o_status_w = 2'd3;
					 o_status_valid_w = 1'b1;
					 state_w = PROCESS_END;
					 program_counter_w = program_counter_r + 4;
				end 
				default: begin
					
				end
			endcase
		end
		LOAD_DATA:begin
			if(counter2_r == 1)begin
				counter2_w = 0;
				reg_file_w[s1] = i_d_rdata;
				o_status_w = 2'd1;
				o_status_valid_w = 1'b1;
				state_w = IDLE;
				program_counter_w = program_counter_r + 4;
 			end
			else begin
				counter2_w = counter2_r + 1;
				o_d_wen_w = 0;
				o_d_addr_w = reg_file_r[s2] + im;
				state_w = LOAD_DATA;
			end
		end
		PROCESS_END:begin
			
		end
		default:begin
			
		end 
	endcase
end


// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always @(posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n)begin
		//my reg
		j = 0;
		for(i = 0; i < DATA_W; i = i+1)begin
			reg_file_r [i] <= 0;
		end
		state_r <= IDLE;
		//output
		program_counter_r <= 0;
		o_d_wen_r <= 0;
		o_d_addr_r <= 0;
		o_d_wdata_r <= 0;
		o_status_r <= 0;
		o_status_valid_r <= 0;
		//input
		i_i_inst_r <= 0;

		//counter
		counter2_r <= 0;
	end
	else begin
		//my reg
		for(i = 0; i < DATA_W; i = i+1)begin
			reg_file_r [i] <= reg_file_w[i];
		end
		state_r <= state_w;
		//output
		program_counter_r <= program_counter_w;
		o_d_wen_r <= o_d_wen_w;
		o_d_addr_r <= o_d_addr_w;
		o_d_wdata_r <= o_d_wdata_w;
		o_status_r <= o_status_w;
		o_status_valid_r <= o_status_valid_w;
		//input
		i_i_inst_r <= i_i_inst_w;

		//counter
		counter2_r <= counter2_w;
	end
end


endmodule