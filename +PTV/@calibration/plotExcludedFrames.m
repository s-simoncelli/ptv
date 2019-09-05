function h = plotExcludedFrames(this)
%Plot frames that were excluded withthe  'Exclude' option.

    for i=1:length(this.Exclude)
        frameIdx = this.findFrameById(this.Exclude(i), this.fileNamesAll);
        image.leftFrame = imread(this.imagesLeftAll{frameIdx});
        image.rightFrame = imread(this.imagesRightAll{frameIdx});
        
        image.merged = cat(2, image.leftFrame, image.rightFrame);
        image.merged = insertObjectAnnotation(image.merged, 'rectangle', [0 0 20 20], ...
            sprintf('Frame #%d', frameIdx), 'FontSize', 50);
        
        h(i) = figure;
        imshow(image.merged, 'InitialMagnification', 50);
    end
end

