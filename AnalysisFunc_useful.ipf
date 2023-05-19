#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Change the color of traces instantly
// If you'd like to inverse rainbow, change the sorting order in changeColorFunc
// 2012/4/22 S.Tani

Menu "Useful Tools"
  "ChangeColor"
  "GraphStyle"
  "Graph_Int_Norm"
  "Graph_SizeFit"
  
End


Proc changeColor()
	String list =  TraceNameList("", ";", 1)
	Variable abc
	list = listMatch(list, "*")
	abc = changeColorFunc(list)
End

Function changeColorFunc(list)
	String list
	Variable nmax	
	String wvName
	Variable r, g, b
	Variable i
	String legendStr = "\Z24"
	Variable nextTrace = 0
	Variable hue, light, saturation
	Silent 1
	nmax = ItemsInList(list)
	//list = SortList(list, ";",17) /////////////////////// change 16 to 17 if you prefer the rainbow changing from blue to red
	for( i = 0; i < nmax; i += 1)
		hue = (nmax == 1) ? 240 : ((nmax <= 5) ? 240 : 270)*i/(nmax-1)
		light = 0.5 - 0.15*exp(-((hue-120)/50)^2)
		saturation = 1
		HLS2RGB( hue, light, saturation, r, g, b)
		wvName = StringFromList(i, list)
		ModifyGraph RGB($wvName) = (r*65535, g*65535, b*65535)
		if(6*i/((nmax > 1) ? nmax - 1 : 1) >= nextTrace)
			legendStr += "\\s("+wvName+") "+wvName+"\r"
			nextTrace += 1
		endif
	endfor
	legendStr = RemoveEnding(legendStr)
	Legend/C/N=traceColor/J/A=RT/F=0 legendStr
	return 0
End

Function HLS2RGB(h, l, s, red, green, blue) //hue:[0 360] lightness*[0 1] saturation[0 1] rgb[0 1]
	Variable h, l, s
	Variable &red, &green, &blue
	Variable maximum, minimum
	
	
	if(s == 0)
		red = l; green = l; blue = l
		return 0
	endif
	
	maximum = (l <= 0.5) ? l*(1+s) : l*(1-s) + s
	minimum = 2*l - maximum
	substitute(red, mod(h +120, 360), maximum, minimum)
	substitute(green, h, maximum, minimum)
	substitute(blue, mod(h +240, 360), maximum, minimum)
End

Function substitute(value, a, maximum, minimum)
	Variable &value
	Variable a, maximum ,minimum
	if(a < 60)
		value = minimum+(maximum - minimum)*a/60
	elseif(a < 180)
		value = maximum
	elseif(a < 240)
		value = minimum+(maximum - minimum)*(240-a)/60
	else
		value = minimum
	endif
End


proc GraphStyle()
PauseUpdate; Silent 1
SetAxis/A/R bottom
ModifyGraph  fSize=24,axThick=2
ModifyGraph lblMargin(left)=15
ModifyGraph standoff=0
ModifyGraph lsize=2
ModifyGraph axOffset(left)=0 //
ModifyGraph nticks(left)=5 //
Label left "\\Z32Intensity / a.u."
Label bottom "\\Z32Raman shift / cm\\S−1"
end

proc Graph_Int_Norm()
PauseUpdate; Silent 1
ModifyGraph axOffset(left)=-5 
ModifyGraph nticks(left)=0 
Label left "\\Z32Normalized intensity" 
end

proc Graph_SizeFit()
ModifyGraph width=850.394,height={Aspect,0.7}
end

macro MultiRenameWave(DFRName,st,affix)
	string DFRName 
	Prompt DFRName,"Select Data Folder.",popup ReplaceString(",",StringByKey("FOLDERS",DataFolderDir(1)),";")
	variable st 
	Prompt st, "Style:" , popup "Prefix;Suffix"
	string affix
	Prompt affix,"Enter output affix. ex)_220101 "
	setdataFolder :$DFRName
	string list = wavelist("*",";","")
	string wvName
	variable nmax = itemsinlist(list)
	variable i=0
	do
	wvName = StringFromList(i,list)
	RenameWave_func(wvName,st,affix)
	i+=1
	while(i<nmax)
	setdataFolder root:
endmacro

function RenameWave_func(input_name,style,affix)
	string input_name
	variable style
	string affix
	
	wave input = $input_name
	
	string output_name
	if(style == 1)
		output_name = affix + input_name 
	else
		output_name = input_name + affix
	endif
	
	Rename input $output_name
end	
	
function swap1DSp(input)
	wave input
	variable sppnt = dimsize(input,0)
	string wvName = nameofwave(input)
	string newWaveName = wvName + "_swap"
	duplicate/o/d input $newWaveName
	wave newWave = $newWaveName
	variable i
	for(i=0; i<sppnt; i+=1)
		newWave[i]=input[(Sppnt-1)-i]
	endfor
end




macro AverageSpectrum(DFRName,output_name)
	string DFRName 
	Prompt DFRName,"Select Data Folder.",popup ReplaceString(",",StringByKey("FOLDERS",DataFolderDir(1)),";")
	string output_name
	Prompt output_name,"Output Wave Name:"
	MakeAverageSpectrum(DFRName,output_name)
