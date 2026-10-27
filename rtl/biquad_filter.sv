module biquad_filter (
    input logic clk,
    input logic rst, // Active-high synchronous reset
    input logic sample_valid, // Check if our i2s receiver has decoded the sample and it is ready to use
    input logic signed [15:0] x_in, // Let's assume our digital audio sample is a a signed 16 bit number
    output logic signed [15:0] y_out, // Assumed 16 bit digital filtered output
    output logic output_valid // Signal to send to transmitter to denote filtered data is ready to be transmitted
); 

logic signed [15:0] x1; // Register to store previous audio sample the difference equation uses
logic signed [15:0] x2; // Register to store audio sample from two samples ago for the difference equation
logic signed [15:0] y1; // previous filter output
logic signed [15:0] y2; // filter output from two output cycles ago 
localparam int COEFF_FRAC_BITS = 20; // number of fractional bits for the fixed point arithmetic

//Biquad filter coefficients (signed 32 bit Q12.20 fixed-point)
// Coefficients are fixed at synthesis time and scaled by 2^20
parameter signed [31:0] b0 = 32'sd1048576; // Current input coefficient
parameter signed [31:0] b1 = 32'sd1048576; // Previous input coefficient
parameter signed [31:0] b2 = 32'sd1048576; // Input coefficient from two samples ago
parameter signed [31:0] a1 = 32'sd1048576; // Previous output feedback coefficient
parameter signed [31:0] a2 = 32'sd1048576; // Output feedback coefficient from two samples ago

logic signed [47:0] product_b0;
logic signed [47:0] product_b1;
logic signed [47:0] product_b2;
logic signed [47:0] product_a1;
logic signed [47:0] product_a2;

// Calculate the five products in parallel
assign product_b0 = b0 * x_in;
assign product_b1 = b1 * x1;
assign product_b2 = b2 * x2;
assign product_a1 = a1 * y1;
assign product_a2 = a2 * y2;

// Five signed 48-bit terms can require up to 51 bits to represent their mathematical sum without overflow (chat told me this...)
logic signed [50:0] accumulator;

// Implement the difference equation
assign accumulator = product_b0 + product_b1 + product_b2 - product_a1 - product_a2;
logic signed [50:0] scaled_result;
// fixed-right arithmetic shift by 20 bits
assign scaled_result = accumulator >>> COEFF_FRAC_BITS;

// turn this signal into 16 bits..saturation
logic signed [15:0] saturated_result; 
always_comb begin
    if (scaled_result > 51'sd32767) begin 
        saturated_result = 16'sd32767;
    end 
    else if (scaled_result < -51'sd32768) begin
        saturated_result = -16'sd32768; // I need to look more at why clamping low causes this effect
    end 
    else begin
        saturated_result = scaled_result[15:0];
    end
end

// store this in y_out...sequential
// set output_valid high...sequential
always_ff @(posedge clk) begin 
    if (rst) begin // synchronous reset
        y_out <= 16'sd0;
        output_valid <= 1'b0;
        x1 <= 16'sd0;
        x2 <= 16'sd0;
        y1 <= 16'sd0;
        y2 <= 16'sd0;
    end
    else if (sample_valid) begin
        y_out <= saturated_result;
        output_valid <= 1'b1;
        x1 <= x_in;
        x2 <= x1;
        y1 <= saturated_result;
        y2 <= y1;
    end 
    else begin
        output_valid <= 1'b0;
    end
end

endmodule

