function catGo9
% CATGO9 Launches a graphical interface for the 'Cat Go' board game.
%
%   Description:
%       This function initializes a 9x9 Go board where placed stones
%       dynamically merge visually. The game detects specific patterns
%       to draw 'Cat' features (ears and faces) on the stones.
%       - Left Click: Place stone.
%       - 'b' Key: Undo last move.
%
%   Syntax:
%       catGoGame
%
%   Inputs:
%       None
%
%   Outputs:
%       None (Generates a GUI Figure)
%
%   Example:
%       catGo9;

    % --- Visualization Setup ---
    gameFig = figure('Name', 'Cat Go - Refactored', ...
        'Units', 'normalized', ...
        'Position', [0.1, 0.1, 0.55, 0.8], ...
        'WindowButtonDownFcn', @onMouseClick, ...
        'WindowKeyPressFcn', @onKeyPress, ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none');

    gameAx = axes('Parent', gameFig, ...
        'Color', [215, 177, 116] ./ 255, ...
        'PlotBoxAspectRatio', [1, 1, 1], ...
        'XLim', [0.4, 9.6], ...
        'YLim', [0.4, 9.6], ...
        'NextPlot', 'add', ...
        'XColor', 'none', ...
        'YColor', 'none');

    % Draw Board Grid
    gridX = [1:9; 1:9; nan(1, 9)];
    gridY = [ones(1, 9); 9 .* ones(1, 9); nan(1, 9)];
    plot(gameAx, gridX(:), gridY(:), 'LineWidth', 1, 'Color', 'k'); % Vertical
    plot(gameAx, gridY(:), gridX(:), 'LineWidth', 1, 'Color', 'k'); % Horizontal

    % Draw Board Borders and "Star" points (Hoshi)
    borderX = [0.9, 0.9, 9.1, 9.1, 0.9, 0.9];
    borderY = [0.9, 9.1, 9.1, 0.9, 0.9, 9.1];
    plot(gameAx, borderX, borderY, 'LineWidth', 3, 'Color', 'k');

    theta = linspace(0, 2 * pi, 50);
    starX = cos(theta) .* 0.08;
    starY = sin(theta) .* 0.08;
    % Draw the 4 corner star points
    fill(gameAx, starX + 3, starY + 3, [0, 0, 0]);
    fill(gameAx, starX + 7, starY + 3, [0, 0, 0]);
    fill(gameAx, starX + 3, starY + 7, [0, 0, 0]);
    fill(gameAx, starX + 7, starY + 7, [0, 0, 0]);

    % --- Game State Initialization ---
    boardSize = 9;
    gameStateMat = zeros(boardSize); % 0=Empty, +/- Int = Group IDs
    currentTurn = 1; % 1 = Black, -1 = White
    emojiDataMap = zeros(0, 3); % [x, y, groupID]

    % Graphics Handles storage
    patchHandlesMat = cell(boardSize);
    lineHandlesMat = cell(boardSize);

    % History for Undo functionality
    historyGameMat = {gameStateMat};
    historyEmojiMat = {emojiDataMap};

    % --- Nested Callback Functions ---

    function onMouseClick(~, ~)
        % Description: Handles stone placement and game logic.
        
        clickPoint = get(gameAx, 'CurrentPoint');
        gridPos = [round(clickPoint(1, 1)), round(clickPoint(1, 2))];

        % Boundary checks
        gridPos(gridPos < 1) = 1;
        gridPos(gridPos > 9) = 9;

        row = gridPos(1);
        col = gridPos(2);

        % If the spot is empty, proceed
        if (gameStateMat(row, col) == 0)
            
            % 1. Analyze Neighbors for Grouping
            % Find coordinates of same-colored stones (Self) and opponents (Opponent)
            [sX, sY] = find(sign(gameStateMat) == currentTurn);
            selfSet = [sX, sY];
            
            [oX, oY] = find(sign(gameStateMat) == -currentTurn);
            opponentSet = [oX, oY];

            % Get existing group IDs for current player
            selfGroupIDs = [0; unique(gameStateMat(sign(gameStateMat) == currentTurn))];

            % Define 4 neighbors (Up, Down, Left, Right)
            neighborOffsets = [-1, 0; 1, 0; 0, -1; 0, 1];
            potentialNeighbors = repmat(gridPos, [4, 1]) + neighborOffsets;

            % Intersect neighbors with existing stones
            intersectSelf = intersect(potentialNeighbors, selfSet, 'rows');
            intersectOpponent = intersect(potentialNeighbors, opponentSet, 'rows');

            % Suicide rule check (simplistic): Prevent placement if completely surrounded by opponents
            % Note: Real Go rules allow suicide if it captures stones.
            isValidMove = true;
            if size(intersectOpponent, 1) == 4
                isValidMove = false;
            end

            % Generate a new unique ID for a potential new group
            existingAbsIDs = abs(selfGroupIDs);
            possibleIDs = 1:(max(existingAbsIDs) + 1);
            newGroupID = min(setdiff(possibleIDs, existingAbsIDs));

            % 2. Place Stone and Merge Groups
            switch size(intersectSelf, 1)
                case 0
                    % No friendly neighbors: New Group
                    gameStateMat(row, col) = currentTurn * newGroupID;
                    renderStone(gridPos);
                    emojiDataMap = [emojiDataMap; gridPos, currentTurn * newGroupID];

                case 1
                    % One friendly neighbor: Inherit ID
                    neighborID = gameStateMat(intersectSelf(1), intersectSelf(2));
                    gameStateMat(row, col) = neighborID;
                    renderStone(gridPos);
                    renderStone(intersectSelf); % Update neighbor shape
                    
                    % Update emoji map entry
                    mask = emojiDataMap(:, 3) == neighborID;
                    emojiDataMap(mask, :) = [gridPos, neighborID];

                case {2, 3, 4}
                    % Multiple friendly neighbors: Merge all into New Group
                    gameStateMat(row, col) = currentTurn * newGroupID;
                    renderStone(gridPos);
                    
                    for k = 1:size(intersectSelf, 1)
                        targetID = gameStateMat(intersectSelf(k, 1), intersectSelf(k, 2));
                        
                        % Remove old emoji entries for merged groups
                        emojiDataMap(emojiDataMap(:, 3) == targetID, :) = [];
                        
                        % Update board matrix: all stones of targetID become newGroupID
                        gameStateMat(gameStateMat == targetID) = currentTurn * newGroupID;
                        
                        % Redraw neighbor
                        renderStone([intersectSelf(k, 1), intersectSelf(k, 2)]);
                    end
                    emojiDataMap = [emojiDataMap; gridPos, currentTurn * newGroupID];
            end

            % 3. Check Captures (Opponent)
            % Find all empty spots (Liberties)
            [eX, eY] = find(gameStateMat == 0);
            emptySet = [eX, eY];
            
            for k = 1:size(intersectOpponent, 1)
                targetID = gameStateMat(intersectOpponent(k, 1), intersectOpponent(k, 2));
                if targetID == 0; continue; end
                
                % Find all stones in this opponent group
                [tX, tY] = find(gameStateMat == targetID);
                targetGroupSet = [tX, tY];
                numStones = size(targetGroupSet, 1);
                
                % Calculate liberties of the group
                allNeighbors = unique([targetGroupSet + repmat([-1, 0], [numStones, 1]); ...
                                       targetGroupSet + repmat([1, 0], [numStones, 1]); ...
                                       targetGroupSet + repmat([0, -1], [numStones, 1]); ...
                                       targetGroupSet + repmat([0, 1], [numStones, 1])], 'rows');
                
                hasLiberties = intersect(allNeighbors, emptySet, 'rows');

                switch size(hasLiberties, 1)
                    case 0
                        % Capture!
                        isValidMove = true; % Allowed if it captures
                        emojiDataMap(emojiDataMap(:, 3) == targetID, :) = [];
                        for m = 1:numStones
                            gameStateMat(targetGroupSet(m, 1), targetGroupSet(m, 2)) = 0;
                            delete(patchHandlesMat{targetGroupSet(m, 1), targetGroupSet(m, 2)});
                            delete(lineHandlesMat{targetGroupSet(m, 1), targetGroupSet(m, 2)});
                        end
                    case 1
                        % One eye/liberty left: Update emoji location to the 'eye'
                        emojiDataMap(emojiDataMap(:, 3) == targetID, :) = [hasLiberties, targetID];
                end
            end

            % 4. Check Self-Capture (Suicide Check post-placement)
            % Only strictly necessary if the move didn't capture opponents
            [eX, eY] = find(gameStateMat == 0);
            emptySet = [eX, eY];
            
            myID = gameStateMat(row, col);
            [tX, tY] = find(gameStateMat == myID);
            myGroupSet = [tX, tY];
            numStones = size(myGroupSet, 1);
            
            allNeighbors = unique([myGroupSet + repmat([-1, 0], [numStones, 1]); ...
                                   myGroupSet + repmat([1, 0], [numStones, 1]); ...
                                   myGroupSet + repmat([0, -1], [numStones, 1]); ...
                                   myGroupSet + repmat([0, 1], [numStones, 1])], 'rows');
            
            hasLiberties = intersect(allNeighbors, emptySet, 'rows');
            
            switch size(hasLiberties, 1)
                case 0
                    % Self-capture (Suicide)
                    emojiDataMap(emojiDataMap(:, 3) == myID, :) = [];
                    for m = 1:numStones
                        gameStateMat(myGroupSet(m, 1), myGroupSet(m, 2)) = 0;
                        delete(patchHandlesMat{myGroupSet(m, 1), myGroupSet(m, 2)});
                        delete(lineHandlesMat{myGroupSet(m, 1), myGroupSet(m, 2)});
                    end
                case 1
                    emojiDataMap(emojiDataMap(:, 3) == myID, :) = [gridPos, myID];
            end

            % 5. Finalize Turn
            if isValidMove
                currentTurn = -currentTurn;
                historyGameMat{end + 1} = gameStateMat;
                historyEmojiMat{end + 1} = emojiDataMap;
            end
            
            renderEars();
            renderEmojis();
        end
    end

    function onKeyPress(~, eventData)
        % Description: Undo function mapped to 'b' key.
        if strcmp(eventData.Key, 'b')
            if length(historyEmojiMat) >= 2
                historyGameMat(end) = [];
                historyEmojiMat(end) = [];
                gameStateMat = historyGameMat{end};
                emojiDataMap = historyEmojiMat{end};
                currentTurn = -currentTurn;
                
                % Redraw entire board
                for r = 1:9
                    for c = 1:9
                        renderStone([r, c]);
                    end
                end
                renderEars();
                renderEmojis();
            end
        end
    end

    % --- Rendering Functions ---

    function renderEars(~, ~)
        % Description: Detects diagonal patterns to draw cat ears.
        
        % Clean up old ears
        oldEars = findobj(gameAx, 'UserData', 'earLayer');
        delete(oldEars);

        baseMat = gameStateMat;
        % Shift matrices to check diagonals
        rightUpMat = [[zeros(1, 8); baseMat(1:(end - 1), 2:end)], zeros(9, 1)];
        rightDownMat = [[baseMat(2:end, 2:end); zeros(1, 8)], zeros(9, 1)];

        mapRU = (baseMat ~= rightUpMat) & (sign(baseMat) == sign(rightUpMat)) & (baseMat ~= 0);
        mapRD = (baseMat ~= rightDownMat) & (sign(baseMat) == sign(rightDownMat)) & (baseMat ~= 0);

        % Filter specific crossing patterns
        tempRU = mapRU(2:end, :);
        tempRD = mapRD(1:(end - 1), :);
        checkBool = tempRU & tempRD & (sign(baseMat(2:end, :)) ~= sign(baseMat(1:(end - 1), :)));
        
        tempRU(checkBool) = 0;
        tempRD(checkBool) = 0;
        
        mapRU(2:end, :) = tempRU;
        mapRD(1:(end - 1), :) = tempRD;

        % Draw Right-Up Ears
        [ruX, ruY] = find(mapRU == 1);
        drawEarShape(ruX, ruY, 1);

        % Draw Right-Down Ears
        [rdX, rdY] = find(mapRD == 1);
        drawEarShape(rdX, rdY, 2);
        
        function drawEarShape(xIdx, yIdx, type)
            for k = 1:length(xIdx)
                idxX = xIdx(k); idxY = yIdx(k);
                pTurn = sign(gameStateMat(idxX, idxY));
                
                % Determine Color
                if pTurn > 0
                    colorVal = [105, 105, 107] ./ 255; % Black stone color
                else
                    colorVal = [228, 228, 228] ./ 255; % White stone color
                end

                if type == 1 % Right Up pattern
                    fillX = [(idxX - 1 + .2), (idxX - .5 - .03), (idxX - .45), (idxX - .2), (idxX - .5 + .03), (idxX - 1 + .45)];
                    fillY = [(idxY + 1 - .45), (idxY + .5 - .03), (idxY + .2), (idxY + .45), (idxY + .5 + .03), (idxY + 1 - .2)];
                    
                    line1X = [(idxX - 1 + .2), (idxX - .5 - .03), (idxX - .45)];
                    line1Y = [(idxY + 1 - .45), (idxY + .5 - .03), (idxY + .2)];
                    
                    line2X = [(idxX - 1 + .45), (idxX - .5 + .03), (idxX - .2)];
                    line2Y = [(idxY + 1 - .2), (idxY + .5 + .03), (idxY + .45)];
                else % Right Down pattern
                    fillX = [(idxX + .2), (idxX + .5 - .03), (idxX + 1 - .45), (idxX + 1 - .2), (idxX + .5 + .03), (idxX + .45)];
                    fillY = [(idxY + .45), (idxY + .5 + .03), (idxY + 1 - .2), (idxY + 1 - .45), (idxY + .5 - .03), (idxY + .2)];
                    
                    line1X = [(idxX + .2), (idxX + .5 - .03), (idxX + 1 - .45)];
                    line1Y = [(idxY + .45), (idxY + .5 + .03), (idxY + 1 - .2)];
                    
                    line2X = [(idxX + .45), (idxX + .5 + .03), (idxX + 1 - .2)];
                    line2Y = [(idxY + .2), (idxY + .5 - .03), (idxY + 1 - .45)];
                end

                fill(gameAx, fillX, fillY, colorVal, 'EdgeColor', 'none', 'UserData', 'earLayer');
                plot(gameAx, line1X, line1Y, 'Color', 'k', 'LineWidth', 2, 'UserData', 'earLayer');
                plot(gameAx, line2X, line2Y, 'Color', 'k', 'LineWidth', 2, 'UserData', 'earLayer');
            end
        end
    end

    function renderEmojis(~, ~)
        % Description: Draws faces based on group status (surrounded, safe, etc.)
        oldEmojis = findobj(gameAx, 'UserData', 'emojiLayer');
        delete(oldEmojis);

        emojiType = ones(size(emojiDataMap, 1), 1);
        [eX, eY] = find(gameStateMat == 0);
        emptySet = [eX, eY];

        % Determine Emoji Type based on liberties
        for k = 1:size(emojiDataMap, 1)
            targetID = emojiDataMap(k, 3);
            [tX, tY] = find(gameStateMat == targetID);
            targetSet = [tX, tY];
            numStones = size(targetSet, 1);
            
            allNeighbors = unique([targetSet + repmat([-1, 0], [numStones, 1]); ...
                                   targetSet + repmat([1, 0], [numStones, 1]); ...
                                   targetSet + repmat([0, -1], [numStones, 1]); ...
                                   targetSet + repmat([0, 1], [numStones, 1])], 'rows');
            
            intersectLiberties = intersect(allNeighbors, emptySet, 'rows');

            if size(intersectLiberties, 1) == 1
                emojiType(k) = 3; % Distressed face
                
                % Check adjacent opponent groups
                [oX, oY] = find(sign(gameStateMat) == -sign(targetID));
                oppSet = [oX, oY];
                intersectOpp = intersect(allNeighbors, oppSet, 'rows');
                
                for m = 1:size(intersectOpp, 1)
                    oppID = gameStateMat(intersectOpp(m, 1), intersectOpp(m, 2));
                    mask = emojiDataMap(:, 3) == oppID;
                    if any(mask) && emojiType(mask) ~= 3
                        emojiType(mask) = 2; % Aggressive/Happy face
                    end
                end
            end
        end

        for k = 1:size(emojiDataMap, 1)
            drawSpecificEmoji(emojiDataMap(k, 1:2), emojiType(k));
        end
    end

    function drawSpecificEmoji(pos, type)
        % Helper to draw individual face features
        switch type
            case 1 % Neutral/Cute
                t1 = linspace(pi - pi/12, 2*pi - pi/12, 50);
                t2 = linspace(pi + pi/12, 2*pi + pi/12, 50);
                t3 = linspace(0, 2*pi, 50);
                
                eyeX = [cos(t1).*.05-.05, cos(t2).*.05+.05] + pos(1);
                eyeY = [sin(t1).*.05, sin(t2).*.05] + pos(2) -.02;
                
                plot(gameAx, eyeX, eyeY, 'Color', 'k', 'LineWidth', 1.5, 'UserData', 'emojiLayer');
                fill(gameAx, cos(t3).*.06 + pos(1) - .25, sin(t3).*.06 + pos(2), 'k', 'UserData', 'emojiLayer');
                fill(gameAx, cos(t3).*.06 + pos(1) + .25, sin(t3).*.06 + pos(2), 'k', 'UserData', 'emojiLayer');
                
            case 2 % Happy/Confident
                t1 = linspace(0+pi/5, pi-pi/5, 50);
                t3 = linspace(0, 2*pi, 50);
                
                plot(gameAx, cos(t1).*.15 + pos(1), sin(t1).*.12 + pos(2) - .25, 'Color', 'k', 'LineWidth', 1.5, 'UserData', 'emojiLayer');
                plot(gameAx, [.16, .35] + pos(1), [.12, .16] + pos(2), 'Color', 'k', 'LineWidth', 2, 'UserData', 'emojiLayer');
                plot(gameAx, [-.16, -.35] + pos(1), [.12, .16] + pos(2), 'Color', 'k', 'LineWidth', 2, 'UserData', 'emojiLayer');
                fill(gameAx, cos(t3).*.06 + pos(1) - .25, sin(t3).*.06 + pos(2), 'k', 'UserData', 'emojiLayer');
                fill(gameAx, cos(t3).*.06 + pos(1) + .25, sin(t3).*.06 + pos(2), 'k', 'UserData', 'emojiLayer');
                
            case 3 % Worried/Surrounded
                t1 = linspace(0+pi/8, pi-pi/8, 50);
                mouthX = cos(t1).*.22 + pos(1); mouthX = [mouthX, mouthX(1)];
                mouthY = sin(t1).*.22 + pos(2) - .35; mouthY = [mouthY, mouthY(1)];
                
                t3 = linspace(0, 2*pi, 50);
                plot(gameAx, mouthX, mouthY, 'Color', 'k', 'LineWidth', 1.5, 'UserData', 'emojiLayer');
                
                % Sweat drops
                sweatX = [.1, .1, nan, .16, .16, nan, .22, .22, nan, .28, .28, nan, .34, .34] + pos(1);
                sweatY = [.2, .4, nan, .14, .42, nan, .16, .36, nan, .01, .28, nan, .1, .25] + pos(2);
                plot(gameAx, sweatX, sweatY, 'Color', 'k', 'LineWidth', 1, 'UserData', 'emojiLayer');
                
                plot(gameAx, [-.25,-.25, nan, -.3, -.3, nan, -.2, -.2] + pos(1), ...
                             [-.21,-.08, nan, -.18,-.06, nan, -.15,-.06] + pos(2), ...
                             'Color', 'k', 'LineWidth', 1, 'UserData', 'emojiLayer');
                         
                plot(gameAx, cos(t3).*.06 + pos(1) - .25, sin(t3).*.06 + pos(2), 'Color', 'k', 'LineWidth', 1.5, 'UserData', 'emojiLayer');
                plot(gameAx, cos(t3).*.06 + pos(1) + .25, sin(t3).*.06 + pos(2), 'Color', 'k', 'LineWidth', 1.5, 'UserData', 'emojiLayer');
        end
    end

    function renderStone(pos)
        % Description: Draws the stone shape based on connectivity.
        % This function intelligently merges the stone with neighbors to create
        % the blob aesthetic.
        
        row = pos(1); col = pos(2);
        
        % Remove existing graphics at this location
        delete(patchHandlesMat{row, col});
        delete(lineHandlesMat{row, col});

        if gameStateMat(row, col) ~= 0
            pTurn = sign(gameStateMat(row, col));
            if pTurn > 0
                stoneColor = [105, 105, 107] ./ 255;
            else
                stoneColor = [228, 228, 228] ./ 255;
            end

            % Find neighbors of same color
            [sX, sY] = find(sign(gameStateMat) == pTurn);
            sameSet = [sX, sY];
            
            checkPos = repmat(pos, [4, 1]) + [-1, 0; 1, 0; 0, -1; 0, 1];
            [~, iInd, ~] = intersect(checkPos, sameSet, 'rows');
            iInd = sort(iInd);

            % Drawing logic based on connection configuration (Blob logic)
            if isempty(iInd)
                theta = linspace(0, 2*pi, 100);
                xData = cos(theta) .* 0.5 + row;
                yData = sin(theta) .* 0.5 + col;
                patchHandlesMat{row, col} = fill(gameAx, xData, yData, stoneColor, 'EdgeColor', 'none');
                lineHandlesMat{row, col} = plot(gameAx, xData, yData, 'Color', 'k', 'LineWidth', 2);
            else
                xData = []; yData = []; lX = []; lY = [];
                switch length(iInd)
                    case 1
                        % Single connection shape logic
                        if iInd == 1 % Up
                            t = linspace(-pi/2, pi/2, 100);
                            xData = [-.5, cos(t).*.5, -.5] + row; yData = [-.5, sin(t).*.5, .5] + col;
                        elseif iInd == 2 % Down
                            t = linspace(pi/2, 3*pi/2, 100);
                            xData = [.5, cos(t).*.5, .5] + row; yData = [.5, sin(t).*.5, -.5] + col;
                        elseif iInd == 3 % Left
                            t = linspace(0, pi, 100);
                            xData = [.5, cos(t).*.5, -.5] + row; yData = [-.5, sin(t).*.5, -.5] + col;
                        elseif iInd == 4 % Right
                            t = linspace(pi, 2*pi, 100);
                            xData = [-.5, cos(t).*.5, .5] + row; yData = [.5, sin(t).*.5, .5] + col;
                        end
                        patchHandlesMat{row, col} = fill(gameAx, xData, yData, stoneColor, 'EdgeColor', 'none');
                        lineHandlesMat{row, col} = plot(gameAx, xData, yData, 'Color', 'k', 'LineWidth', 2);
                        
                    case 2
                        % Elbow or Straight connection logic
                        if all(iInd == [1; 2]) % Vertical Bridge
                            xData = [-.5, .5, .5, -.5] + row; yData = [-.5, -.5, .5, .5] + col;
                            lX = [-.5, .5, nan, .5, -.5] + row; lY = [-.5, -.5, nan, .5, .5] + col;
                        elseif all(iInd == [3; 4]) % Horizontal Bridge
                            xData = [-.5, -.5, .5, .5] + row; yData = [-.5, .5, .5, -.5] + col;
                            lX = [-.5, -.5, nan, .5, .5] + row; lY = [-.5, .5, nan, .5, -.5] + col;
                        else % Corner/Elbow
                             % (Simplified logic for brevity, matches original aesthetic)
                             if all(iInd == [1; 3])
                                 t = linspace(0, pi/2, 100);
                                 xData = [-.5, .5, cos(t).*.5, -.5] + row;
                                 yData = [-.5, -.5, sin(t).*.5, .5] + col;
                             elseif all(iInd == [1; 4])
                                 t = linspace(3*pi/2, 2*pi, 100);
                                 xData = [-.5, -.5, cos(t).*.5, .5] + row;
                                 yData = [.5, -.5, sin(t).*.5, .5] + col;
                             elseif all(iInd == [2; 3])
                                 t = linspace(pi/2, pi, 100);
                                 xData = [.5, .5, cos(t).*.5, -.5] + row;
                                 yData = [-.5, .5, sin(t).*.5, -.5] + col;
                             elseif all(iInd == [2; 4])
                                 t = linspace(pi, 3*pi/2, 100);
                                 xData = [.5, -.5, cos(t).*.5, .5] + row;
                                 yData = [.5, .5, sin(t).*.5, -.5] + col;
                             end
                             lX = xData(2:end); lY = yData(2:end);
                        end
                        patchHandlesMat{row, col} = fill(gameAx, xData, yData, stoneColor, 'EdgeColor', 'none');
                        if ~isempty(lX); lineHandlesMat{row, col} = plot(gameAx, lX, lY, 'Color', 'k', 'LineWidth', 2); end

                    case 3
                        % T-Junctions
                         xData = [-.5, .5, .5, -.5] + row; yData = [-.5, -.5, .5, .5] + col;
                         patchHandlesMat{row, col} = fill(gameAx, xData, yData, stoneColor, 'EdgeColor', 'none');
                         
                         if all(iInd == [2;3;4]); lX = [-.5, -.5] + row; lY = [-.5, .5] + col;
                         elseif all(iInd == [1;3;4]); lX = [.5, .5] + row; lY = [-.5, .5] + col;
                         elseif all(iInd == [1;2;4]); lX = [-.5, .5] + row; lY = [-.5, -.5] + col;
                         elseif all(iInd == [1;2;3]); lX = [-.5, .5] + row; lY = [.5, .5] + col;
                         end
                         lineHandlesMat{row, col} = plot(gameAx, lX, lY, 'Color', 'k', 'LineWidth', 2);

                    case 4
                        % Cross (center of +)
                        xData = [-.5, .5, .5, -.5] + row; yData = [-.5, -.5, .5, .5] + col;
                        patchHandlesMat{row, col} = fill(gameAx, xData, yData, stoneColor, 'EdgeColor', 'none');
                        lineHandlesMat{row, col} = []; % No border lines needed for center
                end
            end
        end
    end
end