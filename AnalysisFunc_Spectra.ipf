#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


macro bg_sub(trgt_wvName,mask_wvName,nn)
string trgt_wvName,mask_wvName
Prompt trgt_wvName,"Select target wave.",popup wavelist("*",";","DIMS:4")
Prompt mask_wvName,"Select mask wave.",popup wavelist("*",";","DIMS:1")
variable n
variable nn=3 //nn=Polynominal terms（多項式の次数）
Prompt nn,"Enter polynominal terms."
string  name00, name1, name2, name3

//load waves
//wave trgtwave = $trgt_wvName
//wave maskwave = $mask_wvName



variable row = dimsize($trgt_wvName,0)
variable col = dimsize($trgt_wvName,1)
variable spnum = dimsize($trgt_wvName,3)




//make temp_wave for fitting
make /O/N=(spnum) temp_wave =0

//make matrices
name00 =trgt_wvName +"_2D"
name1 = trgt_wvName +"_bg"
name2 = trgt_wvName +"_temp"
name3 = trgt_wvName +"_OHsub"

make/N=(row*col,spnum)/O $name00
duplicate/O $name00 $name1, $name2
$name00 = $trgt_wvName

n=0
do
temp_wave = $name00[n][p]
CurveFit/NTHR=0/Q poly nn,  temp_wave /M=$mask_wvName
$name1[n][] = poly(W_coef,q) 
n+=1
//print n
while(n<=row*col)

$name2 = $name00 - $name1
duplicate/O $trgt_wvName $name3
$name3 = $name2

killwaves $name00,$name1,$name2, 

Endmacro


macro MultiNormalize_PI(DFRName,Ramanshift,x)
	string DFRName 
	Prompt DFRName,"Select Data Folder.",popup ReplaceString(",",StringByKey("FOLDERS",DataFolderDir(1)),";")
	string Ramanshift
	Prompt Ramanshift,"Select Ramanshift wave.",popup wavelist("*",";","DIMS:1")
	Variable x
	Prompt x,"Enter peak pnt."
	NormalizeFunc_PI(DFRName,x,Ramanshift)
endmacro

Function NormalizeFunc_PI(DFR_Name,peak_pnt,x_wvName)	
	string DFR_Name
	variable peak_pnt
	string x_wvName
	wave RamanShift = $x_wvName
	
	DFREF dfr_saved = GetDataFolderDFR()
	setdataFolder :$DFR_Name
	string list = wavelist("*",";","")
	String curr_folder=GetDataFolder(1)
	Variable nmax	
	nmax= itemsinlist(list)
	
	//Create  Normalized spectrum
	String wvName
	Variable i
	for( i = 0; i < nmax; i += 1)
		wvName = StringFromList(i, list)
		wave TrgtWave = $wvName
		string output_name =wvName+"_N_"+num2str(peak_pnt)
		duplicate/O TrgtWave $output_name
		wave Normwave = $output_name
		NormWave /= TrgtWave[peak_pnt]
	endfor
	SetDataFolder $curr_folder
End


macro MultiNormalize_SUM(left_region,right_region,x_wvName)
	Variable left_region=422
	variable right_region=812
	string x_wvName
 	Prompt left_region,"Enter left region pnt."
 	Prompt right_region,"Enter right region pnt."
 	prompt x_wvName,"Choose Raman shift wave.",popup wavelist("*",";","DIMS:1")
	String list =  TraceNameList("", ";", 1)	
	list = listMatch(list, "*")
   NormalizeFunc_SUM(list,left_region,right_region,x_wvName)
Endmacro

