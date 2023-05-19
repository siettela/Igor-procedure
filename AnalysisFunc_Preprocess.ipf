#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

////////2022.6.29 shibuya/////////
function CosmicRayRemove(peak_pnt,width) //widthはピーク幅の半分
//CONSTRUCT
variable peak_pnt,width
NVAR G_x0 = root:TII:Params:G_x0
NVAR G_y0 = root:TII:Params:G_y0
NVAR G_z0 = root:TII:Params:G_z0
SVAR G_trgtWName = root:TII:Params:G_trgtWName
Wave RamanSp = root:RamanSp

variable left_edge = RamanSp[peak_pnt+width]
variable right_edge = RamanSp[peak_pnt-width]
variable y_ave = (left_edge + right_edge)/2

wave trgtWave = $G_trgtWName
variable i 
for(i=peak_pnt-(width-1);i<=peak_pnt+(width-1);i+=1)
	trgtWave[G_x0][G_y0][G_z0][i]=y_ave
endfor	
end





function SVDAnalyze(input, elements_num, output_name)
	//Apply SVD analysis to input wave. -> output_name
	wave input					//input data (4D wave)
	variable elements_num		//number of using elements (normal:10)
	string output_name			//name of output data
	
	variable row_num = dimsize(input, 0)		//number of x-axis points
	variable column_num = dimsize(input, 1)	//number of y-axis points
	variable sppoint_num	 = dimsize(input, 3)		//number of points in spectra
	
	variable pixel_num = row_num * column_num	//number of pixels in XY image
	
	//Redimension 4D wave to 2D wave. -> global_2dwave
	make/N = (pixel_num, sppoint_num) /O global_2dwave = input
	
	//Apply SVD analysis to global_2dwave. -> W_W, M_U, M_VT
	matrixsvd global_2dwave
	
	//Define global variables (result for SVD analysis).
	wave W_W, M_U, M_VT
	
	//Generate extracted W_W matrix. (matrix of singular values) -> global_ext_w_w
	duplicate/O global_2dwave global_ext_w_w
	global_ext_w_w = 0
	
	//Fill global_ext_w_w with extracted singular values.
	variable i	//counter variable
	for(i=0;i<elements_num;i+=1)
		global_ext_w_w[i][i] = W_W[i]
	endfor
	
	//Reconstruct spectra with selected elements.
	matrixop/O global_reconstructed = M_U x global_ext_w_w x M_VT
	
	//Redimension result data (2D wave) to output data (4D).
	duplicate/O input $output_name
	wave output = $output_name
	output = global_reconstructed
	
	//Delete unnecessary waves.
	killwaves global_2dwave, global_ext_w_w, global_reconstructed
	//killwaves W_W, M_U, M_VT
	
	
	//conversion M_U 
	wave M_U
	variable len = dimsize(M_U,0)
	variable s = sqrt(len)
	make/n=(s,s,1,len)/d/o tempM_U
	tempM_U = M_U
	variable c 
	for(c=0;c<10;c+=1)
		string name = "ImgM_U_" + num2str(c)
		make/n=(s,s)/d/o $name
		wave temp = $name
		temp = tempM_U[p][q][0][c]
	endfor
	killwaves tempM_U
end


function ImageBLC(input)
	wave input
	variable row = dimsize(input,0)
	variable col = dimsize(input,1)
	variable Sp = dimsize(input,3)
	
	make/N=(Sp) tempwave
	wave tempwave 
	variable i,j
	for(i=0;i<row;i+=1)
		for(j=0;j<col;j+=1)
			tempwave += input[i][j][0][p]
		endfor
	endfor
	
	variable tempmin = wavemin(tempwave) /(row*col)
	print tempmin
	input -= tempmin
	killwaves tempwave
end



Macro Show_M_VT(n) 
	variable n
	Show_M_VT_Func(n)
endmacro	

