function mat2xlsx()
% --- 用户设置 ---
[matFileName, matFilePath] = uigetfile('*.mat', '请选择要转换的 .mat 数据文件');
if isequal(matFileName, 0)
    disp('用户取消了操作。');
    return;
end
fullMatFileName = fullfile(matFilePath, matFileName);

[xlsxFileName, xlsxFilePath] = uiputfile('*.xlsx', '请指定要保存的 Excel 文件名', [matFileName(1:end-4) '.xlsx']);
if isequal(xlsxFileName, 0)
    disp('用户取消了操作。');
    return;
end
fullXlsxFileName = fullfile(xlsxFilePath, xlsxFileName);

% --- 加载数据 ---
try
    loadedData = load(fullMatFileName);
    disp(['成功加载: ' fullMatFileName]);
catch ME
    disp(['加载文件时出错: ' fullMatFileName]);
    disp(ME.message);
    return;
end

% 检查 'results' 和 'results.trials' 是否存在
if ~isfield(loadedData, 'results') || ~isfield(loadedData.results, 'trials')
    disp('错误: .mat 文件中未找到 "results.trials" 结构。');
    disp('请确保选择了正确的实验数据文件。');
    % 尝试列出加载的变量，帮助用户排查
    disp('加载的变量包括:');
    disp(fieldnames(loadedData));
    return;
end

trialsData = loadedData.results.trials;

if isempty(trialsData)
    disp('警告: "results.trials" 为空，没有数据可导出。');
    return;
end

numTrials = length(trialsData);
if numTrials == 0
    disp('没有试次数据可供转换。');
    return;
end

% --- 预处理数据以便写入表格 ---
% 创建一个新的结构数组，用于存储适合表格的数据
% 我们会选择性地转换或保留字段

% 初始化一个空的结构体来定义字段，确保即使第一个试次某些字段为空，表头也能正确生成
templateTrial = struct(...
    'block', [], ...
    'trialInBlock', [], ...
    'trialOverall', [], ...
    'gridType', '', ...
    'setSize', [], ...
    'memoryItemPositions_str', '', ... % 转换为字符串
    'memoryItemShapes_str', '', ...    % 转换为字符串
    'memoryItemColorsRGB_str', '', ... % 转换为字符串
    'probeItemIndex', [], ...
    'probeItemOriginalColorRGB_str', '', ... % 转换为字符串
    'probeItemPresentedColorRGB_str', '', ... % 转换为字符串
    'isChangeTrial', [], ...
    'expectedResponseKey_char', '', ... % 转换为字符
    'participantResponseKey_char', '', ... % 转换为字符
    'rt', [], ...
    'accuracy', [] ...
    );

exportData = repmat(templateTrial, numTrials, 1); % 预分配

for i = 1:numTrials
    currentTrial = trialsData(i);
    exportData(i).block = currentTrial.block;
    exportData(i).trialInBlock = currentTrial.trialInBlock;
    exportData(i).trialOverall = currentTrial.trialOverall;
    exportData(i).gridType = currentTrial.gridType; % 已经是字符串
    exportData(i).setSize = currentTrial.setSize;

    % 转换 memoryItemPositions (矩阵) 为字符串
    if ~isempty(currentTrial.memoryItemPositions)
        exportData(i).memoryItemPositions_str = mat2str(currentTrial.memoryItemPositions);
    else
        exportData(i).memoryItemPositions_str = '[]';
    end

    % 转换 memoryItemShapes (元胞数组) 为字符串
    if ~isempty(currentTrial.memoryItemShapes)
        exportData(i).memoryItemShapes_str = strjoin(currentTrial.memoryItemShapes, '; ');
    else
        exportData(i).memoryItemShapes_str = '{}';
    end

    % 转换 memoryItemColorsRGB (元胞数组，每个元素是RGB向量) 为字符串
    if ~isempty(currentTrial.memoryItemColorsRGB)
        colorsCellStr = cellfun(@mat2str, currentTrial.memoryItemColorsRGB, 'UniformOutput', false);
        exportData(i).memoryItemColorsRGB_str = strjoin(colorsCellStr, ' | ');
    else
        exportData(i).memoryItemColorsRGB_str = '{}';
    end

    exportData(i).probeItemIndex = currentTrial.probeItemIndex;

    % 转换 probeItemOriginalColorRGB (RGB向量) 为字符串
    if ~isempty(currentTrial.probeItemOriginalColorRGB)
        exportData(i).probeItemOriginalColorRGB_str = mat2str(currentTrial.probeItemOriginalColorRGB);
    else
        exportData(i).probeItemOriginalColorRGB_str = '[]';
    end

    % 转换 probeItemPresentedColorRGB (RGB向量) 为字符串
    if ~isempty(currentTrial.probeItemPresentedColorRGB)
        exportData(i).probeItemPresentedColorRGB_str = mat2str(currentTrial.probeItemPresentedColorRGB);
    else
        exportData(i).probeItemPresentedColorRGB_str = '[]';
    end

    exportData(i).isChangeTrial = currentTrial.isChangeTrial;

    % 转换按键码为字符 (如果 KbName 可用且有意义)
    % 假设 KbName('UnifyKeyNames') 已经在实验脚本中运行
    if ~isnan(currentTrial.expectedResponseKey)
        keyName = KbName(currentTrial.expectedResponseKey);
        if iscell(keyName), keyName = keyName{1}; end % KbName 可能返回 cell
        exportData(i).expectedResponseKey_char = keyName;
    else
        exportData(i).expectedResponseKey_char = 'NaN';
    end

    if ~isnan(currentTrial.participantResponseKey)
        keyName = KbName(currentTrial.participantResponseKey);
        if iscell(keyName), keyName = keyName{1}; end % KbName 可能返回 cell
        exportData(i).participantResponseKey_char = keyName;
    else
        exportData(i).participantResponseKey_char = 'NaN'; % 或 'NoResponse'
    end

    exportData(i).rt = currentTrial.rt;
    exportData(i).accuracy = currentTrial.accuracy;
end

% --- 将结构数组转换为表格 ---
try
    T = struct2table(exportData);
catch ME_table
    disp('将结构体转换为表格时出错:');
    disp(ME_table.message);
    return;
end

% --- 写入 Excel 文件 ---
try
    writetable(T, fullXlsxFileName, 'Sheet', 'TrialData');
    disp(['数据成功写入到: ' fullXlsxFileName]);
catch ME_write
    disp(['写入 Excel 文件时出错: ' fullXlsxFileName]);
    disp(ME_write.message);
    disp('可能的原因:');
    disp('- 文件可能已打开或被其他程序占用。');
    disp('- 没有写入权限。');
    disp('- Office 组件问题 (较少见)。');
end
end

% --- 如何运行 ---
% 1. 将此代码保存为 .m 文件 (例如, convertMyData.m) 到 MATLAB 的路径中。
% 2. 在 MATLAB 命令窗口中输入: convertMatToXlsx
% 3. 按照弹出的对话框选择输入的 .mat 文件和输出的 .xlsx 文件位置。