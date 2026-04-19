import math
import csv

# Parametry

num_samples = 500
#num_periods = 4

# Plik wyjściowy

filename = "/path/input_data.csv"

samples = []

for n in range(num_samples):
    # phase: 0 → 4*2π
    phase1 = 2 * math.pi * 2 * n / num_samples
    phase2 = 2 * math.pi * 100 * n / num_samples

    # sinus range [-1, 1]
    value = (math.sin(phase1) )#+ 0.2*math.sin(phase2))/1.2

    # scaled down to int8 (-128..127)
    scaled_int = int(round(value * 127))
    #formatted as a 8 bit binary
    scaled = format(scaled_int & 0xFF, '08b')

    samples.append(scaled)


# save to csv

with open(filename, mode='w', newline='') as file:
    writer = csv.writer(file)


    for s in samples:
        writer.writerow([s])


print(f"Saved {num_samples} samples to file {filename}")
