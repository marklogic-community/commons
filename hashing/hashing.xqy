xquery version '1.0-ml';

module namespace hashing = "/hashing";

declare namespace s="http://www.w3.org/2009/xpath-functions/analyze-string";

declare variable $BIT32AND := 4294967295;

declare function hashing:sha1($message as xs:string) {
	let $hMap := map:map()
	let $h0 := map:put($hMap,'0',xdmp:hex-to-integer('67452301'))
	let $h1 := map:put($hMap,'1',xdmp:hex-to-integer('EFCDAB89'))
	let $h2 := map:put($hMap,'2',xdmp:hex-to-integer('98BADCFE'))
	let $h3 := map:put($hMap,'3',xdmp:hex-to-integer('10325476'))
	let $h4 := map:put($hMap,'4',xdmp:hex-to-integer('C3D2E1F0'))

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
	let $chunks := 	for $chunk in hashing:chunk-hex(hashing:string-to-hex($message),512)
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
										then (xdmp:hex-to-integer('5A827999'))
										else if ($i ge 20 and $i le 39)
										then (xdmp:hex-to-integer('6ED9EBA1'))
										else if ($i ge 40 and $i le 59)
										then (xdmp:hex-to-integer('8F1BBCDC'))
										else (xdmp:hex-to-integer('CA62C1D6'))
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
	let $analyze := fn:analyze-string($binary, '[0-1]')
	let $axis := $analyze/s:match[$shift]
	let $rotatedBinary := fn:string-join(($axis/following-sibling::s:match,$axis/preceding-sibling::s:match,$axis),'')
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
	let $hexLength := fn:string-length($hex)
	return
	fn:string-join((
	for $i in (1 to $hexLength)
	let $h := fn:substring($hex, $i, 1)
	return if ($h eq '0') 
			then ('0000')
			else if ($h eq '1')
			then ('0001')
			else if ($h eq '2')
			then ('0010')
			else if ($h eq '3')
			then ('0011')
			else if ($h eq '4')
			then ('0100')
			else if ($h eq '5')
			then ('0101')
			else if ($h eq '6')
			then ('0110')
			else if ($h eq '7')
			then ('0111')
			else if ($h eq '8')
			then ('1000')
			else if ($h eq '9')
			then ('1001')
			else if ($h eq 'a')
			then ('1010')
			else if ($h eq 'b')
			then ('1011')
			else if ($h eq 'c')
			then ('1100')
			else if ($h eq 'd')
			then ('1101')
			else if ($h eq 'e')
			then ('1110')
			else ('1111')
	), '')
};

declare function hashing:binary-to-hex($binary as xs:string) as xs:string {
	fn:string-join((	
	for $bin in hashing:chunk-binary($binary, 4)
	return if ($bin eq '0000') 
			then ('0')
			else if ($bin eq '0001')
			then ('1')
			else if ($bin eq '0010')
			then ('2')
			else if ($bin eq '0011')
			then ('3')
			else if ($bin eq '0100')
			then ('4')
			else if ($bin eq '0101')
			then ('5')
			else if ($bin eq '0110')
			then ('6')
			else if ($bin eq '0111')
			then ('7')
			else if ($bin eq '1000')
			then ('8')
			else if ($bin eq '1001')
			then ('9')
			else if ($bin eq '1010')
			then ('a')
			else if ($bin eq '1011')
			then ('b')
			else if ($bin eq '1100')
			then ('c')
			else if ($bin eq '1101')
			then ('d')
			else if ($bin eq '1110')
			then ('e')
			else ('f')
	), '')
};

declare function hashing:pad-with-zeros($string as xs:string, $length as xs:integer) {
	fn:string-join((
	(for $i in 1 to ($length - fn:string-length($string))
	return '0'),
	$string),
	'')
};