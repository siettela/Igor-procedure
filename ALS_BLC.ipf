#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

function ALS_BLC_1D(input,ifShowRes)
	wave input //1D wave
	variable ifShowRes //1 -> show graph 0 -> no graph
	
	if(ifShowRes!=1&&ifShowRes!=0)
		Doalert 0, "Error."
		return 0
	endif	
	
	////Paramater////
	variable lambda = 10^3 // between 10^2 and 10^9
	variable p = 0.001 	// between 0.001 and 0.1.
	variable itr = 10 //
	////////////////
		
	variable len = dimsize(input,0) 
	make/FREE/O/N=(len) w = 1
	
	//Make D matrix 
	MatrixOp/FREE/O D = identity(len)
	differentiate /EP=1/METH=2/DIM=0 D
	differentiate /EP=1/METH=2/DIM=0 D
	
	//Make H matrix = lambda * D^T x D
	Make/FREE /O/N=(len) diag0 = 6
    diag0[0]=1
    diag0[1]=5
    diag0[len-2]=5
    diag0[len-1]=1

    Make/FREE /O/N=(len-1) diag1 = -4
    diag1[0]=-2
    diag1[len-2]=-2

    Make/FREE /O/N=(len-2) diag2 = 1
    Make/FREE /O/N=(len,len) H
    matrixoP/o H = setoffdiag(H,0,diag0)
    matrixop/o H = setoffdiag(H,-1,diag1)
    matrixop/o H = setoffdiag(H,1,diag1)
    matrixop/o H = setoffdiag(H,-2,diag2)
    matrixop/o H = setoffdiag(H,2,diag2)
    matrixop/o H = lambda * H
	
	
	//MAIN-LOOP//
	variable i 
	for(i=0;i<itr;i+=1)
//		matrixOP/FREE/O M_A = (diagonal(w) + H)
//		matrixOP/FREE/O M_B = w*input
//		matrixSolve LU, M_A,M_B
//		wave M_x // output
		
		matrixOp /o /free  C = chol(diagRC(w, len, len)+H)
        matrixOp /o M_x = backwardSub(C,(forwardSub(C^t, w * input)))
		
		//
		matrixOP/O  w = p * greater(input,M_x) + (1-p) * greater(M_x,input)
	endfor
	
	string input_name =  nameofwave(input)
	duplicate/O M_x $input_name + "_bl"
	duplicate/O input $input_name + "_blc"
	wave output = $(input_name + "_blc")
	output -= M_x
	killwaves M_x
	
	if(ifShowRes==1)
		Display/K=1 input
		ModifyGraph width=420,height=220
		setaxis/A/R bottom
		ModifyGraph nticks(left)=0
		
		appendtoGraph output
		appendtoGraph $input_name + "_bl"
		ModifyGraph rgb($input_name + "_bl")=(0,0,65535)
		ModifyGraph rgb($input_name + "_blc")=(2,39321,1)
		
		string text_als
		text_als = "\s("+input_name+") "+input_name+"\s("+input_name + "_bl) "+input_name + "_bl\s("+input_name + "_blc) "+input_name + "_blc"
		Legend/C/N=text_als/F=0/A=RT
		
		variable offset = wavemax(input)*1.05
		ModifyGraph offset($input_name + "_blc")={0,offset}
		SetDrawEnv xcoord= bottom,ycoord= left;DelayUpdate
		DrawLine len,offset,0,offset
	endif	
end		
		
function ALS_BLC_4D(input)  
	wave input
	variable row = dimsize(input,0)
	variable col = dimsize(input,1)
	variable layer = dimsize(input,2)
	variable spnum = dimsize(input,3)
	
	string output_name = nameofwave(input) + "_ALS"
	duplicate/O input $output_name
	wave output = $output_name
	make/O/N=(spnum) temp_1D
	variable i,j,k
	for(i=0;i<row;i+=1)
		for(j=0;j<col;j+=1)
			for(k=0;k<layer;k+=1)
			temp_1D = input[i][j][k][p] 
			ALS_BLC_1D(temp_1D,0)
			wave blc = $"temp_1D_blc"
			output[i][j][k][*]  = blc[s]
			endfor
		endfor
	endfor	
	wave temp_1D_bl, temp_1D_blc
	killwaves temp_1D, temp_1D_bl,temp_1D_blc	
end			