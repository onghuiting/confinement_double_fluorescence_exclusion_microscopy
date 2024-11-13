

// This macro generates height map stacks from intensity stacks in batch.
//
// To convert intensity to delta_height:
// delta_I = beta*delta_height
// delta_height = (I-black_int)/beta
// delta_height = 10um - Hc
// Hc = 10um - delta_height
//
// In this version, Imin (black_int) = 0.
//
// Written by hui ting, 31 July 2024.


//////////////////////////////////////////////////////////////////////////////////////////////////////////

delta_height_max = 10;  // 10um is the maximum height

/////////////////////////////////////////////////////////////////////////////////////////////////////////

pathname = getDirectory("Select your input folder");
list = getFileList(pathname);
total_files = list.length;

for (ifile = 0; ifile < total_files; ifile++) {
	
	if (endsWith(list[ifile], "_c1_corrected.tif")){
		
	filename_c1_corrected = list[ifile];
	filename_channel_mask = replace(filename_c1_corrected, "_c1_corrected.tif", "_channel_mask.tif");
	filename_out = replace(filename_c1_corrected, "_c1_corrected.tif", "_");

// Find b for each frame and find black_int for each frame
roiManager("reset");
open(pathname+filename_c1_corrected);
rename("c1_corrected");
Stack.getDimensions(width, height, channels, slices, frames);

open(pathname+filename_channel_mask);
rename("channel_mask");
run("Make Inverse");
roiManager("Add");

run("Set Measurements...", "median redirect=None decimal=4");
selectWindow("c1_corrected");
roiManager("Deselect");
roiManager("Multi Measure");
run("Select None");

max_int = Table.getColumn("Median1");

close("channel_mask");

beta = newArray(frames);

for (i = 1; i <= frames; i++) {

beta[i-1] = max_int[i-1]/delta_height_max;

selectWindow("c1_corrected");
run("Duplicate...", "title=temp"+" duplicate range="+i+"-"+i);

run("Conversions...", " ");
run("32-bit");

run("Divide...", "value="+beta[i-1]);
run("Enhance Contrast", "saturated=0.35");

//rename("delta_h");
//run("Duplicate...", "title=Hc");

run("Multiply...", "value=-1");   // Hc = 10um - delta_height
run("Add...", "value="+delta_height_max);

run("Min...", "value=0");   // all negative height values are set to 0
rename(i);

}

run("Images to Stack", "name=Hc use");
saveAs("Tiff", pathname+filename_out+"Hc.tif");
run("Close All");

Table.setColumn("beta", beta);
saveAs("Results", pathname+filename_out+"beta.csv");
run("Close");

roiManager("reset");

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		
	}
	
}