endmacro

function makeAverageSpectrum(DFRName,output)
	string DFRName
	string output
	DFREF curr_DFR = getDataFolderDFR()
	setdataFolder :$DFRName
	string list = wavelist("*",";","")
	string wvName
	variable nmax = itemsinlist(list)
	variable i=0
	
	for(i=0;i<nmax;i+=1)
		wvName = StringFromList(i,list)
		wave trgtWave = $wvName
		if(i==0)
			duplicate/O trgtWave $output
			wave ave_wave = $output
			note /K ave_wave, "Average:"+num2str(nmax)
			note ave_wave, wvName
		else
			ave_wave += trgtWave
			note ave_wave, wvName
		endif
	endfor
	
	ave_wave /= nmax
	setdataFolder curr_DFR
end


Function change_matrix_size(input, input_interpolation, output_interpolation)
	wave input
	variable input_interpolation, output_interpolation
	
	string input_name = nameofwave(input)
	string output_name = input_name +"_" + num2str(input_interpolation) + "to" + num2str(output_interpolation)
	
	duplicate/O input $output_name
	wave output = $output_name
	
	variable row_num = dimsize(input, 0)
	variable col_num = dimsize(input, 1)
	variable sp_num = dimsize(input, 3)
	
	variable row_ave_num = row_num / input_interpolation
	variable col_ave_num = col_num / input_interpolation
	
	variable row_num_output = row_ave_num * output_interpolation
	variable col_num_output = col_ave_num * output_interpolation
//	make/N=(row_num_output, col_num_output, 1, sp_num)/D/O $output_name
	Redimension/N=(row_num_output, col_num_output,-1,-1) output
		
	make/N=(sp_num)/FREE average
	variable row_ave_idx, col_ave_idx, interpolate_row_idx, interpolate_col_idx
	variable col, row
	for(row_ave_idx=0;row_ave_idx<row_ave_num;row_ave_idx+=1)
		for(col_ave_idx=0;col_ave_idx<col_ave_num;col_ave_idx+=1)
		
			average = 0
			for(interpolate_row_idx=0;interpolate_row_idx<input_interpolation;interpolate_row_idx+=1)
				for(interpolate_col_idx=0;interpolate_col_idx<input_interpolation;interpolate_col_idx+=1)
					row = row_ave_idx*input_interpolation + interpolate_row_idx
					col = col_ave_idx*input_interpolation + interpolate_col_idx
					multithread average += input[row][col][0][p]
				endfor
			endfor

			for(interpolate_row_idx=0;interpolate_row_idx<output_interpolation;interpolate_row_idx+=1)
				for(interpolate_col_idx=0;interpolate_col_idx<output_interpolation;interpolate_col_idx+=1)
					col = col_ave_idx*output_interpolation + interpolate_col_idx
					row = row_ave_idx*output_interpolation + interpolate_row_idx
					multithread output[row][col][0][] = average[s] / input_interpolation^2
				endfor
			endfor
	
		endfor
	endfor
End


macro BLC1DSpectrum(DFRName)
	string DFRName 
	Prompt DFRName,"Select Data Folder.",popup ReplaceString(",",StringByKey("FOLDERS",DataFolderDir(1)),";")
	setdataFolder :$DFRName
	BLC1DSpectrum_Func()
	setdataFolder root:
endmacro

function BLC1DSpectrum_Func()
	string list = wavelist("*",";","")
	string wvName
	variable nmax = itemsinlist(list)
	variable i=0
	variable min_var
	
	for(i=0;i<nmax;i+=1)
		wvName = StringFromList(i,list)
		wave trgtWave = $wvName
		duplicate/O trgtWave $(wvName + "_blc")
		wave output_wave = $(wvName + "_blc")
		min_var = wavemin(trgtWave)
		output_wave[] -= min_var
	endfor
	
end

macro add_tag() //kodama
	// set editable parameter
	variable font_size = 24
	variable line_thick = 2
	variable tag_rotation = 45 
 
	//CONSTANTS
	string window_name = WinName(0,1) // get active window name
	string wave_name = csrWave(A) // get wavename which cursor on
	variable tag_point = pcsr(A) // get cursor point
	variable wavenumber = round(hcsr(A)/10)*10 // get wavenumber from X axis 
	
	Tag/O=(tag_rotation)/F=0/X=0.00/Y=30.00/L=1/TL={dash=3, lThick=(line_thick)} $wave_name, tag_point,"\\Z"+num2str(font_size)+num2str(wavenumber)
	
end


function ReplaceAllTraceXwave(x_wave)
	wave x_wave
	String list =  TraceNameList("", ";", 1)
	variable nmax = itemsInList(list)	
	string win = winname(0,1)
	string wvName
	variable i
	for( i = 0; i < nmax; i += 1)
		wvName = StringFromList(i,list)
		ReplaceWave/X/W=$win trace=$(wvName), $nameofwave(x_wave)	
  	endfor
end	
	