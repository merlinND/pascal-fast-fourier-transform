program fft;
Uses Math, sysutils;

Type SArray = Array of String;
Type RArray = Array of Real;

//--------------------------------------------------
//-- COMPLEX NUMBERS HANDLING ----------------------
type Complex = Array [0..1] of Real;
type CArray = Array of Complex;
	
function multiply(c1, c2 : Complex) : Complex;
var prod : Complex;
begin
	prod[0] := c1[0] * c2[0] - c1[1] * c2[1];
	prod[1] := c1[0] * c2[1] + c1[1] * c2[0];
	multiply:= prod;
end;
function add(c1,c2 : Complex):Complex;
var sum : Complex;
begin
	sum[0] := c1[0] + c2[0];
	sum[1] := c1[1] + c2[1];
	add := sum;
end;
function substract(c1,c2 : Complex):Complex;
var sum : Complex;
begin
	sum[0] := c1[0] - c2[0];
	sum[1] := c1[1] - c2[1];
	substract := sum;
end;
function conjugate(c1 : Complex):Complex;
var conj : Complex;
begin
	conj[0] := c1[0];
	conj[1] := - c1[1];
	conjugate := conj;
end;
function conjugateArray(c1 : CArray):CArray;
var conjArray : CArray;
	i, n : Integer;
begin
	n := length(c1);
	SetLength(conjArray, n);

	for i:=0 to n - 1 do
	begin
		conjArray[i][0] := c1[i][0];
		conjArray[i][1] := - c1[i][1];
	end;


	conjugateArray := conjArray;
end;
//--------------------------------------------------



//--------------------------------------------------
//-- INPUT DATA HANDLING ---------------------------
// Split a string to an array using the given separator
function occurs(const str, separator: string):integer; 
var i, nSep:integer; 
begin 
	nSep:= 0; 
		for i:= 1 to Length(str) do 
			if str[i] = separator then Inc(nSep); 
	occurs:= nSep; 
end; 

procedure split(const str: String; const separator: String; var Result:SArray; var numberOfItems:Integer);
var i, n: Integer; 
	strline, strfield: String; 
begin 
	n := occurs(str, separator); 
	SetLength(Result, n + 1); 
	i := 0; 
	strline := str; 
	
	repeat 
		if Pos(separator, strline) > 0 then 
		begin 
			strfield := Copy(strline, 1, Pos(separator, strline) - 1); 
			strline := Copy(strline, Pos(separator, strline) + 1, 
							Length(strline) - pos(separator,strline)); 
		end 
		else 
		begin 
			strfield:= strline; 
			strline:= ''; 
		end; 

		Result[i]:= strfield; 
		Inc(i); 
	until strline= ''; 
	
	if Result[High(Result)] = '' then 
		SetLength(Result, Length(Result) - 1);

	numberOfItems := i;
end;

// Read the given string and convert it to a vector of complex numbers
procedure processInput(var result:CArray; var dimension:Integer);
var inputFile:TextFile;
	input:String;
	stringArray:SArray;
	complexNumber:Complex;
	numberInLine:Integer;
begin
	numberInLine := 0;
	dimension := 0;

	//readln(input);
	// Read line by line
	assign(inputFile, 'source.d');
	reset(inputFile); // Put pointer at the beginning of the file
	repeat // For each line
		readln(inputFile, input);

		dimension := dimension + 1;
		SetLength(result, dimension);

		// Split real and imaginary part (using ',' separator)
		split(input, ',', stringArray, numberInLine);
		complexNumber[0] := StrToFloat(stringArray[0]);
		complexNumber[1] := StrToFloat(stringArray[1]);
		
		// Add this number to output
		result[dimension-1] := complexNumber;

	until(EOF(inputFile));
	close(inputFile);
end;
//--------------------------------------------------


//--------------------------------------------------
//-- DATA DIMENSION DETECTION ----------------------
// Read the value of a bit from any variable
function getBit(const Val: DWord; const BitVal: Byte): Boolean;
begin
	getBit := (Val and (1 shl BitVal)) <> 0;
end;
// Set the value of a bit in any variable
function enableBit(const Val: DWord; const BitVal: Byte; const SetOn: Boolean): DWord;
begin
	enableBit := (Val or (1 shl BitVal)) xor (Integer(not SetOn) shl BitVal);
end;
// Determine wether a number is a power of two
procedure isPowerOfTwo(n:Integer; var result:Boolean; var power:Integer);
var bitCounter:Integer;
	keepIncrementingPower:Boolean;
begin
	bitCounter := 0;
	keepIncrementingPower := true;
	power := 0;

	// n is a power of two <=> it has only one bit set to 1
	while (n > 0) do
	begin
		if ((n and 1) = 1) then
		begin
			Inc(bitCounter);
			keepIncrementingPower := false;
		end;
		n := n >> 1; // Bitwise shift
		if (keepIncrementingPower) then
			Inc(power);
	end;
	result := (bitCounter = 1);
end;
//--------------------------------------------------


