module i2s_clock_gen (
    input logic clk, // system clk 12.288Mhz
    input logic rst, // resets clock generator to a known state
    
    output logic i2s_bclk, // physical bit clock sent to adc and stm32
    output logic i2s_ws, // signal for right or left channel select

    output logic i2s_sample_enable, // tells the receiver when to sample ADC data
    output logic frame_start, // tells the receiver when to reallign bit counter to the start of an ADC data frame
    output logic i2s_bit_enable, // Enables transmitter to update i2s_sd with the next serial bit
);

endmodule

// we cant clock the adc till the power rails have settled