// inputs into top --> clock from oscillator + serial data from ADC

// top uses the clock_generation to create timing signals...do we create fsync or how does this work
// question...do some of these generated signals go into other modules, and some go out into the board 
// into the adc or stm

// receiver takes in these timing signals and generates a sample_out and sample_valid that the filter takes in

// biquad takes in output signals from the receiver (sample_valid, x_in), outputs y_out and output_valid for transmitter, and
// outputs input_ready for the receiver

// transmitter

// clock_generation

// question...do we have a system-wide reset that resets all the modules

module top (
    input logic clk, // 12.288Mhz system clock
    input logic adc_sd, // Serial data from the ADC
    input logic rst, // System wide reset from the board user (active high)

    output logic i2s_bclk, // Bit clock send to ADC and STM
    output logic stm_sd, // Serial data going out to the stm
    output logic i2s_ws // Word select signal send to ADC and STM
);

logic i2s_bit_enable; // tells the I2S transmitter when to advance its serial output by one bit
logic i2s_sample_enable; // tells the I2S receiver when to sample the incoming ADC serial data
// i think i need a frame start signal

i2s_clock_gen clock_generation_circuit (
    .clk(clk),
    .rst(rst),
    .i2s_bclk(i2s_bclk),
    .i2s_ws(i2s_ws),
    .i2s_sample_enable(i2s_sample_enable),
    .i2s_bit_enable(i2s_bit_enable)
    // i think i need a frame start, i will add that later
);

i2s_receiver receiver_circuit (
    .clk(clk),
    .rst(rst),
    .fsync(i2s_ws),
    .i2s_sd(adc_sd),
    .i2s_sample_enable(i2s_sample_enable),
    // i need some frame_start signal

);

endmodule



// signal kind -- how a signal gets its value and how that value is maintained/updated -- net vs var

// vs data type -- logic vs bit

// vs assignment type -- procedural vs continuous