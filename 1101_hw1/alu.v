module alu (
    input               i_clk,
    input               i_rst_n,
    input               i_valid,
    input signed [11:0] i_data_a,
    input signed [11:0] i_data_b,
    input        [2:0]  i_inst,
    output              o_valid,
    output       [11:0] o_data,
    output              o_overflow
);
    
// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
reg  [11:0] o_data_w, o_data_r;
reg         o_valid_w, o_valid_r;
reg         o_overflow_w, o_overflow_r;
// ---- Add your own wires and registers here if needed ---- //
wire signed  [23:0]result[0:7];
reg [2:0]last_inst_w,last_inst_r;
reg mac_overflow_w,mac_overflow_r;
wire [11:0]abs_i_data_a,abs_i_data_b;
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
assign o_valid = o_valid_r;
assign o_data = o_data_r;
assign o_overflow = o_overflow_r;
// ---- Add your own wire data assignments here if needed ---- //
assign result[0] = i_data_a + i_data_b;
assign result[1] = i_data_a - i_data_b;
assign result[2] = i_data_a*i_data_b;
assign result[3] =(result[2][4])?(o_data_r+ result[2][16:5]+1):(o_data_r+ result[2][16:5]+1);
assign result[4] = (i_data_a~^i_data_b);
assign result[5] = (!i_data_a[11])?i_data_a:0;
assign result[6] = i_data_a + i_data_b;
// assign result[7] = -2;
assign abs_i_data_a = (~i_data_a[11])?i_data_a:-i_data_a;
assign abs_i_data_b = (~i_data_b[11])?i_data_b:-i_data_b;
// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always@(*) begin
    // $display("%b",result[7]);
    o_data_w = 0;
    o_overflow_w = 1'b0;
    o_valid_w = o_valid_r;
    last_inst_w = i_inst;
    mac_overflow_w = 1'b0;
    if(i_valid)begin
        o_valid_w = 1'b1;
        case (i_inst)
            
            3'b000:begin//Signed Addition
                if((result[0][11]^i_data_a[11]) & (result[0][11]^i_data_b[11]))begin//using xor to judge overflow
                    o_overflow_w = 1;
                end
                // if(i_data_a[11]&i_data_b[11]&!result[0][11])begin//a:-  b:- c:+
                //     o_overflow_w = 1;
                // end
                // else if(~i_data_a[11]&~i_data_b[11]&result[0][11])begin//a:+  b:+ c:-
                //     o_overflow_w = 1;
                // end
                else begin
                    o_data_w = result[0][11:0];
                    o_overflow_w = 0;
                end
            end 
            3'b001:begin//Signed Subtraction
                if((result[1][11]^i_data_a[11]) & (result[1][11]^(!i_data_b[11])))begin//using xor to judge overflow
                    o_overflow_w = 1;
                end
                // if(i_data_a[11]&!i_data_b[11]&!result[1][11])begin//a:-  b:+ c:+
                //     o_overflow_w = 1;
                // end
                // else if(!i_data_a[11]&i_data_b[11]&result[1][11])begin//a:+  b:- c:-
                //     o_overflow_w = 1;
                // end
                else begin
                    o_data_w = result[1][11:0];
                    o_overflow_w = 0;
                end
            end
            3'b010:begin//Signed Multiplication
                
                if((|result[2][23:17])&(!result[2][16]))begin
                    o_overflow_w = 1;
                end
                else if((!(&result[2][23:17]))&(result[2][16]))begin
                    o_overflow_w = 1;
                end
                else begin
                    if(result[2][4])begin
                        o_data_w = result[2][16:5]+1;
                    end
                    else begin
                        o_data_w = result[2][16:5];
                    end
                end
            end
            3'b011:begin //MAC
                mac_overflow_w = mac_overflow_r;
                if(mac_overflow_r)begin             //once the overflow is detected
                    o_overflow_w = 1'b1;
                    mac_overflow_w = 1'b1;
                end
                else if(last_inst_r == 3'b011)begin //not first meet instruction MAC
                    if((|result[2][23:17])&(!result[2][16]))begin
                        o_overflow_w = 1;
                        mac_overflow_w = 1;
                    end
                    else if((!(&result[2][23:17]))&(result[2][16]))begin
                        o_overflow_w = 1;
                        mac_overflow_w = 1;
                    end
                    else if(result[3][23]!=o_data_r[11])begin       //not so sure???
                        o_overflow_w = 1;
                        mac_overflow_w = 1;
                    end
                    
                    else begin
                        if(result[2][4])begin
                            o_data_w = o_data_r+ result[2][16:5]+1;
                        end
                        else begin
                            o_data_w = o_data_r+result[2][16:5];
                        end
                    end
                end
                else begin                          //first meet instruction MAC
                    if((|result[2][23:17])&(!result[2][16]))begin
                        o_overflow_w = 1;
                        mac_overflow_w = 1;
                    end
                    else if((!(&result[2][23:17]))&(result[2][16]))begin
                        o_overflow_w = 1;
                        mac_overflow_w = 1;
                    end
                    else begin
                        if(result[2][4])begin
                            o_data_w = o_data_r+ result[2][16:5]+1;
                        end
                        else begin
                            o_data_w = o_data_r+result[2][16:5];
                        end
                    end
                end
            end
            3'b100:begin//XNOR
                o_data_w = result[4];
            end
            3'b101:begin//ReLU
                o_data_w = result[5];
            end
            3'b110:begin//Mean
                o_data_w = result[6][12:1];
            end
            3'b111:begin//Absolute Max
                if(abs_i_data_a>=abs_i_data_b)begin
                    o_data_w = abs_i_data_a;
                    
                end
                else begin
                    o_data_w = abs_i_data_b;
                end
            end
            default: begin
                
            end
        endcase
    end
    else begin
        o_valid_w = 1'b0;
    end
end




// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        o_data_r <= 0;
        o_overflow_r <= 0;
        o_valid_r <= 0;
        last_inst_r <= 0;
        mac_overflow_r <= 1;
    end else begin
        o_data_r <= o_data_w;
        o_overflow_r <= o_overflow_w;
        o_valid_r <= o_valid_w;
        last_inst_r <= last_inst_w;
        mac_overflow_r <= mac_overflow_w ;
    end
end


endmodule
