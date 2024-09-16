%î÷èñòèì âñå ïåðåìåííûå, êîòîðûå åñòü
clear 
%óçíàåì ñêîëüêî âñåãî ôàéëîâ avi - ïåðåìåííàÿ áîëüøå íèêàê íå èñïîëüçóåòñÿ
u=dir('*.avi');
%%%%%%%%%%%%%%%%%%%%%%%% 
%èìÿ îáðàáàòûâàåìîãî ôàéëà
name_of_file='4.avi';
%%%%%%%%%%%%%%%%%%%%%%%%
%èçíà÷àëüíî íàø ôàéë
obj = VideoReader(name_of_file);
%êàêîé fps ó âèäåî è ñêîëüêî âñåãî êàäðîâ
FPS= obj.FrameRate;
numberOfFrames=round(obj.Duration*FPS)-1; 
t=linspace(1,numberOfFrames/FPS,numberOfFrames);
%ãëàâíûé ìàññèâ, êóäà âñ¸ áóäåò ñîõðàíÿòüñÿ
majorA=zeros(numberOfFrames,1);
%îáðåæèì âèäåî äëÿ ïåðâîãî êàäðà. äëÿ âñåõ îñòàëüíûõ áóäåì îáðàçàòü
%ñîîòâåòñòâåííî. íåîáõîäèìî íàæàòü ïðàâóþ êíîïêó è íàæàòü 'crop'
I_for_crop=read(obj,1);
[J, rect] = imcrop(I_for_crop);
%çàêðûâàåì îêíî
close all
%tic, ÷òîáû óçíàòü î âðåìåíè âûïîëíåíèÿ öèêëà
tic
%öèêë â êîòîðûì îáðàáàòûâàåòñÿ âñ¸ âèäåî
for i=1:numberOfFrames
    %÷èòàåì ôàéë
    I2=read(obj,i);
    %îáðåçàåì èçîáðàæåíèå
    I2=imcrop(I2, rect);
    %ïåðåâîäèì â ñåðîå ïðîñòàíñòâî
    I=rgb2gray(I2);
    I = uint8(255*mat2gray(I));
    I = imadjust(I);
    %нормализация

    fftImage = fft2(I);
    fftImage = fftshift(fftImage);
    window = 30;
    fftImage(int16(end/2):int16(end/2)+window, int16(end/2):int16(end/2)+window) = 0;
    fftImage(int16(end/2)-window:int16(end/2), int16(end/2)-window:int16(end/2)) = 0;
    fftImage(int16(end/2):int16(end/2)+window, int16(end/2)-window:int16(end/2)) = 0;
    fftImage(int16(end/2)-window:int16(end/2), int16(end/2):int16(end/2)+window) = 0;
    fftImage = ifftshift(fftImage);

    output = ifft2(fftImage);
    output = uint8(255*mat2gray(real(output)));

    Divided_image = I - output;
    Divided_image = imadjust(Divided_image);
    Ioi = Divided_image>10;
    Ioi=bwareaopen(Ioi,200);
    %Ioi = imclearborder(Ioi,4);
    %{
    %imshow(Divided_image>10)

    %çàïîëíÿåì ïóñòîòû
    Ioi=imfill(Ioi,'holes');
    %óáèðàåì ìàëåíüêèå îáúåêòû
    Ioi=bwareaopen(Ioi,200);
    Ioi = imclearborder(Ioi,4);
    
    imshow(Ioi)
    %}
    graindata = regionprops(Ioi,'basic');
    grain_areas = [graindata.Area];
    max_value_of_rbc_agg=max(grain_areas);
    Ioi=bwareaopen(Ioi,max_value_of_rbc_agg-700);
    imshow(Ioi);
    %äàëåå îðèåíòèðóåì îáúåêò âåðòèêàëüíî -- äàëåå â öèêëå
    angNorm= regionprops(Ioi,'Orientation');
    angNorm= struct2cell(angNorm);
    angNorm= cell2mat(angNorm);
    if isempty(angNorm)==0
        angNorm=angNorm(1);
        Ioi=imrotate(Ioi,90-angNorm);
        %íàõîäèì ýêñòðåìóìû
        Ext= regionprops(Ioi,'Extrema');
        Ext= struct2cell(Ext);
        Ext= cell2mat(Ext);
        %çàïèñûâàåì ýêñòðåìóì òàêèì îáðàçîì, ÷òî majorA -- ýòî òî, ÷òî íàì
        %íàäî
        majorA(i,1)=max(Ext(:,2))-min(Ext(:,2));
        save(sprintf('majorAxis.mat'), 'majorA');
    else
        continue;
    end
end
toc

%åñëè âåðñèÿ ìàòëàáà R2022a èëè ïîçæå, èñïîëüçóåòå "curveFitter" âìåñòî "cftool"
cftool(t,majorA)
%îòîáðàçèòü çíà÷åíèÿ íà ãðàôèêå
%Func_for_fitting=majorA;
%Func_for_fitting(Func_for_fitting<10)=NaN;
%figure(1),plot(t,Func_for_fitting,'+r'),title('Major axis as a function of time'),xlabel('time (s)'),ylabel('Length(px)');