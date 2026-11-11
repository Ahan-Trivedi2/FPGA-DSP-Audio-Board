// This needs to only use one multiplier, currently it uses too many hardware resources
// Talk to Daniel about this

module biquad_filter (
    input logic clk, // 12.288MHz --> why does this work
    input logic rst, // Active-high synchronous reset
    input logic sample_valid, // High when new sample is ready
    input logic signed [31:0] x_in, // Signed 16-bit audio sample
    output logic signed [31:0] y_out, // reg for our 16 bit filtered output
    output logic output_valid, // reg set high to indicate that the transmitter can read y_out
    output logic input_ready // signal for the receiver to indicate pipelined system can an input
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

logic signed [31:0] x1; // Reg to store previous audio sample the difference equation uses
logic signed [31:0] x2; // Reg to store audio sample from two samples ago for the difference equation
logic signed [31:0] y1; // Reg for previous filter output
logic signed [31:0] y2; // Reg for filter output from two output cycles ago 

// Stage 1 output registers that store products for the summation stage
logic signed [63:0] product_b0;
logic signed [63:0] product_b1;
logic signed [63:0] product_b2;
logic signed [63:0] product_a1;
logic signed [63:0] product_a2;

// Multiplication complete, waiting for summation
logic mult_completed; 

// The mathematical sum of five signed 64-bit values could require three additional bits (chat told me this)
logic signed [66:0] accumulator; // comb signal for our difference equation output

logic signed [66:0] scaled_result; // comb signal for right shifted output of difference equation

logic signed [31:0] saturated_result;  

//=======================================================================================================
// 3. Combinational Logic
//=======================================================================================================
    
// This is all combinational logic that occurs in our summation circuit (stage 2)

// Implement the difference equation
assign accumulator = product_b0 + product_b1 + product_b2 - product_a1 - product_a2;

// combinational control signal that indicates if the biquad can accept a new sample 
assign input_ready = !mult_completed && !rst;

// Fixed-right arithmetic shift by 20 bits
assign scaled_result = accumulator >>> COEFF_FRAC_BITS;

// Combinational logic to clamp the signal if its too big
always_comb begin // i need to look more into this section
    if (scaled_result > 67'sd2147483647) begin 
        saturated_result = 32'sd2147483647;
    end 
    else if (scaled_result < -67'sd2147483648) begin
        saturated_result = 32'sh80000000; // most negative 32 bit number
    end 
    else begin
        saturated_result = scaled_result[31:0];
    end
end

//=======================================================================================================
// 4. Sequential Logic
//=======================================================================================================

always_ff @(posedge clk) begin 
    if (rst) begin // synchronous reset
        mult_completed <= 1'b0;
        y_out <= 32'sd0;
        output_valid <= 1'b0;
        x1 <= 32'sd0;
        x2 <= 32'sd0;
        y1 <= 32'sd0;
        y2 <= 32'sd0;
    end
    else if (mult_completed) begin
        // Stage 2: Capture the accumulated and saturated result
        y_out <= saturated_result;
        output_valid <= 1'b1;
        y1 <= saturated_result;
        y2 <= y1;
        mult_completed <= 1'b0; // reset for next sample
    end 
    else if (sample_valid) begin
        // Stage 1: Capture multiplication results in pipeline registers
        product_b0 <= b0 * x_in;
        product_b1 <= b1 * x1;
        product_b2 <= b2 * x2;
        product_a1 <= a1 * y1;
        product_a2 <= a2 * y2;
        mult_completed <= 1'b1; // after all multiplications get completed, we want to send stage 2 this control signal
        output_valid <= 1'b0;
        // ensure we update x1 and x2, so combinational changes to x_in don't impact our system
        x1 <= x_in;
        x2 <= x1;
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

// nonblocking assignment vs always_ff 
// i want to spend some more time visualizing this hardware
// why does the bit shift work...we increased precision, not numerical scaling when we shifted to this 32 bit implementation


// 11/24 8pm