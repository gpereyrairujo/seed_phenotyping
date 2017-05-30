////////////////////////////////////////////////////////////////////////
// IJ_Seed
// ImageJ macro for detecting germinated seeds based on geometry
// Author: Gustavo Pereyra Irujo - pereyrairujo.gustavo@conicet.gov.ar
// Licensed under GNU GENERAL PUBLIC LICENSE Version 3
// https://github.com/gpereyrairujo/seed_phenotyping
//
// version 0.11 - May 2017
//

setBatchMode(true);  // <---- Do not show processing steps

orig=getTitle();

// 1. Pre-processing ------------------------------------------------------
//    1.1. Set scale in mm
//    1.2. Color correction
//    1.3. Cropping of the area of interest

// 1.1. Set scale in mm
// This value is for the v1 lightbox and the olympus camera
// It should be set interactively in future versions
scalemm=2000/100;
run("Set Scale...", "distance="+scalemm+" known=1 unit=mm global");


// 1.2. Color correction
// This correction is fixed and corresponds to the v1 lightbox and the olympus camera
// It could be replaced with a color chart based correction in future versions
run("Split Channels");
selectWindow(orig+" (red)");
rename("red");
selectWindow(orig+" (green)");
rename("green");
run("Multiply...", "value=0.847");
selectWindow(orig+" (blue)");
rename("blue");
run("Multiply...", "value=.463");
run("Merge Channels...", "c1=red c2=green c3=blue");
rename(orig);

// 1.3. Cropping of the area of interest
// This step needs to be improved in order to automatically detect the blue area
run("Duplicate...", "title=Original duplicate");
selectWindow(orig);
//makeRectangle(1158, 720, 1974, 1812);
makeRectangle(1122, 786, 1932, 1806);
//run("Crop");
run("Colors...", "foreground=black background=blue selection=red");
run("Clear Outside");
run("Colors...", "foreground=black background=white selection=red");
run("Select None");


// 2. Selection of blue regions (~paper) ------------------------------------
//    2.1. Color thresholding: all blueish regions -> 'P'
//    2.2. Color thresholding: strictly blue regions -> 'P2'

// 2.1. Color thresholding: all blueish regions
selectWindow(orig);
run("Duplicate...", "title=P duplicate");
min=newArray(3);
max=newArray(3);
filter=newArray(3);
//a=getTitle();
run("HSB Stack");
run("Convert Stack to Images");
selectWindow("Hue");
rename("0");
selectWindow("Saturation");
rename("1");
selectWindow("Brightness");
rename("2");
min[0]=150;
max[0]=175;
filter[0]="pass";
min[1]=60;
max[1]=255;
filter[1]="pass";
min[2]=0;
max[2]=255;
filter[2]="pass";
for (i=0;i<3;i++){
  selectWindow(""+i);
  setThreshold(min[i], max[i]);
  run("Convert to Mask");
  if (filter[i]=="stop")  run("Invert");
}
imageCalculator("AND create", "0","1");
imageCalculator("AND create", "Result of 0","2");
for (i=0;i<3;i++){
  selectWindow(""+i);
  close();
}
selectWindow("Result of 0");
close();
selectWindow("Result of Result of 0");
rename("P");
run("Invert");

// 2.2. Color thresholding: strictly blue regions
selectWindow(orig);
run("Duplicate...", "title=P2 duplicate");
min=newArray(3);
max=newArray(3);
filter=newArray(3);
//a=getTitle();
run("HSB Stack");
run("Convert Stack to Images");
selectWindow("Hue");
rename("0");
selectWindow("Saturation");
rename("1");
selectWindow("Brightness");
rename("2");
min[0]=155;
max[0]=170;
filter[0]="pass";
min[1]=90;
max[1]=255;
filter[1]="pass";
min[2]=0;
max[2]=255;
filter[2]="pass";
for (i=0;i<3;i++){
  selectWindow(""+i);
  setThreshold(min[i], max[i]);
  run("Convert to Mask");
  if (filter[i]=="stop")  run("Invert");
}
imageCalculator("AND create", "0","1");
imageCalculator("AND create", "Result of 0","2");
for (i=0;i<3;i++){
  selectWindow(""+i);
  close();
}
selectWindow("Result of 0");
close();
selectWindow("Result of Result of 0");
rename("P2");
run("Invert");

