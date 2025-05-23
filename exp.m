function exp()
try
    % --- 被试信息 ---
    prompt = {'被试编号:', '年龄:', '性别 (男/女/其他):', '实验次序:'};
    dlgtitle = '被试信息';
    dims = [1 35; 1 35; 1 35; 1 35];
    definput = {'P01', '20', '男', '1'};
    answer = inputdlg(prompt, dlgtitle, dims, definput);
    if isempty(answer)
        return;
    end
    participantID = answer{1};
    % 此处可添加更多被试信息检查（例如，视力、色盲筛查，尽管这些是筛选标准 [cite: 1]）

    % --- 实验参数 ---
    % 这些参数应从研究方案或配置文件中加载
    % 屏幕参数
    screenNumber = max(Screen('Screens')); % 如果有外接屏幕，则使用外接屏幕
    viewingDistance_cm = 60; % 观看距离（厘米） [cite: 1]
    displaySize = Screen('DisplaySize', screenNumber); % 返回 [宽, 高]，单位mm
    screenWidth_cm = displaySize(1) / 10; % 转为厘米

    % 时间参数 (秒)
    fixationDuration = 0.500; % 注视点呈现时间 [cite: 1]
    memoryArrayDuration = 0.500; % 记忆阵列呈现时间 [cite: 1]
    retentionIntervalDuration = 1.000; % 记忆保持间隔时间 [cite: 1]
    responseWindowDuration = 3.000; % 最大反应时间 [cite: 1]
    interTrialInterval = 0.700; % 试次间隔时间 [cite: 1]

    % 视角控制的注视点和字体参数
    fixationCrossSize_deg = 0.6; % 注视点大小（度）
    instructionFontSize_deg = 1.0; % 指导语字体大小（度）

    % 刺激参数
    numItems = 6; % 固定为6个项目 [cite: 1]
    itemShapes = {'circle', 'square'}; % 两种基本形状：圆形和方形 [cite: 1]
    numShapesEach = numItems / length(itemShapes); % 每种形状3个 [cite: 1]
    itemDiameter_deg = 1.2; % 项目直径/边长 (视角单位) [cite: 1]
    itemBorderPx = 1; % 1像素黑色边框 [cite: 1]

    % 颜色
    colorsRGB = { ... % 8种高区分度颜色 [cite: 1]
        [255, 0, 0], ...   % Red
        [0, 255, 0], ...   % Green
        [0, 0, 255], ...   % Blue
        [255, 255, 0], ... % Yellow
        [255, 0, 255], ... % Magenta
        [0, 255, 255], ... % Cyan
        [255, 128, 0], ... % Orange
        [128, 0, 255] ...  % Purple
        };
    backgroundColorRGB = [128, 128, 128]; % 中性灰背景 [cite: 1]
    borderColorRGB = [0,0,0]; % 黑色边框 [cite: 1]

    % 布局参数
    % 邻近分组
    groupMaxDistance_deg = 2.8; % 组内元素中心点最大距离 (视角) [cite: 1]
    interGroupMinDistance_deg = 4.0; % 组间最小距离 (视角) [cite: 1]
    % 随机控制布局
    itemCenterMinDistance_deg_random = 2.5; % 项目中心点最小间距 (视角) [cite: 1]
    itemEdgeMinDistance_deg_random = 1.3; % 项目边缘最小间距 (视角) [cite: 1]
    % 虚拟网格
    gridSize = 6; % 6x6 虚拟网格 [cite: 1]
    cellSi_deg = 2.0; % 每个单元格尺寸 (视角) [cite: 1]
    totalDisplayArea_deg = 12.0; % 总显示区域 (视角) [cite: 1]

    % 试次结构
    numConditions = 2; % 邻近分组, 随机控制 [cite: 1]
    trialsPerCondition = 60; % 每个条件60个试次 [cite: 1]
    numTotalTrials = numConditions * trialsPerCondition; % 总共120个试次 [cite: 1]
    numBlocks = 2; % 2个实验区块 [cite: 1]
    trialsPerBlock = numTotalTrials / numBlocks; % 每个区块60个试次 [cite: 1]
    changeTrialPercentage = 0.50; % 50% 的试次为“有变化” [cite: 1]

    % 反应按键 (所有被试一致) [cite: 1]
    KbName('UnifyKeyNames'); % 标准化按键名称
    sameKey = KbName('f'); % 例如，“相同”按键
    differentKey = KbName('j'); % 例如，“不同”按键
    escapeKey = KbName('ESCAPE');

    % --- 设置屏幕及变量 ---
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundColorRGB); % 打开窗口
    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % 开启透明度混合
    Screen('TextFont',window,'-:lang=zh-cn');
    [screenXpixels, ~] = Screen('WindowSize', window); % 获取屏幕像素, screenYpixels not used
    [xCenter, yCenter] = RectCenter(windowRect); % 获取屏幕中心坐标
    ifi = Screen('GetFlipInterval', window); % 获取帧间隔时间

    % 将视角单位转换为像素单位
    itemDiameter_px = visAngToPixels(itemDiameter_deg, viewingDistance_cm, screenXpixels, screenWidth_cm);
    groupMaxDistance_px = visAngToPixels(groupMaxDistance_deg, viewingDistance_cm, screenXpixels, screenWidth_cm);
    interGroupMinDistance_px = visAngToPixels(interGroupMinDistance_deg, viewingDistance_cm, screenXpixels, screenWidth_cm);
    itemCenterMinDistance_px_random = visAngToPixels(itemCenterMinDistance_deg_random, viewingDistance_cm, screenXpixels, screenWidth_cm);
    itemEdgeMinDistance_px_random = visAngToPixels(itemEdgeMinDistance_deg_random, viewingDistance_cm, screenXpixels, screenWidth_cm);
    cell_px = visAngToPixels(cellSi_deg, viewingDistance_cm, screenXpixels, screenWidth_cm);
    totalDisplayArea_px = visAngToPixels(totalDisplayArea_deg, viewingDistance_cm, screenXpixels, screenWidth_cm);
    fixationCrossSize_px = round(visAngToPixels(fixationCrossSize_deg, viewingDistance_cm, screenXpixels, screenWidth_cm));
    instructionFontSize_px = round(visAngToPixels(instructionFontSize_deg, viewingDistance_cm, screenXpixels, screenWidth_cm));

    % 定义项目放置的整体边界框（居中）
    displayRect = CenterRectOnPointd([0 0 totalDisplayArea_px totalDisplayArea_px], xCenter, yCenter);

    % 隐藏鼠标指针
    HideCursor(screenNumber);

    % --- 数据存储 ---
    results.participantID = participantID;
    results.dateTime = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')); % Use modern datetime, standard format
    % Preallocate results.trials
    templateTrialData = struct(...
        'block', NaN, ...
        'trialInBlock', NaN, ...
        'trialOverall', NaN, ...
        'condition', '', ...
        'memoryItemPositions', [], ...
        'memoryItemShapes', {{}}, ...
        'memoryItemColorsRGB', {{}}, ...
        'probeItemIndex', NaN, ...
        'probeItemOriginalColorRGB', [], ...
        'probeItemPresentedColorRGB', [], ...
        'isChangeTrial', NaN, ...
        'expectedResponseKey', NaN, ...
        'participantResponseKey', NaN, ...
        'rt', NaN, ...
        'accuracy', NaN ...
        );
    if numTotalTrials > 0
        results.trials = repmat(templateTrialData, 1, numTotalTrials);
    else
        results.trials = []; % Handle case where numTotalTrials might be zero
    end

    % --- 指导语与练习 ---
    ShowInstructions(window, '欢迎参加实验！按任意键开始练习。');
    RunPracticeTrials(window, 20, ifi, fixationDuration, memoryArrayDuration, retentionIntervalDuration, responseWindowDuration, interTrialInterval, itemDiameter_px, colorsRGB, itemShapes, numShapesEach, numItems, sameKey, differentKey, escapeKey, backgroundColorRGB, borderColorRGB, itemBorderPx, displayRect, itemCenterMinDistance_px_random, itemEdgeMinDistance_px_random, groupMaxDistance_px, interGroupMinDistance_px, cell_px, gridSize); % (20-30个练习试次) [cite: 1]
    ShowInstructions(window, '练习结束。按任意键开始正式实验。');

    % --- 正式实验循环 ---
    trialCounter = 0;
    % 创建平衡条件的试次列表
    conditions = repmat({'NeighborGrouping', 'RandomControl'}, 1, trialsPerCondition);
    trialOrder = conditions(randperm(length(conditions))); % 随机化试次顺序

    for block = 1:numBlocks
        ShowInstructions(window, ['第 ' num2str(block) ' 部分，共 ' num2str(numBlocks) ' 部分。按任意键开始。']);

        for trialInBlock = 1:trialsPerBlock
            trialCounter = trialCounter + 1;
            currentCondition = trialOrder{trialCounter};

            % 1. 试次间隔 (ITI)
            Screen('FillRect', window, backgroundColorRGB);
            Screen('Flip', window);
            WaitSecs(interTrialInterval);

            % 2. 注视点
            DrawFixationCross(window, xCenter, yCenter, fixationCrossSize_px, [0 0 0], 2);
            Screen('Flip', window);
            WaitSecs(fixationDuration);

            % 3. 记忆阵列呈现
            %   A. 决定项目位置、形状和颜色
            tempShapes = [repmat(itemShapes(1), 1, numShapesEach), repmat(itemShapes(2), 1, numShapesEach)]; % 3个圆形，3个方形 [cite: 1]
            trialShapes = tempShapes(randperm(length(tempShapes))); % 随机分配形状

            trialColorsIndices = randperm(length(colorsRGB), numItems); % 随机无放回选择6种颜色 [cite: 1]
            trialColors = colorsRGB(trialColorsIndices);

            if strcmp(currentCondition, 'NeighborGrouping')
                itemPositions = GenerateNeighborGroupLayout(numItems, itemDiameter_px, displayRect, groupMaxDistance_px, interGroupMinDistance_px, cell_px, gridSize);
            else % RandomControl
                itemPositions = GenerateRandomLayout(numItems, itemDiameter_px, displayRect, itemCenterMinDistance_px_random, itemEdgeMinDistance_px_random, cell_px, gridSize);
            end

            % 绘制记忆阵列
            Screen('FillRect', window, backgroundColorRGB);
            for i = 1:numItems
                rect = CenterRectOnPointd([0 0 itemDiameter_px itemDiameter_px], itemPositions(i,1), itemPositions(i,2));
                % Fill with color then frame for memory array items
                if strcmp(trialShapes{i}, 'circle')
                    Screen('FillOval', window, trialColors{i}, rect);
                    Screen('FrameOval', window, borderColorRGB, rect, itemBorderPx);
                else % square
                    Screen('FillRect', window, trialColors{i}, rect);
                    Screen('FrameRect', window, borderColorRGB, rect, itemBorderPx);
                end
            end
            Screen('Flip', window); % memoryArrayFlipTime not used
            WaitSecs(memoryArrayDuration - ifi); % 考虑帧间隔进行调整

            % 4. 记忆保持间隔 (空白屏幕) [cite: 1]
            Screen('FillRect', window, backgroundColorRGB);
            Screen('Flip', window);
            WaitSecs(retentionIntervalDuration);

            % 5. 测试阵列呈现 (单项目探测) [cite: 1]
            probeItemIndex = randi(numItems); % 随机选择一个项目进行探测
            probePosition = itemPositions(probeItemIndex,:);
            originalProbeColor = trialColors{probeItemIndex};
            originalProbeShape = trialShapes{probeItemIndex};

            isChangeTrial = rand() < changeTrialPercentage; % 决定是否为“变化”试次 [cite: 1]

            if isChangeTrial % “有变化”试次
                % 选择一个记忆阵列中未出现过的新颜色 [cite: 1]
                availableColorsForChangeIndices = setdiff(1:length(colorsRGB), trialColorsIndices);
                if isempty(availableColorsForChangeIndices)
                    error('没有足够的不重复颜色用于变化试次！');
                end
                newColorIndex = availableColorsForChangeIndices(randi(length(availableColorsForChangeIndices)));
                probeColor = colorsRGB{newColorIndex};
                correctResponse = differentKey;
            else % “无变化”试次
                probeColor = originalProbeColor;
                correctResponse = sameKey;
            end

            % 绘制测试阵列 (单个探测项目)
            Screen('FillRect', window, backgroundColorRGB);
            rect = CenterRectOnPointd([0 0 itemDiameter_px itemDiameter_px], probePosition(1), probePosition(2));
            if strcmp(originalProbeShape, 'circle')
                Screen('FillOval', window, probeColor, rect);
                Screen('FrameOval', window, borderColorRGB, rect, itemBorderPx);
            else % square
                Screen('FillRect', window, probeColor, rect);
                Screen('FrameRect', window, borderColorRGB, rect, itemBorderPx);
            end
            Screen('Flip', window); % testArrayFlipTime not used

            % 6. 收集反应
            responded = false;
            startTime = GetSecs;
            rt = NaN;
            keyCodePressed = NaN; % Initialize to NaN

            while ~responded && (GetSecs - startTime) < responseWindowDuration
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyIsDown
                    if keyCode(escapeKey)
                        sca; % Clean up screen
                        ShowCursor; % Show cursor
                        disp('实验被用户中止。');
                        % Save data before exiting if needed
                        if exist('participantID', 'var') && exist('results', 'var') && exist('answer', 'var')
                            save([participantID '_session' answer{4} '_abortedData.mat'], 'results');
                        end
                        return; % Exit the function exp
                    elseif keyCode(sameKey)
                        responded = true;
                        rt = secs - startTime;
                        keyCodePressed = sameKey;
                    elseif keyCode(differentKey)
                        responded = true;
                        rt = secs - startTime;
                        keyCodePressed = differentKey;
                    end
                end
            end

            % 如果没有反应，则标记为超时 (rt 保持 NaN, keyCodePressed 保持 NaN)

            % 判断准确性
            accuracy = 0;
            if responded && keyCodePressed == correctResponse
                accuracy = 1;
            end

            % 7. 存储试次数据
            trialData.block = block;
            trialData.trialInBlock = trialInBlock;
            trialData.trialOverall = trialCounter;
            trialData.condition = currentCondition;
            trialData.memoryItemPositions = itemPositions; % 记录记忆项目的位置
            trialData.memoryItemShapes = trialShapes; % 记录记忆项目的形状
            trialData.memoryItemColorsRGB = trialColors; % 记录记忆项目的颜色
            trialData.probeItemIndex = probeItemIndex; % 记录探测项目在记忆阵列中的索引
            trialData.probeItemOriginalColorRGB = originalProbeColor; % 记录探测项目的原始颜色
            trialData.probeItemPresentedColorRGB = probeColor; % 记录探测项目呈现的颜色
            trialData.isChangeTrial = isChangeTrial; % 是否为变化试次
            trialData.expectedResponseKey = correctResponse; % 正确反应按键
            trialData.participantResponseKey = keyCodePressed; % 被试反应按键
            trialData.rt = rt; % 反应时
            trialData.accuracy = accuracy; % 准确性 (0或1)

            if numTotalTrials > 0 % Ensure trialCounter is a valid index
                results.trials(trialCounter) = trialData; % Assign to preallocated structure
            else
                results.trials = [results.trials, trialData]; % Fallback if preallocation failed (e.g. numTotalTrials = 0)
            end

            % --- 反应后短暂暂停 (可作为ITI的一部分) ---
            Screen('FillRect', window, backgroundColorRGB); % 清除探测项目
            Screen('Flip', window);
            % WaitSecs(0.1); % 可选的反应后短暂空白

        end % 结束试次循环

        % 每个block结束后增量保存数据 (好习惯)
        if exist('participantID', 'var') && exist('results', 'var') && exist('answer', 'var')
            save([participantID '_session' answer{4} '_block' num2str(block) '_tempData.mat'], 'results');
        else
            warning('无法保存临时数据：缺少必要变量 (participantID, results, or answer).');
        end
    end % 结束block循环

    % --- 实验结束 ---
    ShowInstructions(window, '实验结束！感谢您的参与。');
    WaitSecs(3);

    % --- 保存最终数据 ---
    if exist('participantID', 'var') && exist('results', 'var') && exist('answer', 'var')
        finalDataFilename = [participantID '_session' answer{4} '_finalData.mat'];
        save(finalDataFilename, 'results');
        disp(['数据已保存至: ' finalDataFilename]);
    else
        warning('无法保存最终数据：缺少必要变量 (participantID, results, or answer).');
        finalDataFilename = ['unknown_participant_finalData_' datestr(now, 'yyyymmddTHHMMSS') '.mat'];
        if exist('results', 'var')
            save(finalDataFilename, 'results');
            disp(['部分数据已保存至: ' finalDataFilename ' (被试信息缺失)']);
        else
            disp('没有数据可保存。');
        end
    end

    % --- 清理 ---
    sca; % 关闭屏幕
    ShowCursor; % 显示鼠标指针

