module i2s_receiver (
    input logic clk, // FPGA system clock from the top module
    input logic fsync, // word select to denote left/right channel
    input logic i2s_sd, // data coming in from the i2s ADC
    input logic i2s_sample_enable, // enable signal for when to capture next bit from ADC
    input logic rst,
    output logic signed [31:0] sample_out, // data ready for the biquad filter
    output logic sample_valid // control signal for the biquad module
);

// shift register
logic [31:0] shift_reg;

// bit counter to store how many of the adc bits we've received
logic [5:0] bit_count;

// register to store the previous fsync value in order to be able to decipher the falling edge
logic prev_fsync;

// sequential logic
always_ff @(posedge clk or posedge rst) begin 
    // CONDITION 1: RESET
    if (rst) begin
    shift_reg <= 32'd0;
    bit_count <= 6'd0;
    sample_out <= 32'd0;
    sample_valid <= 1'd0;
    prev_fsync <= 1'b0;
    end

    else begin
        sample_valid <= 1'b0;
        
        // CONDITION 2: Is it time to process another I2S bit?
        if (i2s_sample_enable) begin
            // Remember fsync for the next sampling event
            prev_fsync <= fsync;

            // CONDITION 3: Did WS transition HIGH to LOW?
            if (prev_fsync && !fsync) begin
                bit_count <= 6'b1;
            end

            // Otherwise, continue receiving bits
            else begin
                bit_count <= bit_count + 6'd1;

                if (bit_count >= 6'd1 && bit_count <= 6'd31) begin
                    shift_reg <= {shift_reg[30:0], i2s_sd};
                end

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
