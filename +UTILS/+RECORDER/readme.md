# Class hierarchy
Classes in _italic_ are 'virtual' and should not be instanciated, except for debugging

- _Base_
    - **Double** : record purely numerical stuff (in a matrix), like joystick X and Y position
    - **Cell** : to record anything (in a cell)
        - _Stim_ : all subclasses are intended to work together, with plotDelay and plotStim functions.
            - **Planning** : register events with theoritical onset and duration
            - **Event** : register the events from **Planning** but with their real onset and duration, for later diagnostic
            - **Keylogger** : log all key pressed, including MRI trigger (in parallel to the task execution)

# Utils
```matlab
UTILS.plotDelay( planning , event )
UTILS.plotStim( planning , event , keylogger )
```
