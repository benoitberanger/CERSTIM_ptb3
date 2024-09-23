function cfg = cfgKeyboard()
% cross task keybinds

KbName('UnifyKeyNames') % make keybinds cross-platform compatible

cfg.Start = KbName('t');
cfg.Abort = KbName('escape');

end % fcn