Function NormalizeFunc_SUM(list,left_region,right_region,x_wvName)
	String list
	variable left_region  //O-H str.:422,C-H bend.:2397
	variable right_region   //O-H str.:812,C-H bend.:2461
	string x_wvName
	string win = winname(0,1)
	Variable nmax	
	String wvName
	Variable i
	wave RamanShift = $x_wvName
	variable L_reg_output = round(RamanShift[left_region])
	variable R_reg_output = round(RamanShift[right_region])
	
	String curr_folder=GetDataFolder(1)
	
	//Create Data folder for Normalized spectrum.
	NewDataFolder /O root:$(win+"_N_"+num2str(L_reg_output)+"_"+num2str(R_reg_output))
	silent 1
	nmax = ItemsInList(list)
	for( i = 0; i < nmax; i += 1)
		wvName = StringFromList(i, list)
		wave TrgtWave = $wvName
		string output_name =wvName+"_Norm"
		duplicate/O TrgtWave $output_name
		wave Normwave = $output_name
		WaveStats/Q/R=[left_region,right_region] TrgtWave
		NormWave /= V_sum
		Movewave Normwave, root:$(win+"_N_"+num2str(L_reg_output)+"_"+num2str(R_reg_output)):$wvName
	endfor
	//generate graph using duplicated spectrum.
	String win_rec=WinRecreation(win,0)
	Execute /Q win_rec
	SetDataFolder root:$(win+"_N_"+num2str(L_reg_output)+"_"+num2str(R_reg_output))
	replacewave allinCDF
	Dowindow/C $win +"_N_"+num2str(L_reg_output)+"_"+num2str(R_reg_output)
	
	SetDataFolder $curr_folder
End


macro MultiNormalize_SUM_offset(left_region,right_region,x_wvName)
	Variable left_region=422
	variable right_region=812
	string x_wvName
 	Prompt left_region,"Enter left region pnt."
 	Prompt right_region,"Enter right region pnt."
 	//prompt x_wvName,"Choose Raman shift wave.",popup wavelist("*",";","DIMS:1")
	String list =  TraceNameList("", ";", 1)	
	list = listMatch(list, "*")
   NormalizeFunc_SUM_offset(list,left_region,right_region,x_wvName)
Endmacro

Function NormalizeFunc_SUM_offset(list,left_region,right_region,x_wvName)
	String list
	variable left_region  //O-H str.:422,C-H bend.:2397
	variable right_region   //O-H str.:812,C-H bend.:2461
	string x_wvName
	string win = winname(0,1)
	Variable nmax	
	String wvName
	Variable i
	wave RamanShift = $x_wvName
	variable L_reg_output = round(RamanShift[left_region])
	variable R_reg_output = round(RamanShift[right_region])
	
	
	//Create Data folder for Normalized spectrum.
	nmax = ItemsInList(list)
	for( i = 0; i < nmax; i += 1)
		wvName = StringFromList(i, list)
		wave TrgtWave = $wvName
		WaveStats/Q/R=[left_region,right_region] TrgtWave
		ModifyGraph muloffset($wvName) ={0,1/V_sum}
	endfor

End



macro MultiBaselineCorrect(mask_name,x_wvName,order)
	string win = winname(0,1)
	String list =  TraceNameList("", ";", 1)
	
	string mask_name 
	Prompt mask_name,"Select mask wave.",popup wavelist("*",";","DIMS:1")
	string x_wvName
	prompt x_wvName,"Choose Raman shift wave.",popup wavelist("*",";","DIMS:1")
	variable order
	Prompt order,"Enter order number."
	
	list = listMatch(list, "*")
	
	String wvName
	Variable i = 0
	Variable nmax	
	nmax = ItemsInList(list)
	
	do
	wvName = StringFromList(i, list)
	BaselineCorrection($wvName,$x_wvName,$mask_name,order)
	i+=1
	while(i<nmax)
	
	String win_rec=WinRecreation(win,0)
	Execute /Q win_rec
	variable j = 0
	string output_name
	do
	wvName = StringFromList(j, list)
	output_name = wvName + "_blc"
	replacewave trace=$wvName, $output_name
	j+=1
	while(j<nmax)	
End


Function BaselineCorrection(input, x_wave, mask, order)
	//Subtract baseline from input wave automatically
	wave input, x_wave, mask
	variable order
	
	//Suffixes for outputs
	string BASELINE_SUFFIX = "_bl"
	string OUTPUT_SUFFIX = "_blc"
	
	//Load name of input and declare name of outputs
	string input_name = nameofwave(input)
	string baseline_name = input_name + BASELINE_SUFFIX
	string output_name = input_name + OUTPUT_SUFFIX
	
	//Generate and declare waves of output
	duplicate/O input $baseline_name
	wave baseline = $baseline_name
	duplicate/O input $output_name
	wave output = $output_name
	
	//Execute curve fitting and show results
	  //show input and mask
	display/K=1 input vs x_wave
	ModifyGraph rgb($input_name)=(65535,0,0)
	AppendToGraph/R mask vs x_wave
	ModifyGraph rgb($nameofwave(mask))=(0,0,0)

	CurveFit/TBOX=768/Q poly order, input /X=x_wave /M=mask
	wave coefs = $"w_coef" //load coefs calculated by CurveFit command.
	
	baseline = poly(coefs, x_wave) //generate baseline wave using coefs
	appendtograph baseline vs x_wave //show baseline
	ModifyGraph rgb($baseline_name)=(0,0,65535)
	ModifyGraph zero(left)=1
	
	//Subtract baseline from input wave and show result
	output = input - baseline
	appendtograph output vs x_wave
	ModifyGraph rgb($output_name)=(0,65535,0)