catch ME % 错误处理
    sca;
    ShowCursor;
    disp('!!!!!!!!!!!!!! 发生错误 !!!!!!!!!!!!!!');
    disp(ME.message);
    fprintf('错误类型: %s\n', ME.identifier);
    for i_err = 1:length(ME.stack)
        disp(['文件: ' ME.stack(i_err).file ', 名称: ' ME.stack(i_err).name ', 行: ' num2str(ME.stack(i_err).line)]);
    end
    % 保存目前已收集的数据
    try
        errFilename = ['errorData_' datestr(now, 'yyyymmddTHHMMSS') '.mat'];
        if exist('participantID', 'var') && ~isempty(participantID) && exist('answer', 'var') && ~isempty(answer)
            errFilename = [participantID '_session' answer{4} '_errorData.mat'];
        elseif exist('participantID', 'var') && ~isempty(participantID)
            errFilename = [participantID '_errorData.mat'];
        end

        varsToSave = {};
        if exist('results', 'var')
            varsToSave = [varsToSave, 'results'];
        end
        if exist('ME', 'var')
            varsToSave = [varsToSave, 'ME'];
        end
        if ~isempty(varsToSave)
            save(errFilename, varsToSave{:});
            disp(['错误发生，但部分数据已尝试保存至: ' errFilename]);
        else
            disp('错误发生，没有可保存的数据。');
        end
    catch saveErr
        disp('!!!!!!!!!!!!!! 保存错误数据时发生额外错误 !!!!!!!!!!!!!!');
        disp(saveErr.message);
    end
    rethrow(ME);
