xquery version '1.0-ml';

module namespace hashing = "/hashing";

declare variable $BIT32AND := 4294967295;

declare variable $binaryToHexMap := map:map();
declare variable $hexToBinaryMap := map:map();

declare variable $initializeMaps := (
		map:put($binaryToHexMap,'0000','0'),
		map:put($binaryToHexMap,'0001','1'),
		map:put($binaryToHexMap,'0010','2'),
		map:put($binaryToHexMap,'0011','3'),
		map:put($binaryToHexMap,'0100','4'),
		map:put($binaryToHexMap,'0101','5'),
		map:put($binaryToHexMap,'0110','6'),
		map:put($binaryToHexMap,'0111','7'),
		map:put($binaryToHexMap,'1000','8'),
		map:put($binaryToHexMap,'1001','9'),
		map:put($binaryToHexMap,'1010','a'),
		map:put($binaryToHexMap,'1011','b'),
		map:put($binaryToHexMap,'1100','c'),
		map:put($binaryToHexMap,'1101','d'),
		map:put($binaryToHexMap,'1110','e'),
		map:put($binaryToHexMap,'1111','f'),
		map:put($hexToBinaryMap,'0','0000'),
		map:put($hexToBinaryMap,'1','0001'),
		map:put($hexToBinaryMap,'2','0010'),
		map:put($hexToBinaryMap,'3','0011'),
		map:put($hexToBinaryMap,'4','0100'),
		map:put($hexToBinaryMap,'5','0101'),
		map:put($hexToBinaryMap,'6','0110'),
		map:put($hexToBinaryMap,'7','0111'),
		map:put($hexToBinaryMap,'8','1000'),
		map:put($hexToBinaryMap,'9','1001'),
		map:put($hexToBinaryMap,'a','1010'),
		map:put($hexToBinaryMap,'b','1011'),
		map:put($hexToBinaryMap,'c','1100'),
		map:put($hexToBinaryMap,'d','1101'),
		map:put($hexToBinaryMap,'e','1110'),
		map:put($hexToBinaryMap,'f','1111')
									);

