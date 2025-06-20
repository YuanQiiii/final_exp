function prop()
try
    Screen('Preference', 'SkipSyncTests', 1);
    PsychDefaultSetup(1);
    rng(42); % 固定种子用于测试，确保结果可重现

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
    % 此处可添加更多被试信息检查（例如，视力、色盲筛查，尽管这些是筛选标准 ）

    % --- 实验参数 ---
    % 这些参数应从研究方案或配置文件中加载
    % 屏幕参数
    screenNumber = max(Screen('Screens')); % 如果有外接屏幕，则使用外接屏幕
    viewingDistance_cm = 60; % 观看距离（厘米）
    displaySize = Screen('DisplaySize', screenNumber); % 返回 [宽, 高]，单位mm
    screenWidth_cm = displaySize(1) / 10; % 转为厘米

    % 时间参数 (秒)
    fixationDuration = 0.500; % 注视点呈现时间
    memoryArrayDuration = 0.500; % 记忆阵列呈现时间
    retentionIntervalDuration = 0.900; % 记忆保持间隔时间
    responseWindowDuration = 3.000; % 最大反应时间
    interTrialInterval = 1.000; % 试次间隔时间，改为1000ms

    % 视角控制的注视点和字体参数
    fixationCrossSize_deg = 0.6; % 注视点大小（度）
    instructionFontSize_deg = 0.5; % 指导语字体大小（度）

    % 刺激参数
    setSize = [3, 4]; % 记忆负荷：3, 4个项目
    itemShapes = {'square'}; % 只使用正方形
    itemDiameter_deg = 1.2; % 项目直径/边长 (视角单位)
    itemBorderPx = 1; % 1像素黑色边框
    colorsRGB = {
        [210, 70, 70],   % 柔和红
        [70, 190, 70],   % 柔和绿
        [70, 70, 210],   % 柔和蓝
        [200, 200, 70],  % 柔和黄
        [200, 70, 200],  % 柔和品红
        [70, 200, 200],  % 柔和青
        [230, 140, 50],  % 柔和橙
        [140, 70, 200]   % 柔和紫
        };
    backgroundColorRGB = [128, 128, 128]; % 中性灰背景
    borderColorRGB = [0,0,0]; % 黑色边框
    gridLineColorRGB = [100, 100, 100];  % 灰色网格线，不太显眼

    % 网格类型
    gridTypes = {'NoGrid', 'Grid6x6', 'Grid3x3', 'Grid2x2', 'Grid1x1'};

    % 布局参数
    % 随机控制布局
    itemCenterMinDistance_deg_random = 2.5; % 项目中心点最小间距 (视角)
    itemEdgeMinDistance_deg_random = 1.3; % 项目边缘最小间距 (视角)
    % 虚拟网格
    gridSize = 6; % 6x6网格
    cellSi_deg = itemDiameter_deg; % 将网格单元格大小设为与元素相同
    totalDisplayArea_deg = gridSize * cellSi_deg; % 根据网格大小和单元格大小计算总显示区域

    % 试次结构
    numGridTypes = length(gridTypes); % 5种网格类型
    numSetSizes = length(setSize); % 2种记忆负荷
    trialsPerCondition = 18; % 每个条件12个试次
    numTotalTrials = numGridTypes * numSetSizes * trialsPerCondition; % 总共180个试次
    numBlocks = 3; % 3个实验区块（每种网格类型一个区块）
    trialsPerBlock = numTotalTrials / numBlocks; % 每个区块60个试次
    changeTrialPercentage = 0.50; % 50% 的试次为"有变化"

    % 反应按键 (所有被试一致)
    KbName('UnifyKeyNames'); % 标准化按键名称
    sameKey = KbName('f'); % "相同"按键
    differentKey = KbName('j'); % "不同"按键
    escapeKey = KbName('ESCAPE');
    DisableKeysForKbCheck(133); % 笔记本卡键解决,请提前运行test脚本确定卡住的按键

    % --- 设置屏幕及变量 ---
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundColorRGB); % 打开窗口
    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % 开启透明度混合
    Screen('TextFont',window,'-:lang=zh-cn');
    [screenXpixels, ~] = Screen('WindowSize', window); % 获取屏幕像素, screenYpixels not used
    [xCenter, yCenter] = RectCenter(windowRect); % 获取屏幕中心坐标
    ifi = Screen('GetFlipInterval', window); % 获取帧间隔时间

    % 将视角单位转换为像素单位
    itemDiameter_px = visAngToPixels(itemDiameter_deg, viewingDistance_cm, screenXpixels, screenWidth_cm);
    itemCenterMinDistance_px_random = visAngToPixels(itemCenterMinDistance_deg_random, viewingDistance_cm, screenXpixels, screenWidth_cm);
    itemEdgeMinDistance_px_random = visAngToPixels(itemEdgeMinDistance_deg_random, viewingDistance_cm, screenXpixels, screenWidth_cm);
    cell_px = visAngToPixels(cellSi_deg, viewingDistance_cm, screenXpixels, screenWidth_cm);
    totalDisplayArea_px = visAngToPixels(totalDisplayArea_deg, viewingDistance_cm, screenXpixels, screenWidth_cm);
    fixationCrossSize_px = round(visAngToPixels(fixationCrossSize_deg, viewingDistance_cm, screenXpixels, screenWidth_cm));
    instructionFontSize_px = round(visAngToPixels(instructionFontSize_deg, viewingDistance_cm, screenXpixels, screenWidth_cm));

    % 定义项目放置的整体边界框（居中）
    displayRect = CenterRectOnPointd([0 0 totalDisplayArea_px totalDisplayArea_px], xCenter, yCenter);
    % 限制终端读取字符
    ListenChar(2);
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
        'gridType', '', ...
        'setSize', NaN, ...
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
    instructionText_Welcome = ['欢迎您参加本次实验！\n\n'...
        '在本实验中，您将看到一系列由彩色方块组成的记忆图案。您的任务是尽可能准确地记住屏幕上呈现的所有彩色方块的【颜色和位置】。\n\n' ...
        '短暂的记忆时间后，屏幕上会单独呈现一个方块，这个方块来自于刚才记忆图案中的某个位置，即【位置一定是正确的】。\n'...
        '但是颜色【不一定正确】。\n\n'...
        '您需要判断这个单独呈现的方块的【颜色】是否与它在原始记忆图案中对应位置的方块颜色【相同】。\n\n' ...
        '如果颜色相同，请按键盘上的【F】键；如果颜色不同，请按键盘上的【J】键。\n' ...
        '请您在保证准确的前提下，尽可能快速地做出反应。\n\n' ...
        '实验包含练习和正式两个阶段。练习阶段可以帮助您熟悉任务流程。\n' ...
        '如果您有任何疑问，请现在向实验员提出。\n\n' ...
        '准备好后，请按任意键开始【练习】。'];
    ShowInstructions(window, instructionText_Welcome, instructionFontSize_px);
    RunPracticeTrials(window, 20, ifi, fixationDuration, memoryArrayDuration, retentionIntervalDuration, responseWindowDuration, interTrialInterval, itemDiameter_px, colorsRGB, itemShapes, setSize, sameKey, differentKey, escapeKey, backgroundColorRGB, borderColorRGB, itemBorderPx, displayRect, itemCenterMinDistance_px_random, itemEdgeMinDistance_px_random, cell_px, gridSize, instructionFontSize_px, fixationCrossSize_px, xCenter, yCenter, gridLineColorRGB, gridTypes); % 20个练习试次

    instructionText_FormalStart = ['练习结束。\n\n' ...
        '接下来将开始正式实验。正式实验的流程与练习相同，\n' ...
        '但【不会再有正确或错误的反馈】。\n\n' ...
        '请集中注意力，仍然是尽可能准确地记住颜色和位置，\n' ...
        '并对探测项目的颜色做出"相同"或"不同"的判断。\n' ...
        '反应同样要求【快而准】。\n\n' ...
        '如果您准备好了，请按任意键开始正式实验。'];
    ShowInstructions(window, instructionText_FormalStart, instructionFontSize_px);

    % --- 正式实验循环 ---
    trialCounter = 0;

    % 创建包含所有条件组合的试次列表
    allConditions = [];
    changeTrials = []; % 0=无变化，1=有变化

    for gridIdx = 1:numGridTypes
        for ssIdx = 1:numSetSizes
            currentGridType = gridTypes{gridIdx};
            currentSetSize = setSize(ssIdx);

            % 确保每个条件组合有相同数量的变化/无变化试次
            halfTrials = trialsPerCondition / 2;
            if mod(trialsPerCondition, 2) ~= 0
                warning('trialsPerCondition应为偶数以确保变化/无变化试次平衡');
                halfTrials = floor(halfTrials);
            end

            % 为每个条件创建平衡的变化/无变化试次
            condTrials = repmat({currentGridType, currentSetSize}, trialsPerCondition, 1);
            condChanges = [zeros(halfTrials, 1); ones(trialsPerCondition-halfTrials, 1)];

            allConditions = [allConditions; condTrials];
            changeTrials = [changeTrials; condChanges];
        end
    end

    % 创建平衡的区块分配
    trialsPerCondPerBlock = trialsPerCondition / numBlocks;
    if mod(trialsPerCondition, numBlocks) ~= 0
        warning('trialsPerCondition应能被numBlocks整除以确保区块间平衡');
    end

    % 在区块内随机化，同时保持条件平衡
    blockConditions = cell(numBlocks, 1);
    for blockIdx = 1:numBlocks
        blockConds = [];
        blockChanges = [];

        for gridIdx = 1:numGridTypes
            for ssIdx = 1:numSetSizes
                currentGridType = gridTypes{gridIdx};
                currentSetSize = setSize(ssIdx);

                % 为当前区块找出对应的条件试次
                condIndices = find(strcmp({allConditions{:,1}}, currentGridType) & [allConditions{:,2}] == currentSetSize);

                % 分别获取变化和无变化试次
                changeIndices = condIndices(changeTrials(condIndices) == 1);
                noChangeIndices = condIndices(changeTrials(condIndices) == 0);

                % 随机选择此区块所需的试次数
                blockChangeIdx = changeIndices(randperm(length(changeIndices), trialsPerCondPerBlock/2));
                blockNoChangeIdx = noChangeIndices(randperm(length(noChangeIndices), trialsPerCondPerBlock/2));

                % 添加到区块试次中
                selectedIndices = [blockChangeIdx; blockNoChangeIdx];
                blockConds = [blockConds; allConditions(selectedIndices,:)];
                blockChanges = [blockChanges; changeTrials(selectedIndices)];
            end
        end

        % 随机化区块内试次顺序
        blockRandomOrder = randperm(size(blockConds, 1));
        % 确保 blockChanges 是列向量并正确转换为 cell 数组
        blockChangesCell = num2cell(blockChanges(blockRandomOrder));
        % 检查并调整维度
        if size(blockConds(blockRandomOrder,:), 1) ~= size(blockChangesCell, 1)
            blockChangesCell = reshape(blockChangesCell, [], 1);
        end
        blockConditions{blockIdx} = [blockConds(blockRandomOrder,:), blockChangesCell];
    end

    % 开始正式实验
    for blockIdx = 1:numBlocks
        currentBlockConditions = blockConditions{blockIdx};
        numTrialsInBlock = size(currentBlockConditions, 1);

        ShowInstructions(window, ['第 ' num2str(blockIdx) ' 部分，共 ' num2str(numBlocks) ' 部分。按任意键开始。'], instructionFontSize_px);

        for trialInBlock = 1:numTrialsInBlock
            trialCounter = trialCounter + 1;
            currentGridType = currentBlockConditions{trialInBlock, 1};
            currentSetSize = currentBlockConditions{trialInBlock, 2};

            % 1. 试次间隔 (ITI)
            Screen('FillRect', window, backgroundColorRGB);
            Screen('Flip', window);
            WaitSecs(interTrialInterval);

            % 2. 注视点
            DrawFixationCross(window, xCenter, yCenter, fixationCrossSize_px, [255 255 255], 2);
            Screen('Flip', window);
            WaitSecs(fixationDuration);

            % 3. 记忆阵列呈现
            %   A. 决定项目位置、形状和颜色
            tempShapes = repmat(itemShapes, 1, currentSetSize); % 全部使用正方形
            trialShapes = tempShapes; % 不需要随机排列，因为只有一种形状

            trialColorsIndices = randperm(length(colorsRGB), currentSetSize); % 随机无放回选择颜色
            trialColors = colorsRGB(trialColorsIndices);

            % 使用随机布局函数生成项目位置
            itemPositions = GenerateRandomLayout(currentSetSize, itemDiameter_px, displayRect, itemCenterMinDistance_px_random, itemEdgeMinDistance_px_random, cell_px, gridSize, xCenter, yCenter, fixationCrossSize_px);

            % 检查布局是否生成成功
            if isempty(itemPositions)
                disp(['正式试次 ' num2str(trialCounter) '：无法生成有效布局，使用备用布局']);
                % 使用简单的备用布局
                itemPositions = zeros(currentSetSize, 2);
                gridRows = ceil(sqrt(currentSetSize));
                gridCols = ceil(currentSetSize / gridRows);
                spacing = totalDisplayArea_px / max(gridRows, gridCols);
                item = 1;
                for row = 1:gridRows
                    for col = 1:gridCols
                        if item <= currentSetSize
                            px = displayRect(1) + col * spacing - spacing/2;
                            py = displayRect(2) + row * spacing - spacing/2;
                            itemPositions(item,:) = [px, py];
                            item = item + 1;
                        end
                    end
                end
            end

            % 绘制记忆阵列
            Screen('FillRect', window, backgroundColorRGB);

            % 绘制当前条件的网格
            DrawGridByType(window, currentGridType, gridSize, cell_px, xCenter, yCenter, gridLineColorRGB, displayRect);

            % 绘制记忆项目
            for i = 1:currentSetSize
                rect = CenterRectOnPointd([0 0 itemDiameter_px itemDiameter_px], itemPositions(i,1), itemPositions(i,2));
                % 直接绘制正方形
                Screen('FillRect', window, trialColors{i}, rect);
                Screen('FrameRect', window, borderColorRGB, rect, itemBorderPx);
            end
            Screen('Flip', window);
            WaitSecs(memoryArrayDuration - ifi);

            % 4. 记忆保持间隔
            Screen('FillRect', window, backgroundColorRGB);
            % 在保持间隔期间只显示网格
            % DrawGridByType(window, currentGridType, gridSize, cell_px, xCenter, yCenter, gridLineColorRGB, displayRect);
            Screen('Flip', window);
            WaitSecs(retentionIntervalDuration);

            % 5. 测试阵列呈现 (单项目探测)
            probeItemIndex = randi(currentSetSize); % 随机选择一个项目进行探测
            probePosition = itemPositions(probeItemIndex,:);
            originalProbeColor = trialColors{probeItemIndex};
            originalProbeShape = trialShapes{probeItemIndex};

            isChangeTrial = rand() < changeTrialPercentage; % 决定是否为"变化"试次

            if isChangeTrial % "有变化"试次
                % 选择一个记忆阵列中未出现过的新颜色
                availableColorsForChangeIndices = setdiff(1:length(colorsRGB), trialColorsIndices);
                if isempty(availableColorsForChangeIndices)
                    error('没有足够的不重复颜色用于变化试次！');
                end
                newColorIndex = availableColorsForChangeIndices(randi(length(availableColorsForChangeIndices)));
                probeColor = colorsRGB{newColorIndex};
                correctResponse = differentKey;
            else % "无变化"试次
                probeColor = originalProbeColor;
                correctResponse = sameKey;
            end

            % 绘制测试阵列 (单个探测项目)
            Screen('FillRect', window, backgroundColorRGB);
            % 先绘制网格
            DrawGridByType(window, currentGridType, gridSize, cell_px, xCenter, yCenter, gridLineColorRGB, displayRect);

            rect = CenterRectOnPointd([0 0 itemDiameter_px itemDiameter_px], probePosition(1), probePosition(2));
            % 直接绘制正方形
            Screen('FillRect', window, probeColor, rect);
            Screen('FrameRect', window, borderColorRGB, rect, itemBorderPx);
            Screen('Flip', window);

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
            trialData.block = blockIdx;
            trialData.trialInBlock = trialInBlock;
            trialData.trialOverall = trialCounter;
            trialData.gridType = currentGridType;
            trialData.setSize = currentSetSize;
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
            save([participantID '_session' answer{4} '_block' num2str(blockIdx) '_tempData.mat'], 'results');
        else
            warning('无法保存临时数据：缺少必要变量 (participantID, results, or answer).');
        end

        % 每个block之间提供短暂休息
        if blockIdx < numBlocks
            ShowInstructions(window, ['您已完成第 ' num2str(blockIdx) ' 部分，可以稍作休息。\n\n' ...
                '休息好后，请按任意键继续下一部分。'], instructionFontSize_px);
        end
    end % 结束block循环

    % --- 实验结束 ---
    instructionText_End = ['实验已全部完成！\n\n' ...
        '非常感谢您的参与和耐心配合。\n\n' ...
        '本实验旨在研究不同网格结构对视觉工作记忆的影响，\n' ...
        '您的数据将对我们的研究提供宝贵帮助。\n\n' ...
        '如果您对实验有任何疑问，可以向实验员咨询。\n\n' ...
        '请休息片刻，实验到此结束。'];
    ShowInstructions(window, instructionText_End, instructionFontSize_px);
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
    ListenChar(0); % 确保恢复键盘监听状态
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
ListenChar(0);
end % 结束主函数 exp

