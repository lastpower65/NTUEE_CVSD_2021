module thunderbird(
 input i_clk,
 input i_rst,
 input i_left,
 input i_right,
 input i_haz,
 output reg [9:0] o_led
);

// ---------------------------------------------------------------------------
// Parameter
// ---------------------------------------------------------------------------
parameter IDLE = 0;
parameter I_LEFT = 1;
parameter I_RIGHT = 2;
parameter I_HAZ = 3;

// ---------------------------------------------------------------------------
// MY REG&WIRE
// --------------------------------------------------------------------------
reg [25:0]counter_w,counter_r;
reg [2:0]state_w,state_r;
reg [9:0]o_led_w;
// ---------------------------------------------------------------------------
// continuous assign
// ---------------------------------------------------------------------------

always @(*) begin
    counter_w = counter_r;
    state_w = state_r;
    o_led_w = o_led;
    case (state_r)
        
        IDLE:begin
            counter_w =0;
            if(i_left)begin
                state_w = I_LEFT;
                o_led_w =10'b0010000000;
            end
            else if(i_right)begin
                state_w = I_RIGHT;
                o_led_w =10'b0000000100;
            end
            else if(i_haz)begin
                state_w = state_r;
                o_led_w = 10'b1111111111;
            end
        end 
        default: begin
            state_w =state_r;
        end
    I_LEFT:begin
        
        if(i_haz)begin
            state_w = IDLE;
            o_led_w = 10'b1111111111;
        end
        else begin
            if(counter_r == 25000000)begin
                counter_w = 0;
                if(o_led == 10'b1110000000)begin
                    state_w = IDLE;
                end
                else begin
                    o_led_w = o_led<<1+10'b10000000;
                    state_w = state_r;
                end
                
            end
            else begin
                counter_w = counter_r+1;
                state_w = state_r;
            end
        end
    end
    I_RIGHT:begin
        
        if(i_haz)begin
            state_w = IDLE;
            o_led_w = 10'b1111111111;
        end
        else begin
            if(counter_r == 25000000)begin
                counter_w = 0;
                if(o_led == 10'b0000000111)begin
                    state_w = IDLE;
                end
                else begin
                    o_led_w = o_led>>1+10'b100;
                    state_w = state_r;
                end
                
            end
            else begin
                counter_w = counter_r+1;
                state_w = state_r;
            end
        end
    end
    
    endcase
end

always @(posedge i_clk or i_rst) begin
    if(i_rst)begin
        state_r <= IDLE; 
        o_led <=  0;
        counter_r <=0;
    end

    else begin
        state_r <= state_w;
        o_led <= o_led_w;
        counter_r <= counter_w;
    end
end

endmodule