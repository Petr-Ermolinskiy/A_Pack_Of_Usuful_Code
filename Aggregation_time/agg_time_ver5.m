clear 
u=dir('*.avi');
%%%%%%%%%%%%%%%%%%%%%%%% 
name_of_file='4.avi';
%%%%%%%%%%%%%%%%%%%%%%%%
obj = VideoReader(name_of_file);
FPS= obj.FrameRate;
numberOfFrames=round(obj.Duration*FPS)-1; 
t=linspace(1,numberOfFrames/FPS,numberOfFrames);
majorA=zeros(numberOfFrames,1);

I_for_crop=read(obj,1);
[J, rect] = imcrop(I_for_crop);
close all


tic
f = waitbar(0, 'Starting');
for i=1:numberOfFrames
    
    waitbar(i/numberOfFrames, f, sprintf('Progress: %d %%', floor(i/numberOfFrames*100)));

    I=read(obj,i);
    I=imcrop(I, rect);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    I=rgb2gray(I);
    I = uint8(255*mat2gray(I));
    I = imadjust(I);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % cellpose model cyto2
    cp = cellpose(Model="cyto2", ExecutionEnvironment="gpu",UseEnsemble=true);
    averageCellDiameter = 100;
    
    Divided_image = segmentCells2D(cp,I,ImageCellDiameter=averageCellDiameter,CellThreshold=0,FlowErrorThreshold=0.3,TileOverlap=0.2,TileAndAugment=true);

    mask_plus_I = labeloverlay(I,Divided_image, 'Transparency',0.85);
    
    imshow(mask_plus_I)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %{
    angNorm = cell2mat(struct2cell(regionprops(Divided_image,'Orientation')));
    %{
    dop_massive=regionprops(Divided_image,"BoundingBox");
    dop_massive= transpose(struct2cell(dop_massive));
    dop_massive = cell2mat(dop_massive);
    [empty_, index] = max(dop_massive(:,3));
    %}
    [empty_, index] = max(angNorm);

    if isempty(angNorm)==0
       Divided_image=imrotate(Divided_image,0-angNorm(index));
    end

    dop_massive=regionprops(Divided_image,"BoundingBox");
    dop_massive= transpose(struct2cell(dop_massive));
    dop_massive = cell2mat(dop_massive);
    [majorA(i,1), index] = max(dop_massive(:,3));
    
    Divided_image = im2single(Divided_image);
    Divided_image=insertShape(Divided_image,"rectangle",dop_massive(index,:),LineWidth=2);
    
    %imshow(Divided_image)
    
    %}
end
toc

cftool(t,majorA)