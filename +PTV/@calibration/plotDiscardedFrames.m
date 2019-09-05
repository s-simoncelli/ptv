function h = plotDiscardedFrames(this)
%Plot frames where the checkerboard corners were not fully detected.

    
    I = find(this.imagesUsed == false);
    h = zeros(1, length(I));
    for i=1:length(I)
        
        frameIdx = I(i)
        image.leftFrame = imread(this.imagesLeftAll{frameIdx});
        image.rightFrame = imread(this.imagesRightAll{frameIdx});
        
        image.merged = cat(2, image.leftFrame, image.rightFrame);
        image.merged = insertObjectAnnotation(image.merged, 'rectangle', [0 0 20 20], ...
            sprintf('Frame #%d', frameIdx), 'FontSize', 50);
        
        h(i) = figure;
        imshow(image.merged, 'InitialMagnification', 50);
    end
end

