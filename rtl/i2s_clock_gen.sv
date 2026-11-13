// implement ws

module i2s_clock_gen (
    input logic clk, // system clk 12.288Mhz
    input logic rst, // resets clock generator to a known state
    
    output logic i2s_bclk, // physical bit clock sent to adc and stm32
    output logic i2s_ws, // signal for right or left channel select

    output logic i2s_sample_enable, // tells the receiver when to sample ADC data
    output logic i2s_bit_enable // Enables transmitter to update i2s_sd with the next serial bit
);

logic [1:0] clk_count; // counts system-clock cycles to generate BCLK (0–3).

logic [5:0] frame_bit_count;

// counts system-clock cycles to generate BCLK (0–3).
assign i2s_bclk = clk_count[1]; // this essentially makes bclk 1/4 of the speed of our system clk

// // Enable transmitter to update SD on the system-clock edge that makes BCLK fall
assign i2s_bit_enable = (clk_count == 2'd3);

// Enable receiver to sample ADC SDOUT on the system-clock edge that makes BCLK rise
assign i2s_sample_enable = (clk_count == 2'd1);

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        clk_count <= 2'd0;
        frame_bit_count <= 6'd0;
        i2s_ws <= 1'b0;
    end
    else begin
        // Always increment the system-clock divider
        clk_count <= clk_count + 2'd1;

        // Increment the frame counter at each bclk rising edge
        if (clk_count == 2'd1) begin
            frame_bit_count <= frame_bit_count + 6'd1;
        end

        // Update WS at selected bclk falling edges
        if (clk_count == 2'd3) begin
            if (frame_bit_count == 6'd32) begin
                i2s_ws <= 1'b1; // enter right-channel slot 
            end
            else if (frame_bit_count == 6'd0) begin
                i2s_ws <= 1'b0; // enter left-channel slot
            end
        end  
    end
end

endmodule

// we cant clock the adc till the power rails have settled