end % 结束 try-catch
end % 结束主函数 exp

% --- 辅助函数 ---

function pixels = visAngToPixels(visAng, dist_cm, screenXpixels, screenWidth_cm)
% 将视角单位 (度) 转换为像素单位
% visAng: 视角 (度)
% dist_cm: 观看距离 (厘米)
% screenXpixels: 屏幕水平分辨率 (像素)
% screenWidth_cm: 屏幕宽度 (厘米)

% degPerPixel = rad2deg(atan2(screenWidth_cm/2, dist_cm)) / (screenXpixels/2); % Original, can be simplified
% pixels = visAng / degPerPixel;

% More direct calculation:
% Screen width in visual angle = 2 * atan( (screenWidth_cm/2) / dist_cm )
% Pixels per degree = screenXpixels / (2 * rad2deg(atan( (screenWidth_cm/2) / dist_cm )))
% pixels = visAng * pixelsPerDegree

viewingDistance_px = dist_cm * (screenXpixels / screenWidth_cm); % Viewing distance in terms of horizontal pixels
pixels = tan(deg2rad(visAng/2)) * 2 * viewingDistance_px;
% This formula is common but ensure it matches Psychtoolbox's internal calculations if discrepancies arise.
% A robust way is often to calibrate with a known physical size on screen.
% For small angles, visAng (in rad) approx tan(visAng), so visAng_rad * viewingDistance_px.
% visAng_rad = deg2rad(visAng);
% pixels = visAng_rad * viewingDistance_px; % This is an approximation for small angles.

