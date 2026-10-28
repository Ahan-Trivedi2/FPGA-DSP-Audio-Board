module biquad_filter (
    input logic clk,
    input logic rst, // Active-high synchronous reset
    input logic sample_valid, // High when new sample is ready
    input logic signed [15:0] x_in, // Signed 16-bit audio sample
    output logic signed [15:0] y_out, // reg for our 16 bit filtered output
    output logic output_valid // reg set high to indicate that the transmitter can read y_out
); 

//=======================================================================================================
// 1. Parameters
//=======================================================================================================
localparam int COEFF_FRAC_BITS = 20; // number of fractional bits for the fixed point arithmetic

//Biquad filter coefficients (signed 32 bit Q12.20 fixed-point)
// Coefficients are fixed at synthesis time and scaled by 2^20
parameter signed [31:0] b0 = 32'sd31410; // Current input coefficient
parameter signed [31:0] b1 = 32'sd62819; // Previous input coefficient
parameter signed [31:0] b2 = 32'sd31410; // Input coefficient from two samples ago
parameter signed [31:0] a1 = 32'sd1524885; // Previous output feedback coefficient
parameter signed [31:0] a2 = 32'sd601948; // Output feedback coefficient from two samples ago

//=======================================================================================================
// 2. Internal Signal Declarations
//=======================================================================================================
logic signed [15:0] x1; // Reg to store previous audio sample the difference equation uses
logic signed [15:0] x2; // Reg to store audio sample from two samples ago for the difference equation
logic signed [15:0] y1; // Reg for previous filter output
logic signed [15:0] y2; // Reg for filter output from two output cycles ago 

logic signed [47:0] product_b0; // comb signal for the first multiplier output
logic signed [47:0] product_b1; // comb signal for the second multiplier output
logic signed [47:0] product_b2; // comb signal for the third multiplier output
logic signed [47:0] product_a1; // comb signal for the fourth multiplier output
logic signed [47:0] product_a2; // comb signal for the fifth multiplier output

// Five signed 48-bit terms can require up to 51 bits to represent their mathematical sum without overflow (chat told me this...)
logic signed [50:0] accumulator; // comb signal for our difference equation output

logic signed [50:0] scaled_result; // comb signal for right shifted output of difference equation

logic signed [15:0] saturated_result; 

//=======================================================================================================
// 3. Combinational Logic
//=======================================================================================================

// Five parallel multipliers representing difference equation products
assign product_b0 = b0 * x_in;
assign product_b1 = b1 * x1;
assign product_b2 = b2 * x2;
assign product_a1 = a1 * y1;
assign product_a2 = a2 * y2;

// Implement the difference equation
assign accumulator = product_b0 + product_b1 + product_b2 - product_a1 - product_a2;

// Fixed-right arithmetic shift by 20 bits
assign scaled_result = accumulator >>> COEFF_FRAC_BITS;

// Combinational logic to clamp the signal if its too big
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

//=======================================================================================================
// 4. Sequential Logic
//=======================================================================================================
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
        output_valid <= 1'b0; // This ensures we set the output_valid reg back to 0
    end
end
endmodule

// Notes from Joe
// Block diagram to show how we can have multiple implementations compensator
// parallel path implementation
// compensator
// bit padding for signal paths..did you do this...fixed point arithmetic, right padding
// block diagram implementation of the circuit
// we can obtain the same transfer function through two different block diagram
// block diagram manipulation
// 

// 11/24 8pm