End




macro MultiDifferentiate(DFRName)
	string DFRName 
	Prompt DFRName,"Select Data Folder.",popup ReplaceString(",",StringByKey("FOLDERS",DataFolderDir(1)),";")
	MultiDifferentiateFunc(DFRName)
endmacro

function MultiDifferentiateFunc(DFR_Name)
	string DFR_Name
	DFREF dfr_saved = GetDataFolderDFR()
	setdataFolder :$DFR_Name
	string list = wavelist("*",";","")
	String curr_folder=GetDataFolder(1)
	Variable nmax	
	nmax= itemsinlist(list)
	
	//
	String wvName
	Variable i
	for( i = 0; i < nmax; i += 1)
		wvName = StringFromList(i, list)
		wave TrgtWave = $wvName
		string output_name =wvName+"_DIF"
		duplicate/O TrgtWave $output_name
		wave OutputWave = $output_name
		differentiate OutputWave 
	endfor
	SetDataFolder dfr_saved
End




macro MultiNormalize_SUM_offset_2(left_region,right_region)
	Variable left_region=1270
	variable right_region=1473
 	Prompt left_region,"Enter left region pnt."
 	Prompt right_region,"Enter right region pnt."
   NormalizeFunc_SUM_offset_2(left_region,right_region)
Endmacro

Function NormalizeFunc_SUM_offset_2(left_region,right_region)
	variable left_region  
	variable right_region   
	String list =  TraceNameList("", ";", 1)
	variable nmax = itemsInList(list)	
	variable i
	for( i = 0; i < nmax; i += 1)
		wave TrgtWave = WaveRefIndexed("",i,1) 
		//wave x_Wave = XwaveRefFromTrace("", StringFromList(i, list))
		WaveStats/Q/R=[left_region,right_region] TrgtWave
		ModifyGraph muloffset($StringFromList(i, list)) ={0,1/V_sum}
  	endfor
end




macro MultiNormalize_SUM_2(left_region,right_region)
	Variable left_region=1270
	variable right_region=1473
 	Prompt left_region,"Enter left region pnt."
 	Prompt right_region,"Enter right region pnt."
   NormalizeFunc_SUM_2(left_region,right_region)
Endmacro

Function NormalizeFunc_SUM_2(left_region,right_region)
	variable left_region  
	variable right_region   
	String list =  TraceNameList("", ";", 1)
	variable nmax = itemsInList(list)	
	//
	string win = winname(0,1)
	String curr_folder=GetDataFolder(1)
	NewDataFolder /O root:$(win+"_N_"+num2str(left_region)+"_"+num2str(right_region))
	//
	variable i
	//Create Data folder for Normalized spectrum.
	for( i = 0; i < nmax; i += 1)
		wave TrgtWave = WaveRefIndexed("",i,1) 
		duplicate/O TrgtWave $(nameofwave(TrgtWave)+"_Norm")
		wave NormWave = $(nameofwave(TrgtWave)+"_Norm")
		//wave x_Wave = XwaveRefFromTrace("", StringFromList(i, list))
		WaveStats/Q/R=[left_region,right_region] NormWave
		NormWave /= V_sum
		Movewave Normwave, root:$(win+"_N_"+num2str(left_region)+"_"+num2str(right_region)):$nameofwave(TrgtWave)
  	endfor
	
	//generate graph using duplicated spectrum.
	String win_rec=WinRecreation(win,0)
	Execute /Q win_rec
	SetDataFolder root:$(win+"_N_"+num2str(left_region)+"_"+num2str(right_region))
	replacewave allinCDF
	Dowindow/C $win +"_N_"+num2str(left_region)+"_"+num2str(right_region)
	
	SetDataFolder $curr_folder
End