//--------------------------------------------------
//-- MIRROR PERMUTATION ----------------------------
function mirrorTransform(n,m:Integer):Integer;
var i,p : Integer;
begin
	p := 0;

	for i:=0 to m-1 do
	begin
		p := enableBit(p, m-1-i, getBit(n, i));
	end;

	mirrorTransform:=p;
end;

function doPermutation(source:CArray; m:Integer):CArray;
var i, n : Integer;
	result : CArray;
begin
	n := length(source);
	SetLength(result, n);

	for i:=0 to n-1 do
	begin
		result[i] := source[mirrorTransform(i, m)];
	end;

	doPermutation := result;
end;
//--------------------------------------------------



//--------------------------------------------------
//-- FFT COMPUTATION STEP --------------------------
function doStep(k, M : Longint; prev:CArray):CArray;
var expTerm, substractTerm : Complex;
	dimension, q, j, offset : Longint;
	u : CArray;
begin
	// INITIALIzATION
	//offset = 2^(M-k)
	offset := system.round(intpower(2, M-k));

	SetLength(u, length(prev));

	// COMPUTE EACH COORDINATE OF u_k
	for q:=0 to system.round(intpower(2, k-1) - 1) do
	begin // For each block of the matrix

		for j:=0 to (offset - 1) do
		begin // Fo each line of this block

			// First half
			u[q*2*offset + j] := add( prev[q*2*offset + j], prev[q*2*offset + j + offset] );

			// Second half
			expTerm[0] := cos( (j * PI) / offset );
			expTerm[1] := sin( (j * PI) / offset );
			substractTerm := substract( prev[q*2*offset + j], prev[q*2*offset + j + offset] );
			u[q*2*offset + j + offset] := multiply(expTerm, substractTerm);
		end;

	end;
	
	// Output result
	doStep := u;
end;

// DISCRETE FOURIER TRANSFORM USING COOLEY-TUKEY'S FFT ALGORITHM
function fft(g:CArray; order:Integer):CArray;
var previousRank, nextRank : CArray;
	i : Integer;
begin

	previousRank := g;
	for i:=1 to order do
	begin
		nextRank := doStep(i, order, previousRank);
		previousRank := nextRank;
	end;

	// Mirror transform
	nextRank := doPermutation(nextRank, order);

	fft := nextRank;
end;
// INVERSE FOURIER TRANSFORM
function ifft(G:CArray; order:Integer):CArray;
var result : CArray;
	i, n : Longint;
begin
	n := length(G);
	SetLength(result, n);

	//La transformée inverse est le conjugué de la transformée du conjugué
	result := fft(conjugateArray(G), order);
	result := conjugateArray(result);
	//...ajustée par un facteur 1/n
	for i := 0 to n - 1 do
	begin
		result[i][0] := result[i][0] / n;
		result[i][1] := result[i][1] / n;
	end;

	ifft := result;
end;
//--------------------------------------------------


//--------------------------------------------------
//-- RESULT OUTPUT ---------------------------------
procedure writeResult(result : CArray);
var i, dimension : Integer;
begin
	dimension := length(result);

	for i := 0 to dimension - 1 do
	begin
		write(result[i][0]:2:5);
		write('    +    ');
		write(result[i][1]:2:5);
		writeln(' I');
	end;
end;
// Output one complex number per line using the format:
// real part, imaginary part
procedure saveResult(result : CArray);
var i, dimension : Integer;
	outputFile : TextFile;
begin
	dimension := length(result);

	// Open output file
	assign(outputFile, 'result.d');
	rewrite(outputFile);

	// Write each complex number to a new line
	for i := 0 to dimension - 1 do
	begin
		write(outputFile, result[i][0]);
		write(outputFile, ', ');
		writeln(outputFile, result[i][1]);
	end;

	close(outputFile);
end;
//--------------------------------------------------




//--------------------------------------------------
//-- MAIN ------------------------------------------
var received, result, guessedData : CArray;
	n, m : Integer;
	isAcceptable : Boolean;
begin
	n := 0; m := 0;
	isAcceptable := false;
	
	// READ INPUT DATA
	processInput(received, n);
	
	// Dimension detection: only accept powers of 2
	isPowerOfTwo(n, isAcceptable, m);
	if isAcceptable then
	begin // Acceptable dimension
		write('The given vector is of dimension : 2^');
		writeln(m);
		//La dimension de g nous donne M
		write('We thus have M=');
		writeln(m);

		// APPLY TRANSFORM
		result := fft(received, m);

		// PRINT RESULT
		writeln('Transformed result:');
		writeResult(result);

		// DEMO: find back the original vector using inverse tranform
		writeln('We find back the original vector using the inverse transform:');
		guessedData := ifft(result, m);
		writeResult(guessedData);

		// WRITE RESULT TO result.d
		saveResult(result);

	end
	else // Dimension is not acceptable
	begin
		writeln('The given vector doesn''t have a dimension of  2^M.');
	end;
end.
//--------------------------------------------------