declare function hashing:sha1($message as xs:string) {
	let $hMap := ($initializeMaps,map:map())
	let $h0 := map:put($hMap,'0', 1732584193) (:xdmp:hex-to-integer('67452301'):)
	let $h1 := map:put($hMap,'1', 4023233417) (:xdmp:hex-to-integer('EFCDAB89'):)
	let $h2 := map:put($hMap,'2', 2562383102) (:xdmp:hex-to-integer('98BADCFE'):)
	let $h3 := map:put($hMap,'3', 271733878) (:xdmp:hex-to-integer('10325476'):)
	let $h4 := map:put($hMap,'4', 3285377520) (:xdmp:hex-to-integer('C3D2E1F0'):)
	
	let $messageLength := fn:string-length($message)
	let $messageLengthMod4 := $messageLength mod 4
	let $i := if ($messageLengthMod4 eq 0)
			  then ('80000000')
			  else if ($messageLengthMod4 eq 1)
			  then (hashing:pad-with-zeros(
			  			xdmp:integer-to-hex(xdmp:or64(xdmp:lshift64(fn:string-to-codepoints($message)[fn:last()], 24), xdmp:hex-to-integer('0800000')))
			  		, 8))
			  else if ($messageLengthMod4 eq 2)
			  then (let $codepoints := fn:string-to-codepoints($message)
			  	    return hashing:pad-with-zeros(
			  			xdmp:integer-to-hex(xdmp:or64(xdmp:or64(xdmp:lshift64($codepoints[fn:last()-1], 24),xdmp:lshift64($codepoints[fn:last()], 16)), xdmp:hex-to-integer('08000')))
			  		, 8))
			  else (let $codepoints := fn:string-to-codepoints($message)
			  	    return hashing:pad-with-zeros(
			  			xdmp:integer-to-hex(xdmp:or64(xdmp:or64(xdmp:or64(xdmp:lshift64($codepoints[fn:last()-2], 24),xdmp:lshift64($codepoints[fn:last()-1], 16)), xdmp:lshift64($codepoints[fn:last()], 8)), xdmp:hex-to-integer('080')))
			  		, 8))
	let $chunks := 	for $chunk in hashing:chunk-hex(hashing:string-to-hex($message),32)
					return hashing:pad-with-zeros($chunk,8)
	let $zeros := hashing:build-zeros(fn:count($chunks), ())
	let $chunks := ($chunks, $i, $zeros, hashing:pad-with-zeros(xdmp:integer-to-hex(xdmp:rshift64($messageLength, 29)), 8), hashing:pad-with-zeros(xdmp:integer-to-hex(xdmp:lshift64($messageLength, 3)), 8))
	let $_ := for $blockNumber in (1 to (fn:count($chunks) idiv 16))
				let $wordChunksMap := map:map()
				let $blockStart := (($blockNumber -1) * 16) + 1
				let $blockEnd := $blockStart + 15
				let $_ := for $c at $pos in ($chunks[$blockStart to $blockEnd])
							return map:put($wordChunksMap, xs:string($pos - 1), xdmp:hex-to-integer($c))
				let $_ := for $i in (16 to 79)
							let $w1 := map:get($wordChunksMap, xs:string($i - 3))
							let $w2 := map:get($wordChunksMap, xs:string($i - 8))
							let $w3 := map:get($wordChunksMap, xs:string($i - 14))
							let $w4 := map:get($wordChunksMap, xs:string($i - 16))
							let $newValue := hashing:rotate-left32(xdmp:xor64($w4,xdmp:xor64($w3,xdmp:xor64($w2,$w1))), 1)
							return map:put($wordChunksMap, xs:string($i), $newValue)
				let $chunkMap := map:map()
				let $_ := map:put($chunkMap ,'a',map:get($hMap,'0'))
				let $_ := map:put($chunkMap ,'b',map:get($hMap,'1'))
				let $_ := map:put($chunkMap ,'c',map:get($hMap,'2'))
				let $_ := map:put($chunkMap ,'d',map:get($hMap,'3'))
				let $_ := map:put($chunkMap ,'e',map:get($hMap,'4'))
				let $_ := for $i in 0 to 79
							let $a := map:get($chunkMap ,'a')
							let $b := map:get($chunkMap ,'b')
							let $c := map:get($chunkMap ,'c')
							let $d := map:get($chunkMap ,'d')
							let $e := map:get($chunkMap ,'e')
							let $f := if ($i ge 0 and $i le 19) 
										then (xdmp:or64(xdmp:and64($b,$c),xdmp:and64(xdmp:not64($b),$d)))
										else if ($i ge 40 and $i le 59)
										then (xdmp:or64(xdmp:or64(xdmp:and64($b,$c),xdmp:and64($b,$d)),xdmp:and64($c,$d)))
										else (xdmp:xor64($d,xdmp:xor64($b,$c)))
							let $k := if ($i ge 0 and $i le 19) 
										then (1518500249) (:xdmp:hex-to-integer('5A827999'):)
										else if ($i ge 20 and $i le 39)
										then (1859775393)(:xdmp:hex-to-integer('6ED9EBA1'):)
										else if ($i ge 40 and $i le 59)
										then (2400959708)(:xdmp:hex-to-integer('8F1BBCDC'):)
										else (3395469782)(:xdmp:hex-to-integer('CA62C1D6'):)
							let $temp := hashing:integer-to-32bit(xdmp:add64(hashing:rotate-left32($a,5),xdmp:add64(hashing:integer-to-32bit($f), xdmp:add64($e,xdmp:add64($k, map:get($wordChunksMap, xs:string($i)))))))
							let $_ := map:put($chunkMap ,'e',$d)
							let $_ := map:put($chunkMap ,'d',$c)
							let $_ := map:put($chunkMap ,'c',hashing:rotate-left32($b, 30))
							let $_ := map:put($chunkMap ,'b',$a)
							let $_ := map:put($chunkMap,'a',$temp)
							return ()
				
				let $h0 := map:get($hMap ,'0')
				let $h1 := map:get($hMap ,'1')
				let $h2 := map:get($hMap ,'2')
				let $h3 := map:get($hMap ,'3')
				let $h4 := map:get($hMap ,'4')
				let $a := map:get($chunkMap ,'a')
				let $b := map:get($chunkMap ,'b')
				let $c := map:get($chunkMap ,'c')
				let $d := map:get($chunkMap ,'d')
				let $e := map:get($chunkMap ,'e')
				let $_ := map:put($hMap,'0',hashing:add32($h0, $a))
				let $_ := map:put($hMap,'1',hashing:add32($h1, $b))
				let $_ := map:put($hMap,'2',hashing:add32($h2, $c))
				let $_ := map:put($hMap,'3',hashing:add32($h3, $d))
				let $_ := map:put($hMap,'4',hashing:add32($h4, $e))
				return ()
	return fn:string-join((
			hashing:pad-with-zeros(xdmp:integer-to-hex(map:get($hMap,'0')), 8),
			hashing:pad-with-zeros(xdmp:integer-to-hex(map:get($hMap,'1')), 8),
			hashing:pad-with-zeros(xdmp:integer-to-hex(map:get($hMap,'2')), 8),
			hashing:pad-with-zeros(xdmp:integer-to-hex(map:get($hMap,'3')), 8),
			hashing:pad-with-zeros(xdmp:integer-to-hex(map:get($hMap,'4')), 8)
			), '')
};

