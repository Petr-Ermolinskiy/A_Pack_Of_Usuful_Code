clear 
u=dir('*.avi');
%%%%%%%%%%%%%%%%%%%%%%%% 
name_of_file='3.avi';
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
for i=1:numberOfFrames

    I=read(obj,i);

    I=imcrop(I, rect);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    I=rgb2gray(I);
    I = uint8(255*mat2gray(I));
    I = imadjust(I);
    
    [~,threshold] = edge(I,'sobel');
    fudgeFactor = 1.0;
    image_ = edge(I,'sobel',threshold * fudgeFactor);
    
    se90 = strel('line',3,90);
    se0 = strel('line',3,0);

    image_ = imdilate(image_,[se90 se0]);
    image_ = bwareaopen(image_,1000);
    image_ = imclearborder(image_,4);

    image_ = imfill(image_,'holes');
    
    angNorm = cell2mat(struct2cell(regionprops(image_,'Orientation')));

    if isempty(angNorm)==0
       image_=imrotate(image_,0-angNorm(1));
    end

    dop_massive=regionprops(image_,"BoundingBox");
    dop_massive= transpose(struct2cell(dop_massive));
    dop_massive = cell2mat(dop_massive);
    
    [majorA(i,1), index] = max(dop_massive(:,3));
    
    image_ = im2single(image_);
    image_=insertShape(image_,"rectangle",dop_massive(index,:),LineWidth=2);
    
    imshow(image_)

end
toc

cftool(t,majorA)