Function Show_M_VT_Func(n) 
	variable n
	wave M_VT
	NVAR G_XaxisMode = root:TII:Params:G_XaxisMode
	if(G_XaxisMode==3)
		SVAR G_XaxisWName  = root:TII:Params:G_XaxisWName
		wave Ramanshift = $G_XaxisWName
	endif	
	
	string winNm = "M_VT_"+num2str(10*n)+"_"+num2str(10*n+9)
	
	string AxisName
	
	PauseUpdate; Silent 1		// building window...
	if(G_XaxisMode==3)
		Display /W=(1630,5,2180,1255) M_VT[10*n][*] vs Ramanshift as winNm //x-x 273 y-y 1104
	else
		Display /W=(1630,5,2180,1255) M_VT[10*n][*] as winNm //x-x 273 y-y 1104
	endif
	ModifyGraph margin(left)=28		//,height={Aspect,2.5}
	ModifyGraph nticks(left)=0,fSize(left)=20, lblMargin(left)=5,lblPosMode(left)=1
	ModifyGraph lblPos(left)=57
	ModifyGraph axisEnab(left)={0.9,0.98}
	SetAxis/A=2 left
	Label left num2str(10*n)
	
	variable i
	for(i=1;i<10;i+=1)
		AxisName = "Axis"+num2str(i+1)
		if(G_XaxisMode==3)
			AppendToGraph/L=$AxisName M_VT[10*n+i][*] vs Ramanshift
		else
			AppendToGraph/L=$AxisName M_VT[10*n+i][*]
		endif	
		ModifyGraph nticks($AxisName)=0, fSize($AxisName)=20, lblMargin($AxisName)=5,lblPosMode($AxisName)=1
		ModifyGraph freePos($AxisName)=0
		ModifyGraph axisEnab($AxisName)={0.9-0.1*i,0.98-0.1*i}
		SetAxis/A=2 $AxisName
		Label $AxisName num2str(10*n+i)
	endfor
	
	ModifyGraph zero=1,axThick=2,zeroThick=1,standoff=0
	
	//Mode Change
	ModifyGraph mode=7,lsize=1,rgb=(0,0,0),useNegRGB=1,usePlusRGB=1,hbFill=4,negRGB=(0,0,65535)
End