% --- 辅助函数 ---

function pixels = visAngToPixels(visAng, dist_cm, screenXpixels, screenWidth_cm)
% 将视角单位 (度) 转换为像素单位
% visAng: 视角 (度)
% dist_cm: 观看距离 (厘米)
% screenXpixels: 屏幕水平分辨率 (像素)
% screenWidth_cm: 屏幕宽度 (厘米)

pixelPitch_cm = screenWidth_cm / screenXpixels; % size of a pixel in cm
size_on_screen_cm = 2 * dist_cm * tan(deg2rad(visAng/2)); % Physical size of the stimulus on the screen
pixels = round(size_on_screen_cm / pixelPitch_cm); % Round to nearest pixel
end

function ShowInstructions(window, text, fontSize_px)
Screen('FillRect', window, [128 128 128]); % 灰色背景
Screen('TextSize', window, fontSize_px); % 设置字体大小
DrawFormattedText(window, double(text), 'center', 'center', [255 255 255]); % 白色文本
Screen('Flip', window);
KbStrokeWait; % 等待按键
WaitSecs(0.2); % 消抖
end

function RunPracticeTrials(window, numPracticeTrials, ifi, fixationDuration, memoryArrayDuration, retentionIntervalDuration, responseWindowDuration, interTrialInterval, itemDiameter_px, colorsRGB, itemShapes, setSize, sameKey, differentKey, escapeKey, backgroundColorRGB, borderColorRGB, itemBorderPx, displayRect, itemCenterMinDistance_px_random, itemEdgeMinDistance_px_random, cell_px, gridSize, instructionFontSize_px, fixationCrossSize_px, xCenter, yCenter, gridLineColor, gridTypes)
% 简化的练习试次循环，带反馈
instructionText_PracticeStart = ['现在开始练习。\n\n' ...
    '练习的目的是帮助您熟悉任务流程和按键操作。\n' ...
    '练习试次中，每次反应后屏幕会给出【正确】、【错误】或【超时】的反馈。\n' ...
    '请利用练习机会，尽量理解任务要求。\n\n' ...
    '按任意键开始第一个练习试次。'];
