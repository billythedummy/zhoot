from pydub import AudioSegment
import argparse

def mp3tomif(audio_file, n_samples):
    f = AudioSegment.from_file(audio_file)
    data = f._data
    n_samples = n_samples if n_samples > 0 else len(data) 

    print("WIDTH=24;")
    print(f"DEPTH={n_samples};")
    print()
    print("ADDRESS_RADIX=UNS;")
    print("DATA_RADIX=UNS;")
    print()
    print("CONTENT BEGIN")
    for i in range(n_samples):
        sample = int.from_bytes(data[i*2:i*2+2], 'little', signed=True)
        unsigned = sample if sample >= 0 else sample + 2**24
        print(f"\t{i} : {unsigned};")
    print("END;")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Converts an mp3 file to a mif of raw 24-bit samples')
    parser.add_argument('file', metavar='file', type=str,
        help='file to convert')
    parser.add_argument('--n_samples', metavar='n_samples', type=int, required=False, default=0,
        help='file to convert')
    
    args = parser.parse_args()
    mp3tomif(args.file, args.n_samples)
