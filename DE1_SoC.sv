import enemy_def::*;

module DE1_SoC (
	HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW,
	CLOCK_50, VGA_R, VGA_G, VGA_B, VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS,
	PS2_CLK, PS2_DAT,
	CLOCK2_50, FPGA_I2C_SCLK, FPGA_I2C_SDAT, AUD_XCK, AUD_DACLRCK, 
	AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, AUD_DACDAT
);
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
	input logic [3:0] KEY;
	input logic [9:0] SW;

	input CLOCK_50;
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_BLANK_N;
	output VGA_CLK;
	output VGA_HS;
	output VGA_SYNC_N;
	output VGA_VS;
	
	inout PS2_CLK;
	inout PS2_DAT;

	input CLOCK2_50;
	output FPGA_I2C_SCLK;
	inout FPGA_I2C_SDAT;
	output AUD_XCK;
	input AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK;
	input AUD_ADCDAT;
	output AUD_DACDAT;

	logic reset;
	logic render;
	logic re, rc;
	logic [9:0] x;
	logic [8:0] y;
	logic [7:0] r, g, b;
	
	video_driver #(.WIDTH(640), .HEIGHT(480))
		v1 (.CLOCK_50, .reset, .x, .y, .r, .g, .b,
			 .VGA_R, .VGA_G, .VGA_B, .VGA_BLANK_N,
			 .VGA_CLK, .VGA_HS, .VGA_SYNC_N, .VGA_VS);

	enemy_render er (.clk(CLOCK_50), .x, .y, .state(ALIVE), .x_me(10'd100), .y_me(9'd50), .render(re));
	
	wire button_left, button_right, button_middle;
	wire [5:0] bin_x, bin_y;
	ps2 #(.WIDTH(64), .HEIGHT(48), .BIN(10), .HYSTERESIS(3)) mouse (
		.start(~KEY[0]), .reset, .CLOCK_50, .PS2_CLK, .PS2_DAT,
		.button_left, .button_right, .button_middle,
		.bin_x, .bin_y
	);
	logic [9:0] mouse_x;
	assign mouse_x = 10'(bin_x * 10 - 32);
	logic [8:0] mouse_y; 
	assign mouse_y = 9'(bin_y * 10 - 32);
	crosshair_render cr (.clk(CLOCK_50), .x, .y, .x_me(mouse_x), .y_me(mouse_y), .render(rc));

	// AUDIO
	clock_generator aud_clock_gen (
		CLOCK2_50,
		reset,
		AUD_XCK
	);

	audio_and_video_config cfg(
		CLOCK_50,
		reset,
		FPGA_I2C_SDAT,
		FPGA_I2C_SCLK
	);

	wire aud_write;
	wire [23:0] aud_write_d;
	wire aud_write_ready;
	audio_codec codec(
		.clk(CLOCK_50),
		.reset,
		.read(1'b0),	
		.write(aud_write),
		.writedata_left(aud_write_d), 
		.writedata_right(aud_write_d),
		.AUD_ADCDAT,
		.AUD_BCLK,
		.AUD_ADCLRCK,
		.AUD_DACLRCK,
		.read_ready(), .write_ready(aud_write_ready),
		.readdata_left(), .readdata_right(),
		.AUD_DACDAT
	);

	gunshot_player gp (.clk(CLOCK_50), .reset, .shot(button_left), .aud_write_ready, .aud_write, .aud_write_d);
	
	// FINAL RENDER OR
	assign render = rc | re;
	assign r = render ? 8'd255 : 8'd0;
	assign g = rc ? 8'd255 : 8'd0;
	assign b = g;
	
	assign HEX0 = '1;
	assign HEX1 = '1;
	assign HEX2 = '1;
	assign HEX3 = '1;
	assign HEX4 = '1;
	assign HEX5 = '1;
	assign reset = SW[9];

	assign LEDR[0] = button_left;
	assign LEDR[9] = reset;
endmodule
