# zhoot
A simple arcade style mouse shooter made for the DE1-SoC FPGA. Final lab for UW CSE 371 Winter 2021.

<img src="https://i.imgur.com/ZziAUY2.png" alt="gameplay" width="480" height="320" />

# Overview
Mouse to aim, LMB to shoot. Up to 8 red enemies spawn at the top of the screen and move downwards. Game ends when an enemy touches the bottom of the screen. Enemies move faster over time. 

# Project breakdown
Most of my work is in the `assets/`, `scripts/` and `zhoot/` folder and involves just the game logic and graphics. The rest of the files were provided by the course as starter files, including the PS/2 mouse driver and VGA video driver. 

## System Block Diagram

Reset and clock signals not shown

<img src="https://i.imgur.com/MH5XvsC.png" alt="system block diagram" width="480" height="320" />

## Graphics
Images in `assets/` were ran through `scripts/image_to_SV_array.py` to convert them into 2D SystemVerilog arrays that were then inferred as block RAM during synthesis and then rendered using the VGA drier in `video/video_driver.sv` that constantly scans through, modifies and render each pixel in the 640x480 framebuffer. 

## SFX
A process similar to graphics is done for audio, using `scripts/mp3_to_mif.py` to store the raw audio samples to a ROM to be played by the onboard DAC.