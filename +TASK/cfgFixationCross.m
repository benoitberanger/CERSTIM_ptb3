function cfg = cfgFixationCross()

cfg.Size     = 0.10;              %  Size_px = ScreenY_px * Size
cfg.Width    = 0.10;              % Width_px =    Size_px * Width
cfg.Color    = [127 127 127 255]; % [R G B a], from 0 to 255
cfg.Position = [0.50 0.50];       % Position_px = [ScreenX_px ScreenY_px] .* Position

end % fcn