//old ver.//
//Macro Show_M_VT(n) : Graph
//	variable n
//	PauseUpdate; Silent 1		// building window...
//	string winNm = "M_VT_"+num2str(10*n)+"_"+num2str(10*n+9)
//	Display /W=(1930,5,2180,1255) M_VT[10*n][*] as winNm //x-x 273 y-y 1104
//	AppendToGraph/L=Axis2 M_VT[10*n+1][*]
//	AppendToGraph/L=Axis3 M_VT[10*n+2][*]
//	AppendToGraph/L=Axis4 M_VT[10*n+3][*]
//	AppendToGraph/L=Axis5 M_VT[10*n+4][*]
//	AppendToGraph/L=Axis6 M_VT[10*n+5][*]
//	AppendToGraph/L=Axis7 M_VT[10*n+6][*]
//	AppendToGraph/L=Axis8 M_VT[10*n+7][*]
//	AppendToGraph/L=Axis9 M_VT[10*n+8][*]
//	AppendToGraph/L=Axis10 M_VT[10*n+9][*]
//	ModifyGraph margin(left)=28		//,height={Aspect,2.5}
//	ModifyGraph nticks(left)=0,nticks(Axis2)=0,nticks(Axis3)=0,nticks(Axis4)=0,nticks(Axis5)=0
//	ModifyGraph nticks(Axis6)=0,nticks(Axis7)=0,nticks(Axis8)=0,nticks(Axis9)=0,nticks(Axis10)=0
//	ModifyGraph fSize(left)=20,fSize(Axis2)=20,fSize(Axis3)=20,fSize(Axis4)=20,fSize(Axis5)=20
//	ModifyGraph fSize(Axis6)=20,fSize(Axis7)=20,fSize(Axis8)=20,fSize(Axis9)=20,fSize(Axis10)=20
//	ModifyGraph lblMargin(left)=5,lblMargin(Axis2)=5,lblMargin(Axis3)=5,lblMargin(Axis4)=5
//	ModifyGraph lblMargin(Axis5)=5,lblMargin(Axis6)=5,lblMargin(Axis7)=5,lblMargin(Axis8)=5
//	ModifyGraph lblMargin(Axis9)=5,lblMargin(Axis10)=5
//	ModifyGraph lblPosMode(left)=1,lblPosMode(Axis2)=1,lblPosMode(Axis3)=1,lblPosMode(Axis4)=1
//	ModifyGraph lblPosMode(Axis5)=1,lblPosMode(Axis6)=1,lblPosMode(Axis7)=1,lblPosMode(Axis8)=1
//	ModifyGraph lblPosMode(Axis9)=1,lblPosMode(Axis10)=1
//	ModifyGraph lblPos(left)=57
//	ModifyGraph freePos(Axis2)=0
//	ModifyGraph freePos(Axis3)=0
//	ModifyGraph freePos(Axis4)=0
//	ModifyGraph freePos(Axis5)=0
//	ModifyGraph freePos(Axis6)=0
//	ModifyGraph freePos(Axis7)=0
//	ModifyGraph freePos(Axis8)=0
//	ModifyGraph freePos(Axis9)=0
//	ModifyGraph freePos(Axis10)=0
//	ModifyGraph axisEnab(left)={0.9,0.98}
//	ModifyGraph axisEnab(Axis2)={0.8,0.88}
//	ModifyGraph axisEnab(Axis3)={0.7,0.78}
//	ModifyGraph axisEnab(Axis4)={0.6,0.68}
//	ModifyGraph axisEnab(Axis5)={0.5,0.58}
//	ModifyGraph axisEnab(Axis6)={0.4,0.48}
//	ModifyGraph axisEnab(Axis7)={0.3,0.38}
//	ModifyGraph axisEnab(Axis8)={0.2,0.28}
//	ModifyGraph axisEnab(Axis9)={0.1,0.18}
//	ModifyGraph axisEnab(Axis10)={0,0.08}
//	Label left num2str(10*n)
//	Label Axis2 num2str(10*n+1)
//	Label Axis3 num2str(10*n+2)
//	Label Axis4 num2str(10*n+3)
//	Label Axis5 num2str(10*n+4)
//	Label Axis6 num2str(10*n+5)
//	Label Axis7 num2str(10*n+6)
//	Label Axis8 num2str(10*n+7)
//	Label Axis9 num2str(10*n+8)
//	Label Axis10 num2str(10*n+9)
//	
//EndMacro