% Using the provided formula's logic, which seems standard:
pixelPitch_cm = screenWidth_cm / screenXpixels; % size of a pixel in cm
size_on_retina_cm = 2 * dist_cm * tan(deg2rad(visAng/2));
pixels = size_on_retina_cm / pixelPitch_cm;
end

function ShowInstructions(window, text)

Screen('FillRect', window, [128 128 128]); % 灰色背景
DrawFormattedText(window, double(text), 'center', 'center', [0 0 0]); % 黑色文本
Screen('Flip', window);
KbStrokeWait; % 等待按键
WaitSecs(0.2); % 消抖
end

function RunPracticeTrials(window, numPracticeTrials, ifi, fixationDuration, memoryArrayDuration, retentionIntervalDuration, responseWindowDuration, interTrialInterval, itemDiameter_px, colorsRGB, itemShapes, numShapesEach, numItems, sameKey, differentKey, escapeKey, backgroundColorRGB, borderColorRGB, itemBorderPx, displayRect, itemCenterMinDistance_px_random, itemEdgeMinDistance_px_random, groupMaxDistance_px, interGroupMinDistance_px, cell_px, gridSize)
% 简化的练习试次循环，带反馈
ShowInstructions(window, '练习试次。按任意键继续。');

practiceConditions = repmat({'NeighborGrouping', 'RandomControl'}, 1, ceil(numPracticeTrials/2));
practiceOrder = practiceConditions(randperm(length(practiceConditions)));
practiceOrder = practiceOrder(1:numPracticeTrials); % 确保练习试次数正确

