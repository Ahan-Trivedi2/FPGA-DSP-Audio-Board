// this is essentially a serializer

module i2s_transmitter (
    input logic clk, // system clock
    input logic i2s_ws, // word select from the fpga i2s clk generator
    output logic i2s_sd, // serial data sent to the stm
    input logic signed [31:0] sample_in, // input sample from the biquad
    input logic sample_valid,  // New processed sample is ready from the biquard
    input logic rst, // active high reset logic for registers
    input logic i2s_bit_enable // Pulse to advance to the next audio bit
);

logic [31:0] shift_reg; // loads a buffered sample and shifts it out
logic [31:0] sample_buffer; // captures incoming samples
logic [5:0] bit_count; 

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        shift_reg <= 32'd0;
        sample_buffer <= 32'd0;
        bit_count <= 6'd0; // when the fpga resets we want its bit counter to go back to 0
        i2s_sd <= 1'b0; // initializes serial data output to LOW when fpga resets
    end
    else begin
        if (sample_valid) begin // if we are not resetting, load in the sample to our buffer
            sample_buffer <= sample_in;
        end
        if (i2s_bit_enable) begin 
            // Update i2s_sd on the system-clock edge that causes BCLK to fall,
            // allowing data to settle before the next BCLK rising edge.
            // serialization logic here
            if (bit_count == 6'd0) begin 
                shift_reg <= sample_buffer;
            end
            // put the msb of our shift register on the trasnmitter output
            else if (bit_count >= 6'd1 && bit_count <= 6'd32) begin
                i2s_sd <= shift_reg[31];
                shift_reg <= {shift_reg[30:0], 1'b0};
            end
            // transmit zeros for our unused channel spot
            else if (bit_count >= 6'd33) begin
                i2s_sd <= 1'b0; // do we even need to send this audio packet...can our stm not just omit a channel
            end
            bit_count <= bit_count + 6'd1; // increment bit count 
        end
    end
end

endmodule