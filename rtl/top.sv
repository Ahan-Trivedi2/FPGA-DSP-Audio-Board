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