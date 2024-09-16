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
    %нормализация
    %I = uint8(255*mat2gray(I));
    %imshow(I);
    %äåëàåì ôóðüå ïðåîáðàçîâàíèå
    fftImage = fft2(I);
    %äåëàåì îêíî äëÿ ñãëàæèâàíèÿ, à äàëåå ïðîñòî ïî ýòîìó îêíó âñ¸ è
    %ñãëàæèâàåì. ïî ìîåìó îùóùåíèÿ,window = 1 -- ëó÷øå âñåãî ïîäõîäèò. Åñëè
    %âûáèðàòü window áîëüøå, òî áóäåò õóæå. 
    window = 1;
    fftImage(1:window, 1:window) = 0;
    fftImage(end-window:end, 1:window) = 0;
    fftImage(1:window, end-window:end) = 0;
    fftImage(end-window:end, end-window:end) = 0;
    centeredFFTImage = log(fftshift(real(fftImage)));
    %äåëàåì îáðàòíîå ôóðüå ïðåîáðàçîâàíèå -- ìîæíî íàáëþäàòü çà ýòèì
    %ôàéëîì.
    output = ifft2(fftImage);
    %imshow(output)
    %îäíî èç ñàìûõ âàæíûõ -- ïåðåâîäèì â real è ñòàâèì èíäåêñ -5, ãëàâíîå,
    %÷òîáû áûë îòðèöàòåëüíûé
    Ioi=real(output<-5);
    %çàïîëíÿåì ïóñòîòû
    Ioi=imfill(Ioi,'holes');
    %óáèðàåì ìàëåíüêèå îáúåêòû
    Ioi=bwareaopen(Ioi,200);
    %óáèðàåì îáúåêòû, êîòîðûå êàñàþòñÿ êðàåâ èçîáðàæåíèÿ
    Ioi = imclearborder(Ioi,4);
    %íàõîäèì âñå îñòàâøèåñÿ îáúåêòû è îñòàâëÿåì ñàìûé áîëüøîé! â ýòîì
    %îñíîâíîå íîâøåñòâî ïðîãðàììû
    graindata = regionprops(Ioi,'basic');
    grain_areas = [graindata.Area];
    max_value_of_rbc_agg=max(grain_areas);
    Ioi=bwareaopen(Ioi,max_value_of_rbc_agg-700);
     %imshow(Ioi);
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