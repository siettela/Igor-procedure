#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.




//MEMO
Setscale/I dims,0,131.56,//Wavename  //934/120 pixels
//


macro OpenAllImage(DFRName,i,x,y)
string DFRName 
Prompt DFRName,"Select Data Folder.",popup ReplaceString(",",StringByKey("FOLDERS",DataFolderDir(1)),";")
variable i 
Prompt i, "Print laser point?" , popup "Yes;No"
Variable x,y
Prompt x,"Enter x laser pnt."
Prompt y,"Enter y laser pnt."
if(i==1)
OAI_PrintLaserPnt(DFRName,x,y)
else
OpenAllImages(DFRName)
endif
endmacro

function OAI_PrintLaserPnt(DFRName,x,y)
string DFRName
variable x
variable y
DFREF dfr_saved = GetDataFolderDFR()
setdataFolder :$DFRName
string list = wavelist("*",";","")
string wvName
variable nmax
nmax= itemsinlist(list)
variable i
for(i=0;i<nmax;i+=1)
	wvName = StringFromList(i,list)
	wave Imgwave = $wvName
	NewImage/K=1/HIDE=1 Imgwave
	ModifyGraph width=512,height={Aspect,1}
	SetDrawEnv xcoord= top,ycoord= left,linefgc= (3,52428,1),fillpat= 0,linethick= 3.00;DelayUpdate
	DrawOval (x+4)*(131.56/1023),(y+4)*(131.56/1023),(x-4)*(131.56/1023),(y-4)*(131.56/1023) //scaleを合わせたものに修正
endfor
setdataFolder dfr_saved
end

function OpenAllImages(DFRName)
string DFRName
DFREF dfr_saved = GetDataFolderDFR()
setdataFolder :$DFRName
string list = wavelist("*",";","DIMS:2")
string wvName
variable nmax
nmax= itemsinlist(list)
variable i
for(i=0;i<nmax;i+=1)
	wvName = StringFromList(i,list)
	wave Imgwave = $wvName
	NewImage/K=1/HIDE=1 Imgwave
	ModifyGraph width=512,height={Aspect,1}
endfor
setdataFolder dfr_saved
end

function ImageExpand(laser_x,laser_y,step_x,step_y,stride_x,stride_y)	//FixImages後に対応
variable laser_x
variable laser_y
variable step_x
variable step_y
variable stride_x
variable stride_y


Laser_x *= (131.56/1023)
Laser_y *= (131.56/1023)



string win=WinName(0,1)

SetAxis left laser_y, laser_y + (step_y * stride_y);DelayUpdate
SetAxis top laser_x, laser_x + (step_x * stride_x)

String win_rec=WinRecreation(win,0)
Execute /Q win_rec
SetAxis/A

//DrawLine 
SetDrawEnv xcoord= top,ycoord= left,linefgc= (3,52428,1),linethick= 2.00
Drawline   laser_x,laser_y, laser_x, laser_y + (step_y * stride_y);DelayUpdate
SetDrawEnv xcoord= top,ycoord= left,linefgc= (3,52428,1),linethick= 2.00
Drawline   laser_x,laser_y, laser_x + (step_x * stride_x), laser_y;DelayUpdate
SetDrawEnv xcoord= top,ycoord= left,linefgc= (3,52428,1),linethick= 2.00
Drawline   laser_x + (step_x * stride_x), laser_y, laser_x + (step_x * stride_x), laser_y + (step_y * stride_y);DelayUpdate
SetDrawEnv xcoord= top,ycoord= left,linefgc= (3,52428,1),linethick= 2.00
Drawline   laser_x, laser_y + (step_y * stride_y), laser_x + (step_x * stride_x), laser_y + (step_y * stride_y)
dowindow/HIDE=1 $win
dowindow/HIDE=1 $(win + "_1")

end



macro FixImage_cRaman(DFRName)
string DFRName 
Prompt DFRName,"Select Data Folder.",popup ReplaceString(",",StringByKey("FOLDERS",DataFolderDir(1)),";")
FixImage(DFRName)
endmacro

function FixImage(DFRName)
string DFRName
DFREF dfr_saved = GetDataFolderDFR()
setdataFolder :$DFRName
string list = wavelist("*",";","DIMS:2")
string wvName
variable nmax
nmax= itemsinlist(list)
variable i
for(i=0;i<nmax;i+=1)
	wvName = StringFromList(i,list)
	wave Imgwave = $wvName
	//delete header
	DeletePoints/M=1 0,1, Imgwave
	//Set scale for cRaman
	Setscale/I x,0,131.56,Imgwave //934/120 pixels
	Setscale/I y,0,131.56,Imgwave //934/120 pixels
endfor
setdataFolder dfr_saved
end


function GraytoRed(First_num,Last_num)
	variable First_num,Last_num
	variable i
	for(i=First_num;i<=Last_num;i+=1)
		string ImgName = "Graph"+num2str(i)
		ModifyImage/W=$ImgName '' ctab= {*,*,Red,0}
	endfor	
end	


function subBG_Image(DFRName)
string DFRName
DFREF dfr_saved = GetDataFolderDFR()
setdataFolder :$DFRName
string list = wavelist("*",";","DIMS:2")
string wvName
variable nmax
nmax= itemsinlist(list)
wave BG_I = root:BG:BG_I
variable i
for(i=0;i<nmax;i+=1)
	wvName = StringFromList(i,list)
	wave Imgwave = $wvName
	//delete header
	Imgwave -= BG_I * 0.9
endfor
setdataFolder dfr_saved
end