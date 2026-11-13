module top (
    input logic clk, // 12.288Mhz system clock
    input logic adc_sd, // Serial data from the ADC
    input logic rst, // System wide reset from the board user (active high)

    output logic i2s_bclk, // Bit clock send to ADC and STM
    output logic stm_sd, // Serial data going out to the stm
    output logic i2s_ws // Word select signal send to ADC and STM
);

// Internal routing signals
// Your top module currently has no power-good or startup sequencing logic. That isn't necessarily a problem,
logic i2s_bit_enable; // tells the I2S transmitter when to advance its serial output by one bit
logic i2s_sample_enable; // tells the I2S receiver when to sample the incoming ADC serial data
logic [31:0] sampled_data; // 32 bits of data going from receiver to filter
logic sample_valid; // enable signal from the receiver to the biquad (High when sample is ready)
logic [31:0] processed_data; // data leaving the biquad filter into the transmitter
logic processed_output_valid; // signal to indicate the transmitter can capture filtered data

i2s_clock_gen clock_generation_circuit (
    .clk(clk),
    .rst(rst),
    .i2s_bclk(i2s_bclk),
    .i2s_ws(i2s_ws),
    .i2s_sample_enable(i2s_sample_enable),
    .i2s_bit_enable(i2s_bit_enable)
);

i2s_receiver receiver_circuit (
    .clk(clk),
    .rst(rst),
    .fsync(i2s_ws),
    .i2s_sd(adc_sd),
    .i2s_sample_enable(i2s_sample_enable),
    .sample_out(sampled_data),
    .sample_valid(sample_valid)
);

biquad_filter biquad_filter (
    .clk(clk),
    .rst(rst),
    .sample_valid(sample_valid),
    .x_in(sampled_data),
    .y_out(processed_data),
    .output_valid(processed_output_valid)
);

i2s_transmitter transmitter_circuit (
    .clk(clk),
    .rst(rst),
    .i2s_ws(i2s_ws),
    .i2s_sd(stm_sd),
    .sample_in(processed_data),
    .sample_valid(processed_output_valid),
    .i2s_bit_enable(i2s_bit_enable)
);

endmodule



// signal kind -- how a signal gets its value and how that value is maintained/updated -- net vs var

// vs data type -- logic vs bit

// vs assignment type -- procedural vs continuous