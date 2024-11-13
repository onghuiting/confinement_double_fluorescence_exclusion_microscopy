
         
function write32bit(data, filename)

         imdata=single(data); % make your data "single"
 
         t = Tiff(filename,'w'); % define your filename       
         t.setTag('ImageLength',size(imdata,1)); % size of imdata
         t.setTag('ImageWidth', size(imdata,2)); % size of imdata
         
         % just copy
         t.setTag('Photometric', Tiff.Photometric.LinearRaw);
         t.setTag('SampleFormat', Tiff.SampleFormat.IEEEFP);
         t.setTag('BitsPerSample', 32);       
         t.setTag('SamplesPerPixel', 1);
         t.setTag('Compression', Tiff.Compression.None);
         t.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
         
         t.write(imdata); % write imdata
         t.close();
         
end