// 3. Find seeds -------------------------------------------------------
//    3.1. Fill holes and erase roots -> 'S'
//    3.2. Find seeds and store coordinates -> 'M'
//    3.3. Define areas for each seed -> 'A'
//    3.4. Separate seeds in 'S' in different areas
//    3.5. Decrease the size of seeds
//    3.6. Re-enlarge the seeds

// 3.1. Fill holes and erase roots
run("Duplicate...", "title=S duplicate");
// fill small holes
for(i=0;i<3;i++){
	run("Dilate");
}
for(i=0;i<3;i++){
	run("Erode");
}
// erase small blobs and thin sections (roots)
run("Create Selection");
for(i=0;i<10;i++){
	run("Erode");
}
// refill
for(i=0;i<20;i++){
	run("Dilate");
}
run("Select None");


// 3.2. Find seeds and store coordinates
run("Duplicate...", "title=M duplicate");
run("Distance Map");
run("Find Maxima...", "noise=10 output=[Point Selection] light");
if(selectionType()>-1){
	getSelectionCoordinates(xCoordinates, yCoordinates);
	count=xCoordinates.length;
}
run("Select None");


// 3.3. Define areas for each seed
// create a blank image with the same size
selectWindow("S");
run("Duplicate...", "title=A duplicate");
run("Select All");
run("Clear");
run("Select None");
// draw one point at the center position of each seed
for(i=0;i<count;i++) {
	setPixel(xCoordinates[i],yCoordinates[i],255);
}
// isolate objects
run("Voronoi");
setThreshold(1, 255);
run("Convert to Mask");
run("Invert");

// 3.4. Separate seeds in 'S' in different areas
imageCalculator("AND", "S","A");

// 3.5. Decrease the size of seeds
p=Array.copy(xCoordinates);
for(i=0;i<count;i++) {
	// Find the maximum distance to the background in each seed from 'M'
	selectWindow("M");
	p[i]=getPixel(xCoordinates[i],yCoordinates[i]);
	// Divide this distance by 2
	v=p[i]/2;
	// Find the seed in 'S' and copy that selection to 'M'
	selectWindow("S");
	doWand(xCoordinates[i],yCoordinates[i]);
	selectWindow("M");
	run("Restore Selection");
	// Subtract so that areas farther from the seed center have negative values
	run("Subtract...", "value="+v);
}
run("Select None");
setThreshold(1,255);
run("Convert to Mask");

// 3.6. Re-enlarge the seeds
selectWindow("S");
run("Select All");
run("Clear");
run("Select None");
for(i=0;i<count;i++) {
	// find the reduced seeds in 'M'
	selectWindow("M");
	v=p[i]/2;
	doWand(xCoordinates[i],yCoordinates[i]);
	// enlarge the selection and transfer it to 'S'
	run("Enlarge...", "enlarge="+v+" pixel");
	selectWindow("S");
	run("Restore Selection");
	setForegroundColor(0);
	run("Fill", "slice");	
}
run("Select None");



// 4. Identify roots --------------------------------------------------------
//    4.1. Subtract the seeds from the initial segmentation -> 'R'
//    4.2. 'Clean' roots
//    4.3. Separate roots in different areas -> 'R2'
//    4.4. Merge roots and seeds -> 'SR'


// 4.1. Subtract the seeds from the initial segmentation
imageCalculator("Subtract create", "P","S");
selectWindow("Result of P");
rename("R");

// 4.2. 'Clean' roots
// erase small blobs (noise)
run("Create Selection");
for(i=0;i<2;i++){
	run("Erode");
}
// refill roots
for(i=0;i<6;i++){
	run("Dilate");
}
run("Select None");

// 4.3. Separate roots in different areas
imageCalculator("AND create", "R","A");
selectWindow("Result of R");
rename("R2");

// 4.4. Merge roots and seeds
imageCalculator("OR create", "S","R2");
selectWindow("Result of S");
rename("SR");

// 5. Identify germinated seeds -----------------------------------------------------------
//    5.1. Select the bottom half of the seeds
//    5.2. Find the roots connected to each seed
//    5.3. Select roots longer than 2mm
//    5.4. Assign germinated/non-germinated values to seeds -> 'S3'


