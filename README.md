# Cooley & Tuckey FFT (Pascal Implementation)
A pascal implementation of the Fast Fourier Transform algorithm.

### About
This code was written in the context of a Math project at INSA Rouen, France. The purpose was to discover the Fourier Transform, its applications and a numerical way to compute it efficiently. Please excuse the comments in French.

_Credit_: Includes contributions from Manon Ansart.

## Usage
`pascal-fft` reads the input from the `source.d` and write the ouput result in `result.d`.
`source.d` should contain the signal of which you want to compute the Discrete Fourier Transform. It must have one sample per line, formatted as follows:
	realPart, imaginaryPart
	realPart, imaginaryPart
	realPart, imaginaryPart
Example:
	1, 0
	2, 0
	3, 0
	4, 0
The result is written in `result.d` using this same convention. They can then easily be imported as space-separated values in any other program.
Example:
	 1.00000000000000E+001,  0.00000000000000E+000
	-2.00000000000000E+000, -2.00000000000000E+000
	-2.00000000000000E+000,  0.00000000000000E+000
	-2.00000000000000E+000,  2.00000000000000E+000

Sample `source.d` and `result.d` files are included as examples.

## Project report
Much more detailed explanations of both the algorithm and the code are included in the project report. Unfortunately, there is only a French version for now.
This report was written by Manon Ansart, Daming Li, Merlin Nimier-David and Pei Wang in LaTeX.