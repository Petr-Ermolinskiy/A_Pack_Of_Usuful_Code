% In this script, the brownian motion of RBC is tracking using cellpose
% library
% see https://www.mathworks.com/matlabcentral/fileexchange/130629-medical-imaging-toolbox-interface-for-cellpose-library

% Also, you need to have @msdanalyzer to run this script:
% see https://tinevez.github.io/msdanalyzer/tutorial/MSDTuto_brownian.html

function [t, pX, pY] = calc_t_px_py(file)
obj=VideoReader(file);
%
FPS=obj.FrameRate;
numberOfFrames=round(obj.Duration*FPS)-1; 
t=linspace(1,numberOfFrames/FPS,numberOfFrames);
t=transpose(t-1);

pX=zeros(numberOfFrames,1);
pY=zeros(numberOfFrames,1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
I_for_crop=read(obj,1);
[~, rect] = imcrop(I_for_crop);
%close it all after determining the rectangle 
close all
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic
f = waitbar(0, 'Starting');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=1:numberOfFrames
    I=read(obj,i);
    I=imcrop(I, rect);
    I=rgb2gray(I);
    I = imadjust(I);
    % cellpose model cyto2
    cp = cellpose(Model="cyto2", ExecutionEnvironment="gpu");
    averageCellDiameter = 200;
    
    segmented_mask = segmentCells2D(cp,I,ImageCellDiameter=averageCellDiameter,CellThreshold=2.0);
    
    %mask_plus_I = labeloverlay(I,segmented_mask, 'Transparency',0.6);
    %imshow(mask_plus_I)

    u=regionprops(segmented_mask,'Centroid');
    
    u=struct2array(u);
    
    pX(i)=u(1);
    pY(i)=u(2);
    
    waitbar(i/numberOfFrames, f, sprintf('Progress: %d %%', floor(i/numberOfFrames*100)));
end
close(f)
toc
end