ShowInstructions(window, instructionText_PracticeStart, instructionFontSize_px);

% 练习试次平均分配不同的条件
practiceSetSizes = setSize(randi(length(setSize), numPracticeTrials, 1)); % 随机分配记忆负荷
practiceGridTypes = gridTypes(randi(length(gridTypes), numPracticeTrials, 1)); % 随机分配网格类型

for i_prac = 1:numPracticeTrials
    currentGridType = practiceGridTypes{i_prac};
    currentSetSize = practiceSetSizes(i_prac);

    Screen('FillRect', window, backgroundColorRGB);
    Screen('Flip', window);
    WaitSecs(interTrialInterval / 2); % 练习中ITI可稍短

    % 使用 DrawFixationCross 绘制注视点
    DrawFixationCross(window, xCenter, yCenter, fixationCrossSize_px, [255 255 255], 2);
    Screen('Flip', window);
    WaitSecs(fixationDuration);

    tempShapes_prac = repmat(itemShapes, 1, currentSetSize); % 全部使用正方形
    trialShapes_prac = tempShapes_prac; % 不需要随机排列

    trialColorsIndices_prac = randperm(length(colorsRGB), currentSetSize);
    trialColors_prac = colorsRGB(trialColorsIndices_prac);

    % 使用随机布局函数生成项目位置
    itemPositions_prac = GenerateRandomLayout(currentSetSize, itemDiameter_px, displayRect, itemCenterMinDistance_px_random, itemEdgeMinDistance_px_random, cell_px, gridSize, xCenter, yCenter, fixationCrossSize_px);

    % 检查布局是否生成成功
    if isempty(itemPositions_prac)
        disp(['练习试次 ' num2str(i_prac) '：无法生成有效布局，使用备用布局']);
        % 使用简单的备用布局
        itemPositions_prac = zeros(currentSetSize, 2);
        gridRows = ceil(sqrt(currentSetSize));
        gridCols = ceil(currentSetSize / gridRows);
        spacing = totalDisplayArea_px / max(gridRows, gridCols);
        item = 1;
        for row = 1:gridRows
            for col = 1:gridCols
                if item <= currentSetSize
                    px = displayRect(1) + col * spacing - spacing/2;
                    py = displayRect(2) + row * spacing - spacing/2;
                    itemPositions_prac(item,:) = [px, py];
                    item = item + 1;
                end
            end
        end
    end

    Screen('FillRect', window, backgroundColorRGB);

    % 绘制当前条件的网格
    DrawGridByType(window, currentGridType, gridSize, cell_px, xCenter, yCenter, gridLineColor, displayRect);

    % 绘制记忆项目
    for k_item = 1:currentSetSize
        rect = CenterRectOnPointd([0 0 itemDiameter_px itemDiameter_px], itemPositions_prac(k_item,1), itemPositions_prac(k_item,2));
        % 直接绘制正方形
        Screen('FillRect', window, trialColors_prac{k_item}, rect);
        Screen('FrameRect', window, borderColorRGB, rect, itemBorderPx);
    end
    Screen('Flip', window);
    WaitSecs(memoryArrayDuration - ifi); % Adjusted for flip interval

    % --- 保持间隔 ---
    Screen('FillRect', window, backgroundColorRGB);
    % 在保持间隔期间只显示网格
    DrawGridByType(window, currentGridType, gridSize, cell_px, xCenter, yCenter, gridLineColor, displayRect);
    Screen('Flip', window);
    WaitSecs(retentionIntervalDuration);

    % --- 测试探针 ---
    probeItemIndex_prac = randi(currentSetSize);
    probePosition_prac = itemPositions_prac(probeItemIndex_prac,:);
    originalProbeColor_prac = trialColors_prac{probeItemIndex_prac};
    originalProbeShape_prac = trialShapes_prac{probeItemIndex_prac};

    % 50% 变化, 50% 不变化
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
    % 绘制当前条件的网格
    DrawGridByType(window, currentGridType, gridSize, cell_px, xCenter, yCenter, gridLineColor, displayRect);

    rect = CenterRectOnPointd([0 0 itemDiameter_px itemDiameter_px], probePosition_prac(1), probePosition_prac(2));
    % 直接绘制正方形
    Screen('FillRect', window, probeColor_prac, rect);
    Screen('FrameRect', window, borderColorRGB, rect, itemBorderPx);
    Screen('Flip', window);

    % --- 收集练习反应 ---
    responded_prac = false;
    startTime_prac = GetSecs;
    feedbackText = '';

    while ~responded_prac && (GetSecs - startTime_prac) < responseWindowDuration
        [keyIsDown_prac, secs_prac, keyCode_prac] = KbCheck;
        if keyIsDown_prac
            if keyCode_prac(escapeKey)
                ShowInstructions(window, '练习中止。按任意键返回主实验。', instructionFontSize_px);
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
    DrawFormattedText(window, double(feedbackText), 'center', 'center', [255 255 255]);
    Screen('Flip', window);
    WaitSecs(1.5); % 显示反馈1.5秒
