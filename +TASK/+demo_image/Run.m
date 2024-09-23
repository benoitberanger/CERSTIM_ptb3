function Run()
global S
logger = getLogger();
logger.err('This is a demo script, dont use Logger in the realtime part of a task !')


%% image path

image_path = fileparts(mfilename('fullpath'));
img_no_transparency  = fullfile(image_path,'face_no-transparency.jpg');
img_with_tranparency = fullfile(image_path,'face_with-transparency.png');


%% start PTB engine

Window = PTB_ENGINE.VIDEO.Window();
Window.screen_id = max(Screen('Screens'));
Window.Open();


%% prepare rendering object

ImageWithTransparency = PTB_OBJECT.VIDEO.Image();
ImageWithTransparency.window = Window;
ImageWithTransparency.filename = img_with_tranparency;
ImageWithTransparency.Load();
% ImageWithTransparency.Plot()
ImageWithTransparency.MakeTexture();

ImageNoTransparency = PTB_OBJECT.VIDEO.Image();
ImageNoTransparency.window = Window;
ImageNoTransparency.filename = img_no_transparency;
ImageNoTransparency.Load();
% ImageNoTransparency.Plot()
ImageNoTransparency.MakeTexture();


%% demo runtime

ImageWithTransparency.ScaleToMax();
ImageWithTransparency.Move(Window.size_x*0.25, Window.size_y*0.50);
ImageWithTransparency.Draw();

ImageNoTransparency.ScaleToMax();
ImageNoTransparency.Move(Window.size_x*0.75, Window.size_y*0.50);
ImageNoTransparency.Draw();

Window.Flip();


%% END


ImageWithTransparency.Close();
ImageNoTransparency.Close();
logger.warn('Press any key to Exit...');
KbWait();
Window.Close();


end % fcn
