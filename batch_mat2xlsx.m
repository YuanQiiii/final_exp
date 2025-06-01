function batch_mat2xlsx()
% 批量将文件夹中所有 .mat 文件转换为 .xlsx

% 1. 选择包含 .mat 文件的文件夹
dirname = uigetdir(pwd, '请选择包含 .mat 数据文件的文件夹');
if isequal(dirname, 0)
    disp('用户取消了操作。');
    return;
end

% 2. 列出所有 .mat 文件
matFiles = dir(fullfile(dirname, '*.mat'));
if isempty(matFiles)
    disp('在选定文件夹中未找到 .mat 文件。');
    return;
end

% 3. 逐个转换
for k = 1:numel(matFiles)
    matName = matFiles(k).name;
    fullMat = fullfile(dirname, matName);
    try
        data = load(fullMat);
    catch ME
        warning('加载文件出错: %s\n%s', matName, ME.message);
        continue;
    end

    % 检查结果结构
    if ~isfield(data, 'results') || ~isfield(data.results, 'trials')
        warning('文件 %s 中缺少 results.trials，跳过。', matName);
        continue;
    end

    % 调用已有的单文件转换逻辑（可将下段代码抽成函数）
    trials = data.results.trials;
    numT = numel(trials);
    if numT == 0
        warning('文件 %s 中没有试次数据，跳过。', matName);
        continue;
    end

    % 预分配结构体模板（与 mat2xlsx.m 相同）
    template = struct(...
        'block',[], 'trialInBlock',[], 'trialOverall',[], ...
        'gridType','', 'setSize',[], ...
        'memoryItemPositions_str','', ...
        'memoryItemShapes_str','', ...
        'memoryItemColorsRGB_str','', ...
        'probeItemIndex',[], ...
        'probeItemOriginalColorRGB_str','', ...
        'probeItemPresentedColorRGB_str','', ...
        'isChangeTrial',[], ...
        'expectedResponseKey_char','', ...
        'participantResponseKey_char','', ...
        'rt',[], 'accuracy',[] ...
        );
    exportData = repmat(template, numT, 1);

    for i = 1:numT
        t = trials(i);
        exportData(i).block   = t.block;
        exportData(i).trialInBlock = t.trialInBlock;
        exportData(i).trialOverall = t.trialOverall;
        exportData(i).gridType= t.gridType;
        exportData(i).setSize = t.setSize;

        % 转换并填充其它字段（同 mat2xlsx.m）
        if ~isempty(t.memoryItemPositions)
            exportData(i).memoryItemPositions_str = mat2str(t.memoryItemPositions);
        else
            exportData(i).memoryItemPositions_str = '[]';
        end
        if ~isempty(t.memoryItemShapes)
            exportData(i).memoryItemShapes_str = strjoin(t.memoryItemShapes, '; ');
        else
            exportData(i).memoryItemShapes_str = '{}';
        end
        if ~isempty(t.memoryItemColorsRGB)
            strs = cellfun(@mat2str,t.memoryItemColorsRGB,'UniformOutput',false);
            exportData(i).memoryItemColorsRGB_str = strjoin(strs,' | ');
        else
            exportData(i).memoryItemColorsRGB_str = '{}';
        end

        exportData(i).probeItemIndex = t.probeItemIndex;
        if ~isempty(t.probeItemOriginalColorRGB)
            exportData(i).probeItemOriginalColorRGB_str = mat2str(t.probeItemOriginalColorRGB);
        else
            exportData(i).probeItemOriginalColorRGB_str = '[]';
        end
        if ~isempty(t.probeItemPresentedColorRGB)
            exportData(i).probeItemPresentedColorRGB_str = mat2str(t.probeItemPresentedColorRGB);
        else
            exportData(i).probeItemPresentedColorRGB_str = '[]';
        end

        exportData(i).isChangeTrial = t.isChangeTrial;
        % 键码转字符
        if ~isnan(t.expectedResponseKey)
            nm = KbName(t.expectedResponseKey);
            if iscell(nm), nm = nm{1}; end
            exportData(i).expectedResponseKey_char = nm;
        else
            exportData(i).expectedResponseKey_char = 'NaN';
        end
        if ~isnan(t.participantResponseKey)
            nm = KbName(t.participantResponseKey);
            if iscell(nm), nm = nm{1}; end
            exportData(i).participantResponseKey_char = nm;
        else
            exportData(i).participantResponseKey_char = 'NaN';
        end

        exportData(i).rt = t.rt;
        exportData(i).accuracy = t.accuracy;
    end

    % 转表与写文件
    try
        T = struct2table(exportData);
        xlsxName = [matName(1:end-4) '.xlsx'];
        writetable(T, fullfile(dirname, xlsxName), 'Sheet','TrialData');
        fprintf('已转换并写入: %s\n', xlsxName);
    catch MEo
        warning('转换或写入失败: %s\n%s', matName, MEo.message);
    end
end
end