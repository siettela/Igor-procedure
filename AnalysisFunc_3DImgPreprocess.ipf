#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
function SVDAnalyze_3D(input, elements_num, output_name)
	//Apply SVD analysis to input wave. -> output_name
	wave input					//input data (4D wave)
	variable elements_num		//number of using elements (normal:10)
	string output_name			//name of output data
	
	variable row_num = dimsize(input, 0)		//number of x-axis points
	variable column_num = dimsize(input, 1)	//number of y-axis points
	variable z_num = dimsize(input,2)	//number of z-axiz points
	variable sppoint_num	 = dimsize(input, 3)		//number of points in spectra
	
	variable pixel_num = row_num * column_num	//number of pixels in XY image
	variable box_num = pixel_num * z_num
	
	//z-axis stacking to 0 (and concatenate in x-axis dimention)
	make/N=(row_num,1,1,sppoint_num)/O layer_4dwave
	variable z1
	for(z1=0;z1<z_num;z1+=1)
		make/N = (row_num,column_num,1,sppoint_num) /O temp_4dwave = input[p][q][z1][s]
		concatenate/NP=1 {temp_4dwave},layer_4dwave
	endfor	
	deletepoints/M=1 0,1,layer_4dwave
	
	
	//Redimension 4D wave to 2D wave. -> global_2dwave
	make/N = (box_num, sppoint_num) /O global_2dwave = layer_4dwave
	
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
	
	make/N=(row_num,column_num,1,sppoint_num)/O $output_name
	wave output = $output_name
	variable z2
	for(z2=0;z2<z_num;z2+=1)
		duplicate/O global_reconstructed temp_rec
		if(z2==0)
			deletepoints pixel_num,(pixel_num*z_num),temp_rec
		elseif(z2==z_num-1)
			deletepoints 0,(pixel_num*(z_num-1)),temp_rec
		else
			deletepoints	 0,(pixel_num*z2),temp_rec
			deletepoints pixel_num,(pixel_num*(z_num-z2)),temp_rec
		endif	
		make/N=(row_num,column_num,1,sppoint_num)/O temp_rec_4D
		temp_rec_4D = temp_rec
		concatenate/NP=2 {temp_rec_4D},output
	endfor
	deletepoints/M=2 0,1,output
	
	
	//Delete unnecessary waves.
	killwaves global_2dwave, global_ext_w_w, global_reconstructed,temp_4dwave,layer_4dwave,temp_rec,temp_rec_4D
	//killwaves W_W, M_U, M_VT
end
	


function ImageBLC_3D(input)
	wave input
	variable row = dimsize(input,0)
	variable col = dimsize(input,1)
	variable z = dimsize(input,2)
	variable Sp = dimsize(input,3)
	
	make/N=(Sp) tempwave
	wave tempwave 
	variable i,j,k
	for(i=0;i<row;i+=1)
		for(j=0;j<col;j+=1)
			for(k=0;k<z;k+=1)
			tempwave += input[i][j][k][p]
			endfor
		endfor
	endfor
	
	variable tempmin = wavemin(tempwave) /(row*col*z)
	print tempmin
	input -= tempmin
	killwaves tempwave
end	