end
ShowInstructions(window, '练习结束。按任意键继续。', instructionFontSize_px);
end

function itemPositions = GenerateRandomLayout(numItems, itemDiameter_px, displayRect, itemCenterMinDistance_px_random, itemEdgeMinDistance_px_random, cell_px, gridSize, xCenter, yCenter, fixationCrossSize_px)
% GenerateRandomLayout: Generates item positions randomly on a grid.
%
% Inputs:
%   numItems: Total number of items.
%   itemDiameter_px: Diameter of each item.
%   displayRect: [left, top, right, bottom] of the allowed display area.
%   itemCenterMinDistance_px_random: Minimum distance between centers of any two items.
%   itemEdgeMinDistance_px_random: Minimum distance between edges of any two items.
%   cell_px: Cell size in pixels of the grid.
%   gridSize: Size of the grid (e.g., 6 for a 6x6 grid).
%   xCenter, yCenter: Center coordinates of the screen/displayRect.
%   fixationCrossSize_px: Size of the central fixation cross.
%
% Output:
%   itemPositions: An N-by-2 matrix of [x, y] coordinates. Returns empty if failed.

itemPositions = zeros(numItems, 2);
maxTotalAttempts = 100;
fixationRadius = (fixationCrossSize_px / 2) + (itemDiameter_px / 2);

