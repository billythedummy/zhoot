'''*******************************************************************************
    Authors:         Original by Haytham Shaban, Sam Waddell. Modified by billythedummy
    ------------------------------------------------------------------------
    Project:        image_to_SV_array.py
    ------------------------------------------------------------------------
    Description:    Image to Array Script that takes in an image, and produces the verilog assignments required to produce the same image on a VGA display.
    ------------------------------------------------------------------------
*******************************************************************************'''

from PIL import Image
import re
import argparse

def img2array(name, mode, array_name):
    if mode < 0 or mode > 1:
        print("Invalid mode only [0-1] allowed")
        return

    img = Image.open(name, 'r')
    width, height = img.size
    pixelCount = width*height
    data = list(img.getdata())
    #print(data);
        
    for i in range(pixelCount):  
        if(i % width == 0):
            if(i != 0):
                print("};")
            print(array_name + "[%d] = " % (i/width), end =" "), ####### Change "array" to whatever name you want for the logic that will be assigned.
            print("{", end =" "),
        
        val = 1
        if mode == 0 and data[i][0] == 0 and data[i][1] == 0 and data[i][2] == 0:
            val = 0
        elif mode == 1 and data[i][0] == 255 and data[i][1] == 255 and data[i][2] == 255:
            val = 0

        if(i % width == width-1):
            print("1'b" + str(val), end =" ")
        else:
            print("1'b" + str(val)+ ",", end =" "),
    print("};")
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Converts an image to a SystemVerilog Array')
    parser.add_argument('file', metavar='file', type=str,
        help='file to convert')
    parser.add_argument('--mode', metavar='mode', type=int, default=0, required=False,
        help='`0`: black (0, 0, 0) = 0, anything else = 1. `1`: white (255, 255, 255) = 0, anything else = 1')
    parser.add_argument('--array_name', metavar='array_name', type=str, default='array', required=False,
        help='name of sv array to assign to')
    
    args = parser.parse_args()
    img2array(args.file, args.mode, args.array_name)