for i_prac = 1:numPracticeTrials % Renamed loop variable
    currentCondition = practiceOrder{i_prac};

    Screen('FillRect', window, backgroundColorRGB);
    Screen('Flip', window);
    WaitSecs(interTrialInterval / 2); % 练习中ITI可稍短

    DrawFormattedText(window, '+', 'center', 'center', [0 0 0]);
    Screen('Flip', window);
    WaitSecs(fixationDuration);

    tempShapes_prac = [repmat(itemShapes(1), 1, numShapesEach), repmat(itemShapes(2), 1, numShapesEach)];
    trialShapes_prac = tempShapes_prac(randperm(length(tempShapes_prac)));

    trialColorsIndices_prac = randperm(length(colorsRGB), numItems);
    trialColors_prac = colorsRGB(trialColorsIndices_prac);

    if strcmp(currentCondition, 'NeighborGrouping')
        itemPositions_prac = GenerateNeighborGroupLayout(numItems, itemDiameter_px, displayRect, groupMaxDistance_px, interGroupMinDistance_px, cell_px, gridSize);
    else
        itemPositions_prac = GenerateRandomLayout(numItems, itemDiameter_px, displayRect, itemCenterMinDistance_px_random, itemEdgeMinDistance_px_random, cell_px, gridSize);
    end

    Screen('FillRect', window, backgroundColorRGB);
    for k_item = 1:numItems % Renamed loop variable
        rect = CenterRectOnPointd([0 0 itemDiameter_px itemDiameter_px], itemPositions_prac(k_item,1), itemPositions_prac(k_item,2));
        if strcmp(trialShapes_prac{k_item}, 'circle')
            Screen('FillOval', window, trialColors_prac{k_item}, rect);
            Screen('FrameOval', window, borderColorRGB, rect, itemBorderPx);
        else % square
            Screen('FillRect', window, trialColors_prac{k_item}, rect);
            Screen('FrameRect', window, borderColorRGB, rect, itemBorderPx);
        end
    end
    Screen('Flip', window);
    WaitSecs(memoryArrayDuration - ifi); % Adjusted for flip interval

    % --- 保持间隔 ---
    Screen('FillRect', window, backgroundColorRGB);
    Screen('Flip', window);
    WaitSecs(retentionIntervalDuration);

    % --- 测试探针 (简化版，假设总是无变化，仅用于按键练习) ---
    probeItemIndex_prac = randi(numItems);
    probePosition_prac = itemPositions_prac(probeItemIndex_prac,:);
    originalProbeColor_prac = trialColors_prac{probeItemIndex_prac};
    originalProbeShape_prac = trialShapes_prac{probeItemIndex_prac};

    % For practice, let's make it simpler: 50% change, 50% no change
    isChangeTrial_prac = rand() < 0.5;
    if isChangeTrial_prac
        availableColorsForChangeIndices_prac = setdiff(1:length(colorsRGB), trialColorsIndices_prac);
        if isempty(availableColorsForChangeIndices_prac)
            % Fallback: pick any color not the original if all were somehow used
            temp_colors = 1:length(colorsRGB);
            temp_colors(trialColorsIndices_prac(probeItemIndex_prac)) = []; % remove original
            if isempty(temp_colors), temp_colors = trialColorsIndices_prac(probeItemIndex_prac); end % Should not happen
            newColorIndex_prac = temp_colors(randi(length(temp_colors)));
        else
            newColorIndex_prac = availableColorsForChangeIndices_prac(randi(length(availableColorsForChangeIndices_prac)));
        end
        probeColor_prac = colorsRGB{newColorIndex_prac};
        correctPracticeResponse = differentKey;
    else
        probeColor_prac = originalProbeColor_prac;
        correctPracticeResponse = sameKey;
    end

    Screen('FillRect', window, backgroundColorRGB);
    rect = CenterRectOnPointd([0 0 itemDiameter_px itemDiameter_px], probePosition_prac(1), probePosition_prac(2));
    if strcmp(originalProbeShape_prac, 'circle')
        Screen('FillOval', window, probeColor_prac, rect);
        Screen('FrameOval', window, borderColorRGB, rect, itemBorderPx);
    else % square
        Screen('FillRect', window, probeColor_prac, rect);
        Screen('FrameRect', window, borderColorRGB, rect, itemBorderPx);
    end
    Screen('Flip', window);

    % --- 收集练习反应 ---
    responded_prac = false;
    startTime_prac = GetSecs;
    feedbackText = '';

    while ~responded_prac && (GetSecs - startTime_prac) < responseWindowDuration
        [keyIsDown_prac, secs_prac, keyCode_prac] = KbCheck;
        if keyIsDown_prac
            if keyCode_prac(escapeKey)
                ShowInstructions(window, '练习中止。按任意键返回主实验。');
                return;
            elseif keyCode_prac(sameKey)
                responded_prac = true;
                if correctPracticeResponse == sameKey
                    feedbackText = '正确！';
                else
                    feedbackText = '错误。';
                end
            elseif keyCode_prac(differentKey)
                responded_prac = true;
                if correctPracticeResponse == differentKey
                    feedbackText = '正确！';
                else
                    feedbackText = '错误。';
                end
            end
        end
    end

    if ~responded_prac
        feedbackText = '超时！';
    end

    % 显示反馈
    Screen('FillRect', window, backgroundColorRGB);
    DrawFormattedText(window, double(feedbackText), 'center', 'center', [0 0 0]);
    Screen('Flip', window);
    WaitSecs(1.5); % 显示反馈1.5秒