//
//function Show_M_VT_RS(n,Ramanshift) : Graph
//	variable n
//	wave Ramanshift 
//	wave M_VT = root:M_VT
//	PauseUpdate; Silent 1		// building window...
//	string winNm = "M_VT_"+num2str(10*n)+"_"+num2str(10*n+9)
//	Display /W=(1930,5,2180,1255) M_VT[10*n][*] vs Ramanshift as winNm //x-x 273 y-y 1104
//	AppendToGraph/L=Axis2 M_VT[10*n+1][*] vs Ramanshift
//	AppendToGraph/L=Axis3 M_VT[10*n+2][*] vs Ramanshift
//	AppendToGraph/L=Axis4 M_VT[10*n+3][*] vs Ramanshift
//	AppendToGraph/L=Axis5 M_VT[10*n+4][*] vs Ramanshift
//	AppendToGraph/L=Axis6 M_VT[10*n+5][*] vs Ramanshift
//	AppendToGraph/L=Axis7 M_VT[10*n+6][*] vs Ramanshift
//	AppendToGraph/L=Axis8 M_VT[10*n+7][*] vs Ramanshift
//	AppendToGraph/L=Axis9 M_VT[10*n+8][*] vs Ramanshift
//	AppendToGraph/L=Axis10 M_VT[10*n+9][*] vs Ramanshift
//	ModifyGraph margin(left)=28		//,height={Aspect,2.5}
//	ModifyGraph nticks(left)=0,nticks(Axis2)=0,nticks(Axis3)=0,nticks(Axis4)=0,nticks(Axis5)=0
//	ModifyGraph nticks(Axis6)=0,nticks(Axis7)=0,nticks(Axis8)=0,nticks(Axis9)=0,nticks(Axis10)=0
//	ModifyGraph fSize(left)=20,fSize(Axis2)=20,fSize(Axis3)=20,fSize(Axis4)=20,fSize(Axis5)=20
//	ModifyGraph fSize(Axis6)=20,fSize(Axis7)=20,fSize(Axis8)=20,fSize(Axis9)=20,fSize(Axis10)=20
//	ModifyGraph lblMargin(left)=5,lblMargin(Axis2)=5,lblMargin(Axis3)=5,lblMargin(Axis4)=5
//	ModifyGraph lblMargin(Axis5)=5,lblMargin(Axis6)=5,lblMargin(Axis7)=5,lblMargin(Axis8)=5
//	ModifyGraph lblMargin(Axis9)=5,lblMargin(Axis10)=5
//	ModifyGraph lblPosMode(left)=1,lblPosMode(Axis2)=1,lblPosMode(Axis3)=1,lblPosMode(Axis4)=1
//	ModifyGraph lblPosMode(Axis5)=1,lblPosMode(Axis6)=1,lblPosMode(Axis7)=1,lblPosMode(Axis8)=1
//	ModifyGraph lblPosMode(Axis9)=1,lblPosMode(Axis10)=1
//	ModifyGraph lblPos(left)=57
//	ModifyGraph freePos(Axis2)=0
//	ModifyGraph freePos(Axis3)=0
//	ModifyGraph freePos(Axis4)=0
//	ModifyGraph freePos(Axis5)=0
//	ModifyGraph freePos(Axis6)=0
//	ModifyGraph freePos(Axis7)=0
//	ModifyGraph freePos(Axis8)=0
//	ModifyGraph freePos(Axis9)=0
//	ModifyGraph freePos(Axis10)=0
//	ModifyGraph axisEnab(left)={0.9,0.98}
//	ModifyGraph axisEnab(Axis2)={0.8,0.88}
//	ModifyGraph axisEnab(Axis3)={0.7,0.78}
//	ModifyGraph axisEnab(Axis4)={0.6,0.68}
//	ModifyGraph axisEnab(Axis5)={0.5,0.58}
//	ModifyGraph axisEnab(Axis6)={0.4,0.48}
//	ModifyGraph axisEnab(Axis7)={0.3,0.38}
//	ModifyGraph axisEnab(Axis8)={0.2,0.28}
//	ModifyGraph axisEnab(Axis9)={0.1,0.18}
//	ModifyGraph axisEnab(Axis10)={0,0.08}
//	Label left num2str(10*n)
//	Label Axis2 num2str(10*n+1)
//	Label Axis3 num2str(10*n+2)
//	Label Axis4 num2str(10*n+3)
//	Label Axis5 num2str(10*n+4)
//	Label Axis6 num2str(10*n+5)
//	Label Axis7 num2str(10*n+6)
//	Label Axis8 num2str(10*n+7)
//	Label Axis9 num2str(10*n+8)
//	Label Axis10 num2str(10*n+9)
//EndMacro





