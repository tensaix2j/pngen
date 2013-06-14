
package provide PNG 1.0

namespace eval PNG {

    proc write { filename palette alpha_palette image_data_arr_name scale_x scale_y pixborder  symbolX } {

	upvar $image_data_arr_name image

        set fid [open ${filename} w]
        fconfigure ${fid} -translation binary


	set datawidth 	 [ llength  [ lindex $image 0 ] ]
	set dataheight   [ llength  $image ] 
	set width   	 [ expr $datawidth  * $scale_x  ]
        set height 	 [ expr $dataheight * $scale_y  ]
	set lwidth	[ expr $width  - 1  ]
	set lheight	[ expr $height - 1  ]
	
	#---PNG Signature
        puts -nonewline ${fid} [binary format c8 {137 80 78 71 13 10 26 10}]
        

	set data {}
        append data [binary format I $width]
        append data [binary format I $height]
        append data [binary format c5 {8 3 0 0 0}]
        Chunk ${fid} "IHDR" ${data}

	
	

	#--- PLTE --------------
	set data {}
        set unique-colors [lsort -dictionary -unique ${image}]
        set palette-size 0
        foreach color ${palette} {
            append data [binary format H6 ${color}]
            incr palette-size
        }
        if { ${palette-size} < 256 } {
            set fill [binary format H6 000000]
            append data [string repeat ${fill} [expr {256-${palette-size}}]]
        }
        Chunk ${fid} "PLTE" ${data}

	

	#---TRNS--------------
	set data {}
	foreach alpha $alpha_palette {
		append data [ binary format c $alpha ]
	}
	Chunk ${fid} "tRNS" ${data}


	
	
	#---Data----------------
        set data {}

	
	set rr 0
	
        foreach scanline $image {
	
		for { set i 0 } { $i < $scale_y } { incr i } {

			
			# add filter type to the beginning of each scanline
			append data [binary format c 0]     ;# type 0 (no filter)
			set cc 0
			
			foreach pixel $scanline {

				for { set j 0 } { $j < $scale_x } { incr j } { 

					if {  $symbolX == 1 } {
						
						if { [ mask_with_triangle $j $i $scale_x $scale_y ] == 1 } {
							set colorindex $pixel
						} else {
							set colorindex 0
						}

					} else {
						set colorindex $pixel
					}
						
					if { $scale_x > 1 && $scale_y > 1 && $pixborder == 1 && ( $i == 0 || $j == 0 || $rr == $lheight || $cc == $lwidth )  } {

						set colorindex 1
					}
		
					append data [binary format c $colorindex ]
					incr cc
				}
				
			}
			incr rr
		}
		
        }

	#puts "col: $cc , row: $rr "
	
        #set cdata [binary format H* 78da]
	set cdata [binary format H* 38cb]
	append cdata [zlib deflate ${data} 9]
	
	# Fuck this guy for missing this, seriously
	set checkvalue [ zlib adler32 $data ] 
	append cdata [binary format I $checkvalue ]	
	
			
	Chunk ${fid} "IDAT" ${cdata}
	
	

	#-- IEND--------------------
        Chunk ${fid} "IEND"     
        close ${fid}
    }




   	#--------------------------
	# Mark X like such  for example, if the scalex and scaley is 5x5
	#
	#
	#	1 0 0 0 1
	#	0 1 0 1 0
	#	0 0 1 0 0
	#	0 1 0 1 0
	#	1 0 0 0 1

	proc mask_with_symbolX { x y scalex scaley } {
		
		if { $scalex <= 2 || $scaley <= 2 || $x == $y  || [ expr $scalex - 1 - $x ] == $y  } {		
			return 1;
		}  

		return 0
	}

	proc mask_with_triangle { x y scalex scaley } {
		
		if { $scalex <= 2 || $scaley <= 2 || $y < $x    } {		
			return 1;
		}  
		
		return 0
	}	

    	
    #--------------------------------------
    proc Chunk { fid type {data ""} } {
        set length [binary format I [string length ${data}]]
        puts -nonewline ${fid} ${length}
        puts -nonewline ${fid} [encoding convertto ascii ${type}]
        if { ${data} ne "" } {
            puts -nonewline ${fid} ${data}  
        }
        set crcdata "${type}${data}"
        set crc [zlib crc32 ${crcdata}]
        puts -nonewline ${fid} [binary format I ${crc}]
    }

}

#--------------------------
# Example :

if  { $argv == "testpngen" } {

	set palette 		{ 0 000000 FF0000 00FF00 0000FF FFFF00 FF00FF}
	set alpha_palette 	{ 100 255 255 255 255 255 255 }
	
	set image {
		{1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1}
		{1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1}
		{1 0 0 1 1 1 1 1 1 1 1 0 0 0 3 3 3 3 0 0 0 2 2 0 0 0 0 0 0 0 0 1}
		{1 0 0 1 1 1 1 1 1 1 1 0 0 3 3 3 3 3 3 0 0 2 2 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 1 1 0 0 0 0 0 3 3 0 0 3 3 0 0 2 2 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 1 1 0 0 0 0 0 3 3 0 0 0 0 0 0 2 2 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 1 1 0 0 0 0 0 3 3 0 0 0 0 0 0 2 2 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 1 1 0 0 0 0 0 3 3 0 0 0 0 0 0 2 2 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 1 1 0 0 0 0 0 3 3 0 0 0 0 0 0 2 2 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 1 1 0 0 0 0 0 3 3 0 0 3 3 0 0 2 2 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 1 1 0 0 0 0 0 3 3 3 3 3 3 0 0 2 2 2 2 2 2 2 0 0 0 1}
		{1 0 0 0 0 0 1 1 0 0 0 0 0 0 3 3 3 3 0 0 0 2 2 2 2 2 2 2 0 0 0 1}
		{1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1}
		{1 0 4 4 4 4 4 4 0 0 0 1 1 0 0 0 0 1 1 0 0 6 6 6 6 6 6 6 6 0 0 1}
		{1 0 4 4 4 4 4 4 4 0 0 1 1 0 0 0 0 1 1 0 0 6 6 6 6 6 6 6 6 0 0 1}
		{1 0 4 4 0 0 0 4 4 0 0 1 1 1 0 0 0 1 1 0 0 6 6 0 0 0 0 0 0 0 0 1}
		{1 0 4 4 0 0 0 4 4 0 0 1 1 1 1 0 0 1 1 0 0 6 6 0 0 0 0 0 0 0 0 1}
		{1 0 4 4 0 0 0 4 4 0 0 1 1 0 1 1 0 1 1 0 0 6 6 0 0 6 6 6 6 0 0 1}
		{1 0 4 4 4 4 4 4 4 0 0 1 1 0 0 1 1 1 1 0 0 6 6 0 0 6 6 6 6 0 0 1}
		{1 0 4 4 4 4 4 4 0 0 0 1 1 0 0 0 1 1 1 0 0 6 6 0 0 0 0 6 6 0 0 1}
		{1 0 4 4 0 0 0 0 0 0 0 1 1 0 0 0 0 1 1 0 0 6 6 0 0 0 0 6 6 0 0 1}
		{1 0 4 4 0 0 0 0 0 0 0 1 1 0 0 0 0 1 1 0 0 6 6 6 6 6 6 6 6 0 0 1}
		{1 0 4 4 0 0 0 0 0 0 0 1 1 0 0 0 0 1 1 0 0 6 6 6 6 6 6 6 6 0 0 1}
		{1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1}
		{1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1}
		{1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1}
		}
		
		PNG::write test.png $palette $alpha_palette image 1 1 0

}