end
ShowInstructions(window, '练习结束。按任意键继续。');
end

% --- 占位符函数 (如果您的代码依赖它们) ---
function itemPositions = GenerateNeighborGroupLayout(~, itemDiameter_px, displayRect, ~, ~, cell_px, gridSize)
% 占位符：生成邻近分组布局
% 实际实现应确保项目在 displayRect 内，并遵循分组和单元格逻辑
% 这里仅为示例，返回随机位置
disp('警告: GenerateNeighborGroupLayout 未完全实现，使用随机布局代替。');
itemPositions = GenerateRandomLayout(6, itemDiameter_px, displayRect, cell_px*2, cell_px, cell_px, gridSize);
end

function itemPositions = GenerateRandomLayout(numItems, itemDiameter_px, displayRect, itemCenterMinDistance_px, itemEdgeMinDistance_px, ~, ~)
% 占位符：生成随机布局
% 实际实现应确保项目在 displayRect 内，并遵循最小距离约束
disp('警告: GenerateRandomLayout 未完全实现，使用基本随机位置。');
itemPositions = zeros(numItems, 2);
displayRectWidth = RectWidth(displayRect) - itemDiameter_px;
displayRectHeight = RectHeight(displayRect) - itemDiameter_px;
displayRectLeft = displayRect(1) + itemDiameter_px/2;
displayRectTop = displayRect(2) + itemDiameter_px/2;

