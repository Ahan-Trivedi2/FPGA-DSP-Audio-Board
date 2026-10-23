module biquad_filter (
    input logic clk,
    input logic rst, // Active-high synchronous reset
    input logic sample_valid, // Check if our i2s receiver has decoded the sample and it is ready to use
    input logic signed [15:0] x_in, // Let's assume our digital audio sample is a a signed 16 bit number
    output logic signed [15:0] y_out, // Assumed 16 bit digital filtered output
    output logic output_valid // 
); 

