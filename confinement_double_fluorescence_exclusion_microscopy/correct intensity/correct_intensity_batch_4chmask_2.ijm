

// This macro is to correct intensity using background intensity profile, so that intensity along x is homogeneous.
// For non-channel region, the "bg_img" has values of 1, so that, the original values are kept when dividing by the 
// "bg_img". No correction done for non-channel region.
// 
// Before running this macro, please run "get_background_profile_batch.ijm".
// The input folder for this macro should be the output folder of "get_background_profile_batch.ijm".
//
// This version subtracts Imin first.
//
// Written by hui ting, 31 July 2024.


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


pathname = getDirectory("Select your input folder");

list = getFileList(pathname);
total_files = list.length;


for (ifile = 0; ifile < total_files; ifile++) {
	
	if (endsWith(list[ifile], "_rectangle_roi.tif")){
		
    filename_roi = list[ifile];   
    filename_bg = replace(list[ifile], "_rectangle_roi.tif", "_background_profile.tif");
    filename_out = replace(list[ifile], "_rectangle_roi.tif", "_"); 
    filename_ch_mask = replace(list[ifile], "_rectangle_roi.tif", "_channel_mask.tif");
    
	open(pathname+filename_bg);
	rename("bg_prof");
	open(pathname+filename_ch_mask);
    rename("channel_mask");    
    roiManager("reset");
    roiManager("Add");
	open(pathname+filename_roi);
	rename("input");
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////		
		
run("Select None");
run("Duplicate...", "title=c1 duplicate channels=1");
frames = nSlices;

for  (fr=1; fr<=frames; fr++){

selectWindow("c1");
setSlice(fr);
roiManager("Select", 0);
black_int = getValue("Median");
run("Select None");
run("Subtract...", "value="+black_int+" slice");

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

selectWindow("input");
run("Duplicate...", "title=c4 duplicate channels=4");
Stack.getDimensions(width, height, channels, slices, frames);

newImage("bg_img", "32-bit black", width, height, 1);

selectWindow("bg_prof");
run("Select All");
run("Copy");

setBatchMode(true);
for (row = 0; row <= height; row++) {

selectWindow("bg_img");
makeRectangle(0, row, width, 1);
run("Paste");

}
setBatchMode(false);

/////////////////////////////////////////////////////////////////////////////////////////////

selectWindow("channel_mask");
roiManager("Select", 0);
run("Copy");

selectWindow("bg_img");
roiManager("Select", 0);
run("Paste");
run("Select None");
run("Fire");
run("Enhance Contrast", "saturated=0.35");

imageCalculator("Divide create 32-bit stack", "c1","bg_img");

///////////////////////////////////////////////////////////////////////////////////////////////////

selectWindow("Result of c1");
saveAs("Tiff", pathname+filename_out+"c1_corrected.tif");
selectWindow("bg_img");
saveAs("Tiff", pathname+filename_out+"bg_img.tif");
selectWindow("channel_mask");
saveAs("Tiff", pathname+filename_out+"channel_mask.tif");
selectWindow("input");
run("Duplicate...", "title=c2 duplicate channels=2");
saveAs("Tiff", pathname+filename_out+"GFP.tif");
run("Close All");
roiManager("reset");

	}
}