% 计算网格的尺寸和位置
gridWidth = gridSize * cell_px;
gridHeight = gridSize * cell_px;
gridLeft = xCenter - (gridWidth / 2);
gridTop = yCenter - (gridHeight / 2);
gridRight = gridLeft + gridWidth;
gridBottom = gridTop + gridHeight;

% 创建网格中心点坐标列表
gridCenters = zeros(gridSize * gridSize, 2);
idx = 1;
for row = 1:gridSize
    for col = 1:gridSize
        % 计算格子中心点坐标
        centerX = gridLeft + ((col - 0.5) * cell_px);
        centerY = gridTop + ((row - 0.5) * cell_px);
        gridCenters(idx, :) = [centerX, centerY];
        idx = idx + 1;
    end
end

% 确保最小距离要求
minReqCenterDist = max(itemCenterMinDistance_px_random, itemEdgeMinDistance_px_random + itemDiameter_px);

for attempt = 1:maxTotalAttempts
    % 随机打乱网格顺序
    shuffledGridIndices = randperm(size(gridCenters, 1));
    positions_candidate = zeros(numItems, 2);
    usedIndices = [];
    placed = 0;

    for i = 1:length(shuffledGridIndices)
        gridIdx = shuffledGridIndices(i);
        pos = gridCenters(gridIdx, :);

        % 检查是否过于靠近注视点
        if norm(pos - [xCenter, yCenter]) < fixationRadius
            continue;
        end

        % 检查与已放置元素的距离
        tooClose = false;
        for j = 1:placed
            if norm(pos - positions_candidate(j, :)) < minReqCenterDist
                tooClose = true;
                break;
            end
        end

        if tooClose
            continue;
        end

        % 放置成功
        placed = placed + 1;
        positions_candidate(placed, :) = pos;
        usedIndices = [usedIndices, gridIdx];

        % 如果已放置足够数量的元素，则完成
        if placed == numItems
            itemPositions = positions_candidate;
            disp('GenerateRandomLayout: Success on grid.');
            return;
        end
    end
