

// This macro gets background profiles in batch. 
// The input folder should consist of multiple .tif files.
// Each .tif file is a 4 channel movie, with a rectangle ROI on it.
//
// Before running this macro, make sure each input file in the folder is saved with ROI prepared as follows:
// Draw a rectangle ROI along the narrow channel, the ROI should start from x = 0, with width = x dimension of image and 
// height of 3 pixels. (Use Edit -> Selection -> Specify)
//
// Intensity profile with thickness (height) of 3 pixels, is to get average along y for reducing outliers.
// Alternatively, do median or mean filtering (with radius = 1 pixel) on image, before getting line profile.
// * Project along all y is not good.
//
// If the background intensity profile generated is not correct, use a substack with sparse cells (instead of the whole original stack), 
// to generate background intensity profile.
//
// This version subtracts Imin first.
//
// Written by hui ting, 31 July 2024.


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

c = 4;  // channel for background profile estimation (Dextran)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pathname = getDirectory("Choose input directory");
list = getFileList(pathname);
total_files = list.length;
dir_res = pathname+"Results";
File.makeDirectory(dir_res);

run("Clear Results");

for (ifile = 0; ifile < list.length; ifile++) {
	
	if (endsWith(list[ifile], ".tif")){
		
	open(pathname+list[ifile]);
	rename(list[ifile]);
		
name = getTitle;
Stack.getDimensions(width, height, channels, slices, frames);
run("Properties...", "channels="+channels+" slices="+slices+" frames="+frames+" unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1");


///////////////////////////////////  channel mask and subtract Imin from c4 ////////////////////////////////////////////

roiManager("reset");
roiManager("Add");
run("Select None");
run("Duplicate...", "title=c4 duplicate channels=4");
rename("c4");
run("Z Project...", "projection=Median");
//run("Median...", "radius=3");
setOption("ScaleConversions", true);
run("8-bit");
run("Auto Threshold", "method=Otsu white");
//run("Auto Threshold", "method=RenyiEntropy white");
run("Options...", "iterations=10 count=1 black pad do=Close");
run("Options...", "iterations=2 count=1 black pad do=Dilate");
run("Invert");
run("Divide...", "value=255");
setMinAndMax(0, 1);

selectWindow("MED_c4");
setThreshold(1, 1, "raw");
run("Create Selection");

for  (fr=1; fr<=frames; fr++){

selectWindow(name);
Stack.setChannel(c);
Stack.setFrame(fr);
run("Restore Selection");
black_int = getValue("Median");
run("Select None");
run("Subtract...", "value="+black_int+" slice");

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Table.create("Intensity_profile");
Table.showRowNumbers(false);
Table.showRowIndexes(false);
Table.saveColumnHeader(0);

median_value = newArray(frames);

selectWindow(name);
roiManager("Select", 0);

setBatchMode(true);

for  (fr=1; fr<=frames; fr++){

selectWindow(name);
Stack.setChannel(c);
Stack.setFrame(fr);
run("Plot Profile");
Plot.getValues(x, y);
run("Close");

median_value[fr-1] = get_median(y);
y_divby_med = newArray(x.length);
  
for (iii=0; iii<x.length; iii++){
 
  y_divby_med[iii] = y[iii]/median_value[fr-1];
  Table.set("y_c"+c+"_f"+fr, iii, y_divby_med[iii]);
   
}
}

Table.update;
  
selectWindow("Intensity_profile");
saveAs("Results", dir_res+File.separator+name+"_intensity profile.csv");
run("Close");

selectWindow(name);
saveAs("Tiff", dir_res+File.separator+name+"_rectangle_roi.tif");


/////////////////////////////////////////////////////////////////////////////////////


run("Text Image... ", "open=["+dir_res+File.separator+name+"_intensity profile.csv]");
rename("int_prof_txt_img");

run("Reslice [/]...", "output=1.000 start=Left avoid");
run("Z Project...", "projection=Median");
rename("median_int_prof");

run("Select All");
run("Plot Profile");

selectWindow("median_int_prof");
run("Mean...", "radius=5");
run("Morphological Filters", "operation=Opening element=Disk radius=15");
run("Morphological Filters", "operation=Closing element=Disk radius=15");
run("Mean...", "radius=5");
run("Select All");
run("Plot Profile");

saveAs("Tiff", dir_res+File.separator+name+"_plot_background_profile.tif");

selectWindow("median_int_prof-Opening-Closing");
saveAs("Tiff", dir_res+File.separator+name+"_background_profile.tif");

selectWindow("MED_c4");
saveAs("Tiff", dir_res+File.separator+name+"_channel_mask.tif");
run("Close All");
roiManager("reset");

	}
}



/////////////////////////////////////////////////////////////////////////////


function get_median(a) {
	
sortedValues = Array.copy(a);
Array.sort(sortedValues);

arr_lg = a.length;
if (arr_lg%2 == 1){
arr_md_idx = floor(arr_lg/2);
median_arr = sortedValues[arr_md_idx];
}
else {
arr_md_idx1 = arr_lg/2;
arr_md_idx2 = arr_md_idx1-1;
median_arr = (sortedValues[arr_md_idx1]+sortedValues[arr_md_idx2])/2;
}

return median_arr;

}


