function Run()
global S
logger = getLogger();
logger.err('This is a demo script, dont use Logger in the realtime part of a task !')


%% start PTB engine

Window = PTB_ENGINE.VIDEO.Window();
Window.screen_id = max(Screen('Screens'));
Window.bg_color = [0 0 0]; % black background
Window.Open();


%% prepare rendering object

Checkerboard        = PTB_OBJECT.VIDEO.Checkerboard();
Checkerboard.window = Window;
Checkerboard.GenerateRects();


%% demo runtime

logger.warn('Press any key to Exit...');

max_iter = 100;
iter = 0;
while iter < max_iter
    iter = iter + 1;

    Checkerboard.DrawFlic();
    Window.Flip();
    WaitSecs(0.200);

    Checkerboard.DrawFlac();
    Window.Flip();
    WaitSecs(0.200);

    if KbCheck
        break
    end
end


%% END

Window.Close();


end % fcn