// 5.1. Select the bottom half of the seeds
// (this is a way to avoid identifying seeds as germinated when a root from other seed is touching it - definitely could be improved!)

// draw a line through the middle of each seed
for(i=0;i<count;i++) {
x=xCoordinates[i];
y=yCoordinates[i]-1;
p=getPixel(x,y);
for(x=xCoordinates[i];p==255;x++){
	p=getPixel(x,y);
	setPixel(x,y,0);	
}
x=xCoordinates[i]-1;
y=yCoordinates[i]-1;
p=getPixel(x,y);
for(x=xCoordinates[i]-1;p==255;x--){
	p=getPixel(x,y);
	setPixel(x,y,0);	
}
}
// fill the bottom part of seeds and roots with value 1
for(i=0;i<count;i++) {
setColor(1);
floodFill(xCoordinates[i],yCoordinates[i]);
}
run("Glasbey");

// 5.2. Find the roots connected to each seed
imageCalculator("Min create", "SR","R");
selectWindow("Result of SR");
rename("R3");
setThreshold(1, 254);
run("Convert to Mask");

// 5.3. Select roots longer than 2mm
// (criterion for considering a seed as germinated - can be adjusted according to species, etc.)
selectWindow("S");
run("Duplicate...", "title=S2");
run("Create Selection");
run("Enlarge...", "enlarge=2"); // create selection 2mm larger than seeds
selectWindow("R3"); 
run("Duplicate...", "title=R4");
run("Restore Selection"); // copy selection to roots
run("Clear", "slice"); // clear roots closest to seeds
run("Select None");
// find roots and store coordinates
selectWindow("R4");
run("Find Maxima...", "noise=10 output=[Point Selection] light");
if(selectionType()>-1){
	getSelectionCoordinates(xCoordR, yCoordR);
	countR=xCoordR.length;
	noRoots=false;
}
else{
	noRoots=true;
}
run("Select None");

// 5.4. Assign germinated/non-germinated values to seeds
// fill areas containing roots with value 2
// and areas without roots with value 1
selectWindow("A");
run("Divide...", "value=255");
if(noRoots==false){
	for(i=0;i<countR;i++) {
	setColor(2);
	floodFill(xCoordR[i],yCoordR[i]);
	}	
}
run("Glasbey");
// copy color values to seeds
selectWindow("S");
run("Duplicate...", "title=S3 duplicate");
run("Divide...", "value=255");
run("Glasbey");
imageCalculator("Multiply", "S3","A");

// 6. Create final results image --------------------------------------------------
//    6.1. Add roots to the 'S3' image
//    6.2. Close all other images
//    6.3. Merge original and result images side-by-side

// 6.1. Add roots to the 'S3' image
// add complete roots with value 3
selectWindow("R3");
run("Divide...", "value=255");
run("Multiply...", "value=3");
run("Glasbey");
imageCalculator("Add", "S3","R3");
// add long root sections with value 4
selectWindow("R4");
run("Divide...", "value=255");
run("Multiply...", "value=4");
run("Glasbey");
imageCalculator("Add", "S3","R4");

// 6.2. Close all other images
selectWindow("P");
run("Close");
selectWindow("P2");
run("Close");
selectWindow("S");
run("Close");
selectWindow("A");
run("Close");
selectWindow("R");
run("Close");
selectWindow("R2");
run("Close");
selectWindow("R3");
run("Close");
selectWindow("R4");
run("Close");
selectWindow("S2");
run("Close");
selectWindow("SR");
run("Close");
selectWindow("M");
run("Close");
selectWindow(orig);
run("Close");
//selectWindow("S3");
//rename(orig);

// 6.3. Merge original and result images side-by-side
run("Images to Stack", "name=Stack title=[] use");
run("Make Montage...", "columns=2 rows=1 scale=0.5 first=1 last=2 increment=1 border=0 font=12");
selectWindow("Stack");
run("Close");
selectWindow("Montage");
rename(orig);

// 7. Measure germinated/non-germinated seeds -----------------------------------------
run("Set Measurements...", "area mean centroid shape display redirect=None decimal=3");
for(i=0;i<count;i++) {
doWand(xCoordinates[i],yCoordinates[i]);
run("Measure");
}
run("Select None");

// End ----------------------------------------------------------------------------

setBatchMode(false);