macro Show_M_U() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(5,5,1005,405) as "M_U"
	//conversion_M_U()
	//Image 0
	Display/W=(0,0,200,200)/HOST=# 
	AppendImage ImgM_U_0
	ModifyImage ImgM_U_0 ctab= {*,*,Geo,0}
	ModifyGraph margin(left)=42,margin(bottom)=42,margin(top)=28,margin(right)=28
	ModifyGraph mirror=0
	SetDrawLayer UserFront
	DrawText 0,-0.05,"Image 0"
	RenameWindow #,G0
	SetActiveSubwindow ##
	//Image 1
	Display/W=(200,0,400,200)/HOST=#  
	AppendImage ImgM_U_1
	ModifyImage ImgM_U_1 ctab= {*,*,Geo,0}
	ModifyGraph margin(left)=42,margin(bottom)=42,margin(top)=28,margin(right)=28
	ModifyGraph mirror=0
	SetDrawLayer UserFront
	DrawText 0,-0.05,"Image 1"
	RenameWindow #,G1
	SetActiveSubwindow ##
	//Image 2
	Display/W=(400,0,600,200)/HOST=# 
	AppendImage ImgM_U_2
	ModifyImage ImgM_U_2 ctab= {*,*,Geo,0}
	ModifyGraph margin(left)=42,margin(bottom)=42,margin(top)=28,margin(right)=28
	ModifyGraph mirror=0
	SetDrawLayer UserFront
	DrawText 0,-0.05,"Image 2"
	RenameWindow #,G2
	SetActiveSubwindow ##
	//Image 3
	Display/W=(600,0,800,200)/HOST=# 
	AppendImage ImgM_U_3
	ModifyImage ImgM_U_3 ctab= {*,*,Geo,0}
	ModifyGraph margin(left)=42,margin(bottom)=42,margin(top)=28,margin(right)=28
	ModifyGraph mirror=0
	SetDrawLayer UserFront
	DrawText 0,-0.05,"Image 3"
	RenameWindow #,G3
	SetActiveSubwindow ##
	//Image 4
	Display/W=(800,0,1000,200)/HOST=# 
	AppendImage ImgM_U_4
	ModifyImage ImgM_U_4 ctab= {*,*,Geo,0}
	ModifyGraph margin(left)=42,margin(bottom)=42,margin(top)=28,margin(right)=28
	ModifyGraph mirror=0
	SetDrawLayer UserFront
	DrawText 0,-0.05,"Image 4"
	RenameWindow #,G4
	SetActiveSubwindow ##
	//Image 5
	Display/W=(0,200,200,400)/HOST=#
	AppendImage ImgM_U_5
	ModifyImage ImgM_U_5 ctab= {*,*,Geo,0}
	ModifyGraph margin(left)=42,margin(bottom)=42,margin(top)=28,margin(right)=28
	ModifyGraph mirror=0
	SetDrawLayer UserFront
	DrawText 0,-0.05,"Image 5"
	RenameWindow #,G5
	SetActiveSubwindow ##
	//Image 6
	Display/W=(200,200,400,400)/HOST=# 
	AppendImage ImgM_U_6
	ModifyImage ImgM_U_6 ctab= {*,*,Geo,0}
	ModifyGraph margin(left)=42,margin(bottom)=42,margin(top)=28,margin(right)=28
	ModifyGraph mirror=0
	SetDrawLayer UserFront
	DrawText 0,-0.05,"Image 6"
	RenameWindow #,G6
	SetActiveSubwindow ##
	//Image 7
	Display/W=(400,200,600,400)/HOST=# 
	AppendImage ImgM_U_7
	ModifyImage ImgM_U_7 ctab= {*,*,Geo,0}
	ModifyGraph margin(left)=42,margin(bottom)=42,margin(top)=28,margin(right)=28
	ModifyGraph mirror=0
	SetDrawLayer UserFront
	DrawText 0,-0.05,"Image 7"
	RenameWindow #,G7
	SetActiveSubwindow ##
	//Image 8
	Display/W=(600,200,800,400)/HOST=# 
	AppendImage ImgM_U_8
	ModifyImage ImgM_U_8 ctab= {*,*,Geo,0}
	ModifyGraph margin(left)=42,margin(bottom)=42,margin(top)=28,margin(right)=28
	ModifyGraph mirror=0
	SetDrawLayer UserFront
	DrawText 0,-0.05,"Image 8"
	RenameWindow #,G8
	SetActiveSubwindow ##
	//Image 9
	Display/W=(800,200,1000,400)/HOST=# 
	AppendImage ImgM_U_9
	ModifyImage ImgM_U_9 ctab= {*,*,Geo,0}
	ModifyGraph margin(left)=42,margin(bottom)=42,margin(top)=28,margin(right)=28
	ModifyGraph mirror=0
	SetDrawLayer UserFront
	DrawText 0,-0.05,"Image 9"
	RenameWindow #,G9
	SetActiveSubwindow ##

EndMacro

	
////option////
function ImageBLC_a(input)
	wave input
	variable tempmin = wavemin(input) 
	print tempmin
	input -= tempmin
end	
///////
