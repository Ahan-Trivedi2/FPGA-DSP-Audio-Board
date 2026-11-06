module i2s_receiver (
    input logic clk, // FPGA system clock from the top module
    input logic fsync, // word select to denote left/right channel
    input logic i2s_sd, // data coming in from the i2s ADC
    input logic i2s_sample_enable, // enable signal for when to capture next bit from ADC
    input logic frame_start, // Indicates the begining of a new i2s frame
    input logic rst,
    output logic signed [31:0] sample_out, // data ready for the biquad filter
    output logic sample_valid // control signal for the biquad module
);

// shift register
logic [31:0] shift_reg;

// bit counter to store how many of the adc bits we've received
logic [5:0] bit_count;

// sequential logic
always_ff @(posedge clk or posedge rst) begin 
    // address reset logic
    if (rst) begin
    shift_reg <= 32'd0;
    bit_count <= 6'd0;
    sample_out <= 32'd0;
    sample_valid <= 1'd0;
    end
    else begin
        if (frame_start) begin
            bit_count <= 1'b0;
        end
        sample_valid <= 1'b0;
        else if (i2s_sample_enable) begin
            bit_count <= bit_count + 6'd1; // incrementing bit count to stay in sync with data
            if (bit_count >= 6'd1 && bit_count <= 6'd32) begin
                shift_reg <= {shift_reg[30:0], i2s_sd};
            if (bit_count == 6'd32) begin
                sample_out <= {shift_reg[30:0], i2s_sd};
                sample_valid <= 1'b1;
            end
            end
        end
    end
end

endmodule


// go over the i2s counting convention...   
// i need some logic to make sure im working with the begining of the fsynch line...
