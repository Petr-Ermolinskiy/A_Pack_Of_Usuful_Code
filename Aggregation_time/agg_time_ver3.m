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
for i=1:numberOfFrames

    I=read(obj,i);
    I=imcrop(I, rect);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    I=rgb2gray(I);
    I = uint8(255*mat2gray(I));
    I = imadjust(I);
    
    fftImage = fft2(I);

    a = size(fftImage);
    factor = 7;
    window = floor(a(1)/factor);
    window_l = floor(a(2)/factor);
    
    fftImage(1:window, 1:window_l) = 0;
    fftImage(end-window:end, 1:window_l) = 0;
    fftImage(1:window, end-window_l:end) = 0;
    fftImage(end-window:end, end-window_l:end) = 0;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    output = ifft2(fftImage);
    II = uint8(255*mat2gray(real(output)));

    Divided_image = I - II;
    Divided_image = imadjust(Divided_image);
    %%%%%%%%%%%%%%%%%%%
    Divided_image = Divided_image>0;

    Divided_image=~Divided_image;
    Divided_image=bwareaopen(Divided_image,20000);
    Divided_image = imclearborder(Divided_image,4);
    
    angNorm = cell2mat(struct2cell(regionprops(Divided_image,'Orientation')));
    
    dop_massive=regionprops(Divided_image,"BoundingBox");
    dop_massive= transpose(struct2cell(dop_massive));
    dop_massive = cell2mat(dop_massive);
    [empty_, index] = max(dop_massive(:,3));

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

end
toc

cftool(t,majorA)