end

warning('GenerateRandomLayout: Failed to generate a valid layout after %d attempts.', maxTotalAttempts);
itemPositions = []; % 失败返回空数组
end

function DrawFixationCross(window, x, y, size_px, color, ~)
% 在(x, y)处绘制一个圆形注视点，size_px为直径
rect = [x - size_px/2, y - size_px/2, x + size_px/2, y + size_px/2];
Screen('FillOval', window, color, rect);
end

function DrawGridByType(window, gridType, gridSize, cell_px, xCenter, yCenter, gridLineColor, displayRect)
% 根据网格类型绘制不同的网格
%
% 输入:
%   window: 窗口句柄
%   gridType: 网格类型字符串，可以是 'NoGrid', 'Grid6x6', 'Grid3x3', 'Grid2x2', 'Grid1x1'
%   gridSize: 网格大小 (6 表示 6x6 网格)
%   cell_px: 单元格大小 (像素)
%   xCenter, yCenter: 屏幕中心坐标
%   gridLineColor: 网格线颜色 [R G B]
%   displayRect: 显示区域的边界矩形 [left top right bottom]

gridWidth = gridSize * cell_px;
gridHeight = gridSize * cell_px;
gridLeft = xCenter - (gridWidth / 2);
gridTop = yCenter - (gridHeight / 2);
gridRight = gridLeft + gridWidth;
gridBottom = gridTop + gridHeight;