declare function hashing:chunk-hex($hex as xs:string, $bitSize as xs:integer) as xs:string* {
	let $hexLength := ($bitSize idiv 4)
	let $numOfChunks := fn:string-length($hex) idiv $hexLength
	for $i in 1 to ($numOfChunks)
	return fn:substring($hex, (($i - 1) * $hexLength)+1, $hexLength)
};

declare function hashing:chunk-binary($binary as xs:string, $bitSize as xs:integer) as xs:string* {
	let $numOfChunks := fn:string-length($binary) idiv $bitSize
	for $i in 1 to ($numOfChunks)
	return fn:substring($binary, (($i - 1) * $bitSize)+1, $bitSize)
};

declare function hashing:rotate-left32($number as xs:unsignedLong, $shift as xs:integer) {
	let $binary := hashing:pad-with-zeros(hashing:hex-to-binary(xdmp:integer-to-hex(xdmp:and64($number, $BIT32AND))), 32)
	let $rotatedBinary := fn:string-join((fn:substring($binary, $shift + 1),fn:substring($binary, 1, ($shift - 1)),fn:substring($binary, $shift, 1)),'')
	return xdmp:hex-to-integer(hashing:binary-to-hex($rotatedBinary))
};

declare function hashing:add32($number1 as xs:unsignedLong,$number2 as xs:unsignedLong) {
	xdmp:and64(xdmp:add64($number1, $number2), $BIT32AND)
};

declare function hashing:string-to-hex($string as xs:string) {
	fn:string-join((
		(for $cp in fn:string-to-codepoints($string)
		return hashing:pad-with-zeros(xdmp:integer-to-hex($cp),2))
	), '') 
};

declare function hashing:integer-to-32bit($integer as xs:integer) as xs:unsignedLong {
	xdmp:and64($integer, $BIT32AND)
};

declare function hashing:build-zeros($chunkCount, $zeros) {
	if ((($chunkCount + fn:count($zeros)) mod 16) eq 13)
	then ($zeros)
	else (
		hashing:build-zeros($chunkCount, ($zeros, '00000000'))
	)
};

declare function hashing:hex-to-binary($hex as xs:string) as xs:string {
	let $codepoints := fn:string-to-codepoints($hex)
	return
	fn:string-join((
	for $cp in $codepoints
	return map:get($hexToBinaryMap, fn:codepoints-to-string($cp)) 
	), '')
};

declare function hashing:binary-to-hex($binary as xs:string) as xs:string {
	fn:string-join((	
	for $bin in hashing:chunk-binary($binary, 4)
	return map:get($binaryToHexMap, $bin)
	), '')
};

declare function hashing:pad-with-zeros($string as xs:string, $length as xs:integer) {
	fn:string-join((
	(for $i in 1 to ($length - fn:string-length($string))
	return '0'),
	$string),
	'')
};