for i_item = 1:numItems
    placed = false;
    attempts = 0;
    while ~placed && attempts < 1000 % 防止无限循环
        x = displayRectLeft + rand() * displayRectWidth;
        y = displayRectTop + rand() * displayRectHeight;
        currentPos = [x, y];

        if i_item == 1
            placed = true;
        else
            % 检查与先前项目距离 (简化版，仅中心距离)
            tooClose = false;
            for j_item = 1:(i_item-1)
                dist = norm(currentPos - itemPositions(j_item,:));
                if dist < itemCenterMinDistance_px % 使用 itemCenterMinDistance_px
                    tooClose = true;
                    break;
                end
            end
            if ~tooClose
                placed = true;
            end
        end
        attempts = attempts + 1;
    end
    if ~placed
        warning('GenerateRandomLayout: 可能无法在约束条件下放置所有项目。');
        % 如果无法放置，则将其放在一个随机有效位置，忽略某些约束
        itemPositions(i_item, :) = [displayRectLeft + rand() * displayRectWidth, displayRectTop + rand() * displayRectHeight];
    else
        itemPositions(i_item, :) = currentPos;
    end
end
end

function DrawFixationCross(window, x, y, size_px, color, ~)
% 在(x, y)处绘制一个圆形注视点，size_px为直径
rect = [x - size_px/2, y - size_px/2, x + size_px/2, y + size_px/2];
Screen('FillOval', window, color, rect);
end