switch gridType
    case 'NoGrid'
        % 不绘制任何网格
        return;

    case 'Grid6x6'
        % 绘制完整的6x6网格
        % 绘制水平网格线
        for row = 0:gridSize
            yPos = gridTop + (row * cell_px);
            Screen('DrawLine', window, gridLineColor, gridLeft, yPos, gridRight, yPos, 3); % 从1改为3
        end

        % 绘制垂直网格线
        for col = 0:gridSize
            xPos = gridLeft + (col * cell_px);
            Screen('DrawLine', window, gridLineColor, xPos, gridTop, xPos, gridBottom, 3); % 从1改为3
        end

    case 'Grid3x3'
        % 绘制3x3超级网格 (每2个单元格一条线)
        % 绘制水平超级网格线
        for row = 0:2:gridSize
            yPos = gridTop + (row * cell_px);
            Screen('DrawLine', window, gridLineColor, gridLeft, yPos, gridRight, yPos, 4); % 从2改为4
        end

        % 绘制垂直超级网格线
        for col = 0:2:gridSize
            xPos = gridLeft + (col * cell_px);
            Screen('DrawLine', window, gridLineColor, xPos, gridTop, xPos, gridBottom, 4); % 从2改为4
        end

    case 'Grid2x2'
        % 绘制2x2超级网格 (每3个单元格一条线)
        % 绘制水平超级网格线
        for row = 0:3:gridSize
            yPos = gridTop + (row * cell_px);
            Screen('DrawLine', window, gridLineColor, gridLeft, yPos, gridRight, yPos, 4); % 从2改为4
        end

        % 绘制垂直超级网格线
        for col = 0:3:gridSize
            xPos = gridLeft + (col * cell_px);
            Screen('DrawLine', window, gridLineColor, xPos, gridTop, xPos, gridBottom, 4); % 从2改为4
        end

    case 'Grid1x1'
        % 只绘制整体边框
        Screen('FrameRect', window, gridLineColor, [gridLeft, gridTop, gridRight, gridBottom], 4); % 从2改为4

    otherwise
        warning('未知的网格类型: %s', gridType);
end
end