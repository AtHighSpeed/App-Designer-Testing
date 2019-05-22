classdef app2 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        StartButton               matlab.ui.control.StateButton
        SumEditFieldLabel         matlab.ui.control.Label
        SumEditField              matlab.ui.control.NumericEditField
        TexttosendEditFieldLabel  matlab.ui.control.Label
        TexttosendEditField       matlab.ui.control.EditField
        SendButton                matlab.ui.control.Button
        SerialPortDropDownLabel   matlab.ui.control.Label
        SerialPortDropDown        matlab.ui.control.DropDown
        TextAreaLabel             matlab.ui.control.Label
        TextArea                  matlab.ui.control.TextArea
    end

    
    % Variable initialization
    properties (Access = public)
        iTextBox = 0; % Cell array size of TextArea
        i_sum = 0; % Variable that stores the sum value
        sumTrigger = 0; % Trigger variable for stoping the sum
        ArduinoMess = ''; % String variable that stores the message to Arduino IDO
        serialVar; % Variable for serial port communication
        sendTrigger = 0; % Trigger variable for sending the message
        time; % Datetime variable
    end
    
    events
        SendButtonIsPressed
    end
    
    methods (Access = private)
        
        % Function that makes continuous sum when StratButton is pressed
        function [summer, trigger] = StartButtonCounter(app)
            summer = 0;
            while get(app.StartButton,'Value') == 1
                summer = summer + 1;
                drawnow;
                ev = addlistener(app,'SendButtonIsPressed',@MessageSender);
            end
            if get(app.StartButton,'Value') == 0
                trigger = 1;
                return
            end
        end
        
        function MessageSender(app)
            app.ArduinoMess = app.TexttosendEditField.Value;
            app.ArduinoMess = strcat(app.ArduinoMess, '\n');
            app.TexttosendEditField.Value = '';
            drawnow;
            fopen(app.serialVar);
            fprintf(app.serialVar,'%s',app.ArduinoMess);
            fclose(app.serialVar);
            app.ArduinoMess = '';
        end
    end
    
    


    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: StartButton
        function StartButtonPushed(app, event)
            app.serialVar = serial(app.SerialPortDropDown.Value);
            app.serialVar.ReadAsyncMode = 'continuous';
            if app.StartButton.Value == 1
                app.sumTrigger = app.StartButton.Value;
                app.StartButton.Text = 'Stop';
                app.SumEditField.Value = 0;
                app.TexttosendEditFieldLabel.Enable = 'on';
                app.TexttosendEditField.Editable = 'on';
                app.TexttosendEditField.Enable = 'on';
                app.time = string(datetime('now','Format','yyyy-MM-dd HH:mm:ss.ms'));
                app.iTextBox = app.iTextBox + 1;
                app.TextArea.Value(app.iTextBox) = {' >> Adder started'};
                drawnow;
                [app.i_sum, app.sumTrigger] = StartButtonCounter(app);
            end
            if app.sumTrigger == 1
                app.StartButton.Text = 'Start';
                app.TexttosendEditFieldLabel.Enable = 'off';
                app.TexttosendEditField.Editable = 'off';
                app.TexttosendEditField.Enable = 'off';
                app.SumEditField.Value = app.i_sum;
                app.time = string(datetime('now','Format','yyyy-MM-dd HH:mm:ss.ms'));
                app.iTextBox = app.iTextBox + 1;
                app.TextArea.Value(app.iTextBox) = {' >> Adder stoped'};
                drawnow;
                app.i_sum = 0;
                app.sumTrigger = 0;
            end
        end

        % Button pushed function: SendButton
        function SendButtonPushed(app, event)
            notify(app,'SendButtonIsPressed');
            MessageSender(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 631 480];
            app.UIFigure.Name = 'UI Figure';

            % Create StartButton
            app.StartButton = uibutton(app.UIFigure, 'state');
            app.StartButton.ValueChangedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.BusyAction = 'cancel';
            app.StartButton.Interruptible = 'off';
            app.StartButton.Text = 'Start';
            app.StartButton.Position = [26 432 100 22];

            % Create SumEditFieldLabel
            app.SumEditFieldLabel = uilabel(app.UIFigure);
            app.SumEditFieldLabel.HorizontalAlignment = 'right';
            app.SumEditFieldLabel.Position = [463 432 30 22];
            app.SumEditFieldLabel.Text = 'Sum';

            % Create SumEditField
            app.SumEditField = uieditfield(app.UIFigure, 'numeric');
            app.SumEditField.Editable = 'off';
            app.SumEditField.Position = [508 432 100 22];

            % Create TexttosendEditFieldLabel
            app.TexttosendEditFieldLabel = uilabel(app.UIFigure);
            app.TexttosendEditFieldLabel.HorizontalAlignment = 'center';
            app.TexttosendEditFieldLabel.Enable = 'off';
            app.TexttosendEditFieldLabel.Position = [26 394 70 22];
            app.TexttosendEditFieldLabel.Text = 'Text to send';

            % Create TexttosendEditField
            app.TexttosendEditField = uieditfield(app.UIFigure, 'text');
            app.TexttosendEditField.Editable = 'off';
            app.TexttosendEditField.Enable = 'off';
            app.TexttosendEditField.Position = [103 394 505 22];

            % Create SendButton
            app.SendButton = uibutton(app.UIFigure, 'push');
            app.SendButton.ButtonPushedFcn = createCallbackFcn(app, @SendButtonPushed, true);
            app.SendButton.Position = [508 362 100 22];
            app.SendButton.Text = 'Send';

            % Create SerialPortDropDownLabel
            app.SerialPortDropDownLabel = uilabel(app.UIFigure);
            app.SerialPortDropDownLabel.HorizontalAlignment = 'right';
            app.SerialPortDropDownLabel.Position = [26 362 62 22];
            app.SerialPortDropDownLabel.Text = 'Serial Port';

            % Create SerialPortDropDown
            app.SerialPortDropDown = uidropdown(app.UIFigure);
            app.SerialPortDropDown.Items = {'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9'};
            app.SerialPortDropDown.Position = [103 362 100 22];
            app.SerialPortDropDown.Value = 'COM1';

            % Create TextAreaLabel
            app.TextAreaLabel = uilabel(app.UIFigure);
            app.TextAreaLabel.HorizontalAlignment = 'right';
            app.TextAreaLabel.Position = [26 341 56 22];
            app.TextAreaLabel.Text = 'Text Area';

            % Create TextArea
            app.TextArea = uitextarea(app.UIFigure);
            app.TextArea.Editable = 'off';
            app.TextArea.FontName = 'Courier';
            app.TextArea.Position = [26 22 582 320];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app2

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end