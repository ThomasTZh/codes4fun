function catGo19
% CATGO19 Launches the 'Cat Go' game on a standard 19x19 grid.
%
%   Description:
%       Initializes a standard 19x19 Go board with complex rendering
%       features (merged stone shapes, cat ears, and reaction emojis).
%       - Left Click: Place stone.
%       - 'b' Key: Undo last move.
%
%   Syntax:
%       catGo19
%
%   Example:
%       catGo19;

    % --- Configuration ---
    boardSize = 19; % Standard Go Board Size
    
    % --- Visualization Setup ---
    fig = figure('Name', 'Cat Go (19x19)', ...
        'Units', 'normalized', ...
        'Position', [0.1, 0.05, 0.6, 0.85], ... % Adjusted for larger board
        'WindowButtonDownFcn', @onMouseClick, ...
        'WindowKeyPressFcn', @onKeyPress, ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none');

    ax = axes('Parent', fig, ...
        'Color', [215, 177, 116] ./ 255, ...
        'PlotBoxAspectRatio', [1, 1, 1], ...
        'XLim', [0.4, boardSize + 0.6], ...
        'YLim', [0.4, boardSize + 0.6], ...
        'NextPlot', 'add', ...
        'XColor', 'none', ...
        'YColor', 'none');

    % --- Draw Grid ---
    % Vertical and Horizontal lines for 19x19
    tx = [1:boardSize; 1:boardSize; nan(1, boardSize)];
    ty = [ones(1, boardSize); boardSize .* ones(1, boardSize); nan(1, boardSize)];
    plot(ax, tx(:), ty(:), 'LineWidth', 1, 'Color', 'k'); 
    plot(ax, ty(:), tx(:), 'LineWidth', 1, 'Color', 'k');

    % Draw Thick Borders
    borderX = [0.9, 0.9, boardSize+0.1, boardSize+0.1, 0.9, 0.9];
    borderY = [0.9, boardSize+0.1, boardSize+0.1, 0.9, 0.9, boardSize+0.1];
    plot(ax, borderX, borderY, 'LineWidth', 3, 'Color', 'k');

    % --- Draw Star Points (Hoshi) ---
    % Standard 19x19 star points are at 4, 10, 16
    starPoints = [4, 10, 16];
    [sx, sy] = meshgrid(starPoints, starPoints);
    theta = linspace(0, 2*pi, 50);
    starRad = 0.08;
    
    for k = 1:numel(sx)
        fill(ax, cos(theta).*starRad + sx(k), sin(theta).*starRad + sy(k), [0,0,0]);
    end

    % --- Data Initialization ---
    goMat = zeros(boardSize, boardSize);
    turn = 1; 
    emojiMap = zeros(0, 3);
    
    % Graphics handles storage
    PMat = cell(boardSize, boardSize); % Patch handles
    LMat = cell(boardSize, boardSize); % Line handles
    
    % History for Undo
    GMat = {goMat};
    EMat = {emojiMap};

    % --- Callback Functions ---
    function onMouseClick(~, ~)
        xxyy = get(ax, 'CurrentPoint');
        pos = [round(xxyy(1,1)), round(xxyy(1,2))];
        
        % Boundary Check
        pos(pos < 1) = 1; pos(pos > boardSize) = boardSize;
        
        if (goMat(pos(1), pos(2)) == 0)
            % Logic: Identify Neighbors
            [SX, SY] = find(sign(goMat) == turn); SSet = [SX, SY]; % Self
            [OX, OY] = find(sign(goMat) == -turn); OSet = [OX, OY]; % Opponent
            SNum = [0; unique(goMat(sign(goMat) == turn))];
            
            PSet = repmat(pos, [4,1]) + [-1,0; 1,0; 0,-1; 0,1];
            ISSet = intersect(PSet, SSet, 'rows'); % Intersect Self
            IOSet = intersect(PSet, OSet, 'rows'); % Intersect Opponent
            
            flag = true;
            % Basic suicide prevention (unless capturing)
            if size(IOSet,1) == 4
                flag = false; 
            end
            
            newNum = min(setdiff(1:(max(abs(SNum))+1), abs(SNum)));
            
            % --- Stone Placement & Merging ---
            switch size(ISSet,1)
                case 0
                    goMat(pos(1), pos(2)) = turn*newNum;
                    drawStone(pos);
                    emojiMap = [emojiMap; pos, turn*newNum];
                case 1
                    goMat(pos(1), pos(2)) = goMat(ISSet(1), ISSet(2));
                    drawStone(pos); drawStone(ISSet);
                    emojiMap(emojiMap(:,3) == goMat(ISSet(1), ISSet(2)),:) = [pos, goMat(ISSet(1), ISSet(2))];
                case {2,3,4}
                    goMat(pos(1), pos(2)) = turn*newNum;
                    drawStone(pos);
                    for i = 1:size(ISSet,1)
                        emojiMap(emojiMap(:,3) == goMat(ISSet(i,1), ISSet(i,2)),:) = [];
                        goMat(goMat == goMat(ISSet(i,1), ISSet(i,2))) = turn*newNum;
                        drawStone([ISSet(i,1), ISSet(i,2)])
                    end
                    emojiMap = [emojiMap; pos, turn*newNum];
            end
            
            % --- Capture Opponent Logic ---
            [EX, EY] = find(goMat == 0); ESet = [EX, EY];
            for i = 1:size(IOSet,1)
                tind = goMat(IOSet(i,1), IOSet(i,2));
                [tX, tY] = find(goMat == tind); tSet = [tX, tY];
                tN = size(tSet, 1);
                TSet = unique([tSet + repmat([-1,0], [tN,1]);
                    tSet + repmat([1,0], [tN,1]);
                    tSet + repmat([0,-1], [tN,1]);
                    tSet + repmat([0,1], [tN,1])],'rows');
                ITSet = intersect(TSet, ESet, 'rows');
                
                switch size(ITSet, 1)
                    case 0 % Captured
                        flag = true; % Valid move if it captures
                        emojiMap(emojiMap(:,3) == tind, :) = [];
                        for j = 1:size(tSet, 1)
                            goMat(tSet(j,1), tSet(j,2)) = 0;
                            delete(PMat{tSet(j,1), tSet(j,2)});
                            delete(LMat{tSet(j,1), tSet(j,2)});
                        end
                    case 1 % Atarik (One liberty left)
                        emojiMap(emojiMap(:,3) == tind, :) = [IOSet(i,:), tind];
                end
            end
            
            % --- Self Capture Check ---
            [EX, EY] = find(goMat == 0); ESet = [EX, EY];
            tind = goMat(pos(1), pos(2));
            [tX, tY] = find(goMat == tind); tSet = [tX, tY];
            tN = size(tSet, 1);
            TSet = unique([tSet + repmat([-1,0], [tN,1]);
                tSet + repmat([1,0], [tN,1]);
                tSet + repmat([0,-1], [tN,1]);
                tSet + repmat([0,1], [tN,1])],'rows');
            ITSet = intersect(TSet, ESet, 'rows');
            
            switch size(ITSet, 1)
                case 0 % Self-capture
                    emojiMap(emojiMap(:,3) == tind, :) = [];
                    for j = 1:size(tSet, 1)
                        goMat(tSet(j,1), tSet(j,2)) = 0;
                        delete(PMat{tSet(j,1), tSet(j,2)});
                        delete(LMat{tSet(j,1), tSet(j,2)});
                    end
                case 1
                    emojiMap(emojiMap(:,3) == tind, :) = [pos, tind];
            end
            
            if flag
                turn = - turn;
                GMat{end + 1} = goMat;
                EMat{end + 1} = emojiMap;
            end
            
            % Trigger complex renderings
            drawEar();
            drawEmojiS();
        end
    end

    function onKeyPress(~, key)
        if strcmp(key.Key, 'b')
            if length(EMat) >= 2
                GMat(end) = [];
                EMat(end) = [];
                goMat = GMat{end};
                emojiMap = EMat{end};
                turn = - turn;
                
                % Full board redraw required for undo
                for i = 1:boardSize
                    for j = 1:boardSize
                        drawStone([i,j])
                    end
                end
                drawEar();
                drawEmojiS();
            end
        end
    end

    % --- Complex Rendering Functions (Retained & Scaled) ---
    
    function drawEar(~, ~)
        % Updated to support dynamic board size
        tobj = findobj(ax, 'UserData', 'slan');
        for i = length(tobj):-1:1
            delete(tobj(i))
        end
        
        baseMat = goMat;
        [r, c] = size(goMat);
        
        % Dynamic padding logic to replace hardcoded 'zeros(1,8)'
        % Shift Right-Up
        ruMat = [[zeros(1, c-1); baseMat(1:(end-1), 2:end)], zeros(r, 1)];
        % Shift Right-Down
        rdMat = [[baseMat(2:end, 2:end); zeros(1, c-1)], zeros(r, 1)];
        
        tmapru = (baseMat ~= ruMat) & (sign(baseMat) == sign(ruMat)) & (baseMat ~= 0);
        tmaprd = (baseMat ~= rdMat) & (sign(baseMat) == sign(rdMat)) & (baseMat ~= 0);
        
        tgoru = goMat(2:end, :);
        tgord = goMat(1:(end-1), :);
        tru = tmapru(2:end, :);
        trd = tmaprd(1:(end-1), :);
        
        tbool = tru & trd & (sign(tgoru) ~= sign(tgord));
        tru(tbool) = 0;
        trd(tbool) = 0;
        
        tmapru(2:end, :) = tru;
        tmaprd(1:(end-1), :) = trd;
        
        % Draw Right-Up Ears
        [rux, ruy] = find(tmapru == 1);
        for i = 1:length(rux)
            tturn = sign(goMat(rux(i), ruy(i))); 
            C = [105,105,107]./255.*(tturn>0) + [228,228,228]./255.*(tturn<0);
            
            fill(ax, [(rux(i)-1+.2), (rux(i)-.5-.03), (rux(i)-.45), (rux(i)-.2), (rux(i)-.5+.03), (rux(i)-1+.45)], ...
                [(ruy(i)+1-.45), (ruy(i)+.5-.03), (ruy(i)+.2), (ruy(i)+.45), (ruy(i)+.5+.03), (ruy(i)+1-.2)], C, ...
                'EdgeColor','none','UserData','slan');
            
            plot(ax, [(rux(i)-1+.2), (rux(i)-.5-.03), (rux(i)-.45)], ...
                 [(ruy(i)+1-.45), (ruy(i)+.5-.03), (ruy(i)+.2)], 'Color','k', 'LineWidth',2,'UserData','slan');
            plot(ax, [(rux(i)-1+.45), (rux(i)-.5+.03), (rux(i)-.2)], ...
                 [(ruy(i)+1-.2), (ruy(i)+.5+.03), (ruy(i)+.45)], 'Color','k', 'LineWidth',2,'UserData','slan');
        end
        
        % Draw Right-Down Ears
        [rdx, rdy] = find(tmaprd == 1);
        for i = 1:length(rdx)
            tturn = sign(goMat(rdx(i), rdy(i)));
            C = [105,105,107]./255.*(tturn>0) + [228,228,228]./255.*(tturn<0);
            
            fill(ax, [(rdx(i)+.2), (rdx(i)+.5-.03), (rdx(i)+1-.45), (rdx(i)+1-.2), (rdx(i)+.5+.03), (rdx(i)+.45)], ...
                [(rdy(i)+.45), (rdy(i)+.5+.03), (rdy(i)+1-.2), (rdy(i)+1-.45), (rdy(i)+.5-.03), (rdy(i)+.2)], C, ...
                'EdgeColor','none','UserData','slan');
            
            plot(ax, [(rdx(i)+.2), (rdx(i)+.5-.03), (rdx(i)+1-.45)], ...
                 [(rdy(i)+.45), (rdy(i)+.5+.03), (rdy(i)+1-.2)], 'Color','k', 'LineWidth',2,'UserData','slan');
            plot(ax, [(rdx(i)+.45), (rdx(i)+.5+.03), (rdx(i)+1-.2)], ...
                 [(rdy(i)+.2), (rdy(i)+.5-.03), (rdy(i)+1-.45)], 'Color','k', 'LineWidth',2,'UserData','slan');
        end
    end

    function drawEmojiS(~,~)
        tobj = findobj(ax, 'UserData', 'emoji');
        for i = length(tobj):-1:1
            delete(tobj(i))
        end
        
        ttype = ones(size(emojiMap,1), 1);
        [EX, EY] = find(goMat == 0); ESet = [EX, EY];
        
        for i = 1:size(emojiMap,1)
            tind = emojiMap(i,3);
            [tX, tY] = find(goMat == tind); tSet = [tX, tY];
            tN = size(tSet, 1);
            TSet = unique([tSet + repmat([-1,0], [tN,1]);
                tSet + repmat([1,0], [tN,1]);
                tSet + repmat([0,-1], [tN,1]);
                tSet + repmat([0,1], [tN,1])],'rows');
            
            ITSet = intersect(TSet, ESet, 'rows');
            if size(ITSet,1) == 1
                ttype(i) = 3; % Worried face
                [OX, OY] = find(sign(goMat) == -sign(tind)); OSet = [OX, OY];
                IOOSet = intersect(TSet, OSet, 'rows');
                for j = 1:size(IOOSet, 1)
                    if ttype(emojiMap(:,3) == goMat(IOOSet(j,1),IOOSet(j,2))) ~= 3
                        ttype(emojiMap(:,3) == goMat(IOOSet(j,1),IOOSet(j,2))) = 2; % Aggressive/Happy face
                    end
                end
            end
        end
        for i = 1:size(emojiMap,1)
            drawEmoji(emojiMap(i,1:2), ttype(i))
        end
    end

    function drawEmoji(pos, type)
        switch type
            case 1
                ttt1 = linspace(pi - pi/12, 2*pi - pi/12, 50);
                ttt2 = linspace(pi + pi/12, 2*pi + pi/12, 50);
                ttt3 = linspace(0, 2*pi, 50);
                ttx = [cos(ttt1).*.05-.05, cos(ttt2).*.05+.05] + pos(1);
                tty = [sin(ttt1).*.05, sin(ttt2).*.05] + pos(2) -.02;
                plot(ax, ttx, tty, 'Color','k', 'LineWidth',1.5, 'UserData','emoji')
                fill(ax, cos(ttt3).*.06 + pos(1) - .25, sin(ttt3).*.06 + pos(2), [0,0,0], 'UserData','emoji')
                fill(ax, cos(ttt3).*.06 + pos(1) + .25, sin(ttt3).*.06 + pos(2), [0,0,0], 'UserData','emoji')
            case 2
                ttt1 = linspace(0+pi/5, pi-pi/5, 50);
                ttt3 = linspace(0, 2*pi, 50);
                plot(ax, cos(ttt1).*.15 + pos(1), sin(ttt1).*.12 + pos(2) - .25, 'Color','k', 'LineWidth',1.5, 'UserData','emoji')
                plot(ax, [.16,.35] + pos(1), [.12,.16] + pos(2), 'Color','k', 'LineWidth',2, 'UserData','emoji')
                plot(ax, [-.16,-.35] + pos(1), [.12,.16] + pos(2), 'Color','k', 'LineWidth',2, 'UserData','emoji')
                fill(ax, cos(ttt3).*.06 + pos(1) - .25, sin(ttt3).*.06 + pos(2), [0,0,0], 'UserData','emoji')
                fill(ax, cos(ttt3).*.06 + pos(1) + .25, sin(ttt3).*.06 + pos(2), [0,0,0], 'UserData','emoji')
            case 3
                ttt1 = linspace(0+pi/8, pi-pi/8, 50);
                ttx = cos(ttt1).*.22 + pos(1); ttx = [ttx, ttx(1)];
                tty = sin(ttt1).*.22 + pos(2) - .35; tty = [tty, tty(1)];
                ttt3 = linspace(0, 2*pi, 50);
                plot(ax, ttx, tty, 'Color','k', 'LineWidth',1.5, 'UserData','emoji')
                ttx = [.1,.1, nan, .16, .16, nan, .22, .22, nan, .28, .28, nan, .34, .34] + pos(1);
                tty = [.2,.4, nan, .14, .42, nan, .16, .36, nan, .01, .28, nan, .1, .25] + pos(2);
                plot(ax, ttx, tty, 'Color','k', 'LineWidth',1, 'UserData','emoji')
                ttx = [-.25,-.25, nan, -.3, -.3, nan, -.2, -.2] + pos(1);
                tty = [-.21,-.08, nan, -.18,-.06, nan, -.15,-.06] + pos(2);
                plot(ax, ttx, tty, 'Color','k', 'LineWidth',1, 'UserData','emoji')
                plot(ax, cos(ttt3).*.06 + pos(1) - .25, sin(ttt3).*.06 + pos(2), 'Color','k', 'LineWidth',1.5, 'UserData','emoji')
                plot(ax, cos(ttt3).*.06 + pos(1) + .25, sin(ttt3).*.06 + pos(2), 'Color','k', 'LineWidth',1.5, 'UserData','emoji')
        end
    end

    function drawStone(pos)
        delete(PMat{pos(1), pos(2)});
        delete(LMat{pos(1), pos(2)});
        if goMat(pos(1), pos(2)) ~= 0
            tturn = sign(goMat(pos(1), pos(2)));
            C = [105,105,107]./255.*(tturn>0) + [228,228,228]./255.*(tturn<0);
            [SX, SY] = find(sign(goMat) == tturn); SSet = [SX, SY];
            PSet = repmat(pos, [4,1]) + [-1,0;1,0;0,-1;0,1];
            [~, IInd, ~] = intersect(PSet, SSet,'rows'); IInd = sort(IInd);
            
            % Blob Logic (Unchanged from original as requested)
            if isempty(IInd)
                ttt = linspace(0,2*pi,100);
                ttx = cos(ttt).*.5 + pos(1);
                tty = sin(ttt).*.5 + pos(2);
                PMat{pos(1), pos(2)} = fill(ax, ttx, tty,C, 'EdgeColor','none');
                LMat{pos(1), pos(2)} = plot(ax, ttx, tty, 'Color','k', 'LineWidth',2);
            else
                switch length(IInd)
                    case 1
                        switch IInd
                            case 1
                                ttt = linspace(-pi/2, pi/2, 100);
                                ttx = [-.5, cos(ttt).*.5, -.5] + pos(1);
                                tty = [-.5, sin(ttt).*.5, .5] + pos(2);
                                PMat{pos(1), pos(2)} = fill(ax, ttx, tty, C, 'EdgeColor','none');
                                LMat{pos(1), pos(2)} = plot(ax, ttx, tty, 'Color','k', 'LineWidth',2);
                            case 2
                                ttt = linspace(pi/2, 3*pi/2, 100);
                                ttx = [.5, cos(ttt).*.5, .5] + pos(1);
                                tty = [.5, sin(ttt).*.5, -.5] + pos(2);
                                PMat{pos(1), pos(2)} = fill(ax, ttx, tty, C, 'EdgeColor','none');
                                LMat{pos(1), pos(2)} = plot(ax, ttx, tty, 'Color','k', 'LineWidth',2);
                            case 3
                                ttt = linspace(0, pi, 100);
                                ttx = [.5, cos(ttt).*.5, -.5] + pos(1);
                                tty = [-.5, sin(ttt).*.5, -.5] + pos(2);
                                PMat{pos(1), pos(2)} = fill(ax, ttx, tty, C, 'EdgeColor','none');
                                LMat{pos(1), pos(2)} = plot(ax, ttx, tty, 'Color','k', 'LineWidth',2);
                            case 4
                                ttt = linspace(pi, 2*pi, 100);
                                ttx = [-.5, cos(ttt).*.5, .5] + pos(1);
                                tty = [.5, sin(ttt).*.5, .5] + pos(2);
                                PMat{pos(1), pos(2)} = fill(ax, ttx, tty, C, 'EdgeColor','none');
                                LMat{pos(1), pos(2)} = plot(ax, ttx, tty, 'Color','k', 'LineWidth',2);
                        end
                    case 2
                        switch true
                            case all(IInd == [1;2])
                                PMat{pos(1), pos(2)} = fill(ax, pos(1) + [-.5, .5, .5, -.5],...
                                    pos(2) + [-.5, -.5, .5, .5], C, 'EdgeColor','none');
                                LMat{pos(1), pos(2)} = plot(ax, pos(1) + [-.5, .5, nan, .5, -.5], ...
                                    pos(2) + [-.5, -.5, nan .5, .5], 'Color','k', 'LineWidth',2);
                            case all(IInd == [3;4])
                                PMat{pos(1), pos(2)} = fill(ax, pos(1) + [-.5, -.5, .5, .5],...
                                    pos(2) + [-.5, .5, .5, -.5], C, 'EdgeColor','none');
                                LMat{pos(1), pos(2)} = plot(ax, pos(1) + [-.5, -.5, nan .5, .5], ...
                                    pos(2) + [-.5, .5, nan, .5, -.5], 'Color','k', 'LineWidth',2);
                            case all(IInd == [1;3])
                                ttt = linspace(0, pi/2, 100);
                                ttx = [-.5, .5, cos(ttt).*.5, -.5] + pos(1);
                                tty = [-.5, -.5, sin(ttt).*.5, .5] + pos(2);
                                PMat{pos(1), pos(2)} = fill(ax, ttx, tty, C, 'EdgeColor','none');
                                LMat{pos(1), pos(2)} = plot(ax, ttx(2:end), tty(2:end), 'Color','k', 'LineWidth',2);
                            case all(IInd == [1;4])
                                ttt = linspace(3*pi/2, 2*pi, 100);
                                ttx = [-.5, -.5, cos(ttt).*.5, .5] + pos(1);
                                tty = [.5, -.5, sin(ttt).*.5, .5] + pos(2);
                                PMat{pos(1), pos(2)} = fill(ax, ttx, tty, C, 'EdgeColor','none');
                                LMat{pos(1), pos(2)} = plot(ax, ttx(2:end), tty(2:end), 'Color','k', 'LineWidth',2);
                            case all(IInd == [2;3])
                                ttt = linspace(pi/2, pi, 100);
                                ttx = [.5, .5, cos(ttt).*.5, -.5] + pos(1);
                                tty = [-.5, .5, sin(ttt).*.5, -.5] + pos(2);
                                PMat{pos(1), pos(2)} = fill(ax, ttx, tty, C, 'EdgeColor','none');
                                LMat{pos(1), pos(2)} = plot(ax, ttx(2:end), tty(2:end), 'Color','k', 'LineWidth',2);
                            case all(IInd == [2;4])
                                ttt = linspace(pi, 3*pi/2, 100);
                                ttx = [.5, -.5, cos(ttt).*.5, .5] + pos(1);
                                tty = [.5, .5, sin(ttt).*.5, -.5] + pos(2);
                                PMat{pos(1), pos(2)} = fill(ax, ttx, tty, C, 'EdgeColor','none');
                                LMat{pos(1), pos(2)} = plot(ax, ttx(2:end), tty(2:end), 'Color','k', 'LineWidth',2);
                        end
                    case 3
                        ttx = [-.5, .5, .5, -.5] + pos(1);
                        tty = [-.5, -.5, .5, .5] + pos(2);
                        PMat{pos(1), pos(2)} = fill(ax, ttx, tty, C, 'EdgeColor','none');
                        switch true
                            case all(IInd == [2;3;4]), ttx = [-.5, -.5] + pos(1); tty = [-.5, .5] + pos(2);
                            case all(IInd == [1;3;4]), ttx = [.5, .5] + pos(1); tty = [-.5, .5] + pos(2);
                            case all(IInd == [1;2;4]), ttx = [-.5, .5] + pos(1); tty = [-.5, -.5] + pos(2);
                            case all(IInd == [1;2;3]), ttx = [-.5, .5] + pos(1); tty = [.5, .5] + pos(2);
                        end
                        LMat{pos(1), pos(2)} = plot(ax, ttx, tty, 'Color','k', 'LineWidth',2);
                    case 4
                        ttx = [-.5, .5, .5, -.5] + pos(1);
                        tty = [-.5, -.5, .5, .5] + pos(2);
                        PMat{pos(1), pos(2)} = fill(ax, ttx, tty, C, 'EdgeColor','none');
                        LMat{pos(1), pos(2)} = [];
                end
            end
        end
    end
end