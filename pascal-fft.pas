program fft;
Uses Math, sysutils;

Type SArray = Array of String;
Type RArray = Array of Real;

//--------------------------------------------------
//-- GESTION DES COMPLEXES -------------------------
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
//-- TRAITEMENT DES DONNÉES D'ENTRÉE ---------------
//Sert à découper une chaîne en tableau selon un séparateur
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

//Lit la chaîne reçue et la transforme en vecteur de flottants double précision
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
	//On lit le fichier ligne par ligne
	assign(inputFile, 'source.d');
	reset(inputFile); //On met le pointeur au début du fichier
	repeat //Pour chaque ligne
		readln(inputFile, input);

		//On a une ligne de coordonnées en plus : on augmente la dimension
		dimension := dimension + 1;
		SetLength(result, dimension);

		//On sépare la partie réelle de la partie imaginaire, on forme un complexe avec
		split(input, ',', stringArray, numberInLine);
		complexNumber[0] := StrToFloat(stringArray[0]);
		complexNumber[1] := StrToFloat(stringArray[1]);
		
		//On écrit le résultat dans le vecteur de sortie
		result[dimension-1] := complexNumber;

	until(EOF(inputFile)); // On continue de lire tant que l'on n'arrive pas au bout du fichier
	close(inputFile); //On ferme le fichier
end;
//--------------------------------------------------


//--------------------------------------------------
//-- DÉTECTION DE LA DIMENSION DU VECTEUR DONNÉ ---
//Sert à récupérer la valeur d'un bit au sein de n'importe quelle variable
function getBit(const Val: DWord; const BitVal: Byte): Boolean;
begin
	getBit := (Val and (1 shl BitVal)) <> 0;
end;
//Sert à affecter la valeur d'un bit
function enableBit(const Val: DWord; const BitVal: Byte; const SetOn: Boolean): DWord;
begin
	enableBit := (Val or (1 shl BitVal)) xor (Integer(not SetOn) shl BitVal);
end;
//Sert à savoir si un nombre est une puissance de deux
procedure isPowerOfTwo(n:Integer; var result:Boolean; var power:Integer);
var bitCounter:Integer;
	keepIncrementingPower:Boolean;
begin
	bitCounter := 0;
	keepIncrementingPower := true;
	power := 0;

	while (n > 0) do //La boucle prendra fin lorsque n finit par devenir 0
	begin
		if ((n and 1) = 1) then
		begin
			Inc(bitCounter);
			keepIncrementingPower := false;
		end;
		n := n >> 1; //On shift n vers la droite
		if (keepIncrementingPower) then
			Inc(power);
	end;
	//Le nombre est une puissance de 2 si et seulement si il n'a qu'un bit à 1
	result := (bitCounter = 1);
end;
//--------------------------------------------------


//--------------------------------------------------
//-- PERMUTATION MIROIR ----------------------------
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
//-- LA RÉCURRENCE ---------------------------------
function doStep(k, M : Longint; prev:CArray):CArray;
var expTerm, substractTerm : Complex;
	dimension, q, j, offset : Longint;
	u : CArray;
begin
	//INITIALISATION
	//offset = 2^(M-k)
	offset := system.round(intpower(2, M-k));

	//On donne la bonne dimension au vecteur résultat u_k
	SetLength(u, length(prev));

	//CALCUL DE CHAQUE COORDONNÉE DE u_k
	for q:=0 to system.round(intpower(2, k-1) - 1) do
	begin //Pour chaque bloc

		for j:=0 to (offset - 1) do
		begin //Pour chaque ligne dans ce bloc

			//Dans la première moitié
			u[q*2*offset + j] := add( prev[q*2*offset + j], prev[q*2*offset + j + offset] );

			//Dans la deuxième moitié
			expTerm[0] := cos( (j * PI) / offset );
			expTerm[1] := sin( (j * PI) / offset );
			substractTerm := substract( prev[q*2*offset + j], prev[q*2*offset + j + offset] );
			u[q*2*offset + j + offset] := multiply(expTerm, substractTerm);
		end;

	end;
	

	//On renvoie le résultat
	doStep := u;
end;
//TRANSFORMÉE DE FOURIER DISCRÈTE PAR L'ALGORITHME FFT
function fft(g:CArray; order:Integer):CArray;
var previousRank, nextRank : CArray;
	i : Integer;
begin

	previousRank := g;
	for i:=1 to order do
	begin //La récurrence
		nextRank := doStep(i, order, previousRank);
		previousRank := nextRank;
	end;

	//Transformation miroir
	nextRank := doPermutation(nextRank, order);

	fft := nextRank;
end;
//TRANSFORMÉE DE FOURIER DISCRÈTE INVERSE
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
//-- AFFICHAGE DU RÉSULTAT -------------------------
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
procedure saveResult(result : CArray);
var i, dimension : Integer;
	outputFile : TextFile;
begin
	dimension := length(result);

	//Ouverture du fichier
	assign(outputFile, 'result.d');
	rewrite(outputFile);

	//Écriture ligne par ligne
	//au format : partie réelle, partie imaginaire
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
	
	//RÉCEPTION DES DONNÉES
	processInput(received, n);
	
	//On détecte si la dimension donnée est acceptable
	isPowerOfTwo(n, isAcceptable, m);
	if isAcceptable then
	begin //La dimension du vecteur est acceptable
		write('Le vecteur donné est de dimension : 2^');
		writeln(m);
		//La dimension de g nous donne M
		write('On a donc un cas M=');
		writeln(m);

		//APPLICATION DE LA TRANSFORMÉE AU VECTEUR DONNÉ
		result := fft(received, m);

		//AFFICHAGE DU RÉSULTAT
		writeln('Vecteur transformé :');
		writeResult(result);

		//ON RETROUVE LE VECTEUR INITIAL AVEC LA IDFT
		writeln('En calculant la transformée inverse, on retrouve le vecteur initial :');
		guessedData := ifft(result, m);
		writeResult(guessedData);

		//ENREGISTREMENT DU VECTEUR TRANSFORMÉ DANS result.d
		saveResult(result);

	end
	else //La dimension n'est pas acceptable
	begin
		writeln('Le vecteur donné n''a pas une dimension de la forme 2^M.');
	end;
end.
//--------------------------------------------------