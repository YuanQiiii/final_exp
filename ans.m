% 视觉工作记忆实验数据分析 (多被试版本)
% 用于分析不同网格类型和记忆负荷对视觉工作记忆的影响，聚合多个被试数据

function analyze_vwm_data_multi_subject()
% --- 文件夹选择 ---
dirname = uigetdir('', '选择包含多个被试.mat数据文件的文件夹');
if isequal(dirname, 0)
    disp('用户取消了操作');
    return;
end

% 获取文件夹中所有.mat文件
mat_files = dir(fullfile(dirname, '*.mat'));
if isempty(mat_files)
    disp('在选定文件夹中未找到.mat文件');
    return;
end

num_subjects = length(mat_files);
fprintf('找到 %d 个被试的数据文件。\n', num_subjects);

% --- 初始化实验设计参数 ---
gridTypes = {'NoGrid', 'Grid6x6', 'Grid3x3', 'Grid2x2', 'Grid1x1'};
setSizes = [3, 4]; % 修正为实际实验中使用的记忆负荷

% --- 数据加载和聚合 ---
% 初始化聚合数据结构
all_trials_data = struct('accuracy', [], 'rt', [], 'gridType', {{}}, 'setSize', [], 'subject', {{}});

for s_idx = 1:num_subjects
    filename = mat_files(s_idx).name;
    fullpath = fullfile(dirname, filename);
    fprintf('正在加载被试 %d/%d: %s\n', s_idx, num_subjects, filename);

    loaded_data = load(fullpath); % 加载到临时结构体

    if ~isfield(loaded_data, 'results')
        warning('数据文件 %s 中不存在results变量，跳过此文件。', filename);
        continue;
    end
    results = loaded_data.results; % 获取results结构体

    % 提取当前被试数据
    trials = results.trials;
    subject_id_str = sprintf('S%02d', s_idx); % 创建被试ID，例如 S01, S02

    for i = 1:length(trials)
        % 检查是否有效数据
        if isfield(trials(i), 'accuracy') && isfield(trials(i), 'rt') && ...
                ~isnan(trials(i).accuracy) && ~isnan(trials(i).rt)
            % 添加到聚合数据集
            all_trials_data.accuracy(end+1) = trials(i).accuracy;
            all_trials_data.rt(end+1) = trials(i).rt;
            all_trials_data.gridType{end+1} = trials(i).gridType;
            all_trials_data.setSize(end+1) = trials(i).setSize;
            all_trials_data.subject{end+1} = subject_id_str;
        end
    end
end

if isempty(all_trials_data.accuracy)
    disp('未能从任何文件中提取有效数据。');
    return;
end

% 转换为分类变量
all_trials_data.gridTypeIdx = categorical(all_trials_data.gridType, gridTypes);
all_trials_data.setSizeIdx = categorical(all_trials_data.setSize);
all_trials_data.subjectIdx = categorical(all_trials_data.subject);

% --- 诊断代码 ---
fprintf('\n--- 诊断信息 ---\n');
fprintf('原始 gridType 值 (unique): \n');
disp(unique(all_trials_data.gridType)');
fprintf('gridTypeIdx 摘要:\n');
summary(all_trials_data.gridTypeIdx);
fprintf('gridTypeIdx 水平:\n');
disp(categories(all_trials_data.gridTypeIdx));

fprintf('原始 setSize 值 (unique): \n');
disp(unique(all_trials_data.setSize)');
fprintf('setSizeIdx 摘要:\n');
summary(all_trials_data.setSizeIdx);
fprintf('setSizeIdx 水平:\n');
disp(categories(all_trials_data.setSizeIdx));

fprintf('原始 subject 值 (unique): \n');
disp(unique(all_trials_data.subject)');
fprintf('subjectIdx 摘要:\n');
summary(all_trials_data.subjectIdx);
fprintf('subjectIdx 水平:\n');
disp(categories(all_trials_data.subjectIdx));
fprintf('--- 结束诊断信息 ---\n');

% --- 描述性统计 ---
desc_stats = compute_descriptive_stats(all_trials_data, gridTypes, setSizes);
display_descriptive_stats(desc_stats, gridTypes, setSizes);

% --- 方差分析 (多被试) ---
[acc_anova, rt_anova] = run_anova_analysis_multi_subject(all_trials_data);

% --- 可视化 ---
create_visualizations(desc_stats, gridTypes, setSizes);

% 不再包含信号检测理论分析
end

function stats = compute_descriptive_stats(data, gridTypes, setSizes)
% 计算描述性统计量 (此函数与原版基本一致)
stats = struct();

% 初始化结果矩阵
stats.acc_mean = zeros(length(gridTypes), length(setSizes));
stats.acc_std = zeros(length(gridTypes), length(setSizes));
stats.acc_se = zeros(length(gridTypes), length(setSizes));
stats.rt_mean = zeros(length(gridTypes), length(setSizes));
stats.rt_std = zeros(length(gridTypes), length(setSizes));
stats.rt_se = zeros(length(gridTypes), length(setSizes));
stats.count = zeros(length(gridTypes), length(setSizes));

% 计算每个条件组合的统计量
for g = 1:length(gridTypes)
    for s = 1:length(setSizes)
        % 找出符合当前条件的试次
        idx = strcmp(data.gridType, gridTypes{g}) & data.setSize == setSizes(s);

        % 提取准确率和反应时间
        acc_data = data.accuracy(idx);
        rt_data = data.rt(idx);

        % 计算统计量
        stats.count(g, s) = sum(idx);

        if ~isempty(acc_data) && stats.count(g,s) > 0
            stats.acc_mean(g, s) = mean(acc_data);
            stats.acc_std(g, s) = std(acc_data);
            if stats.count(g, s) > 1
                stats.acc_se(g, s) = stats.acc_std(g, s) / sqrt(stats.count(g, s));
            else
                stats.acc_se(g, s) = NaN; % SE 未定义如果只有一个样本
            end

            stats.rt_mean(g, s) = mean(rt_data);
            stats.rt_std(g, s) = std(rt_data);
            if stats.count(g, s) > 1
                stats.rt_se(g, s) = stats.rt_std(g, s) / sqrt(stats.count(g, s));
            else
                stats.rt_se(g,s) = NaN;
            end
        else
            stats.acc_mean(g, s) = NaN;
            stats.acc_std(g, s) = NaN;
            stats.acc_se(g, s) = NaN;
            stats.rt_mean(g, s) = NaN;
            stats.rt_std(g, s) = NaN;
            stats.rt_se(g, s) = NaN;
        end
    end
end
end

function display_descriptive_stats(stats, gridTypes, setSizes)
% 显示描述性统计结果 (此函数与原版基本一致)
fprintf('\n======== 描述性统计 (基于所有被试的所有试次) ========\n\n');

% 准确率结果
fprintf('准确率 (均值 ± 标准误):\n');
fprintf('%-10s | %-15s | %-15s | %-15s\n', '网格类型', ['记忆负荷 = ' num2str(setSizes(1))], ['记忆负荷 = ' num2str(setSizes(2))], '总试次数');
fprintf('%-10s | %-15s | %-15s | %-15s\n', '----------', '---------------', '---------------', '---------------');

for g = 1:length(gridTypes)
    fprintf('%-10s | %.3f ± %.3f | %.3f ± %.3f | %d / %d\n', ...
        gridTypes{g}, ...
        stats.acc_mean(g, 1), stats.acc_se(g, 1), ...
        stats.acc_mean(g, 2), stats.acc_se(g, 2), ...
        stats.count(g, 1), stats.count(g, 2));
end

% 反应时间结果
fprintf('\n反应时间 (秒) (均值 ± 标准误):\n');
fprintf('%-10s | %-15s | %-15s | %-15s\n', '网格类型', ['记忆负荷 = ' num2str(setSizes(1))], ['记忆负荷 = ' num2str(setSizes(2))], '总试次数');
fprintf('%-10s | %-15s | %-15s | %-15s\n', '----------', '---------------', '---------------', '---------------');

for g = 1:length(gridTypes)
    fprintf('%-10s | %.3f ± %.3f | %.3f ± %.3f | %d / %d\n', ...
        gridTypes{g}, ...
        stats.rt_mean(g, 1), stats.rt_se(g, 1), ...
        stats.rt_mean(g, 2), stats.rt_se(g, 2), ...
        stats.count(g, 1), stats.count(g, 2));
end
end

function [acc_anova, rt_anova] = run_anova_analysis_multi_subject(data)
% 执行双因素重复测量方差分析
fprintf('\n======== 双因素重复测量方差分析 ========\n\n');

% 确保 subjectIdx 存在且为分类变量
if ~isfield(data, 'subjectIdx') || ~iscategorical(data.subjectIdx)
    error('data.subjectIdx 未找到或不是分类变量。请检查数据聚合过程。');
end

% 准备用于重复测量分析的数据
subjects = categories(data.subjectIdx);
gridTypes = categories(data.gridTypeIdx);
setSizes = categories(data.setSizeIdx);

% 为每个被试计算每个条件组合的平均准确率和反应时
% 创建整理好的数据表格
acc_data = zeros(length(subjects), length(gridTypes), length(setSizes));
rt_data = zeros(length(subjects), length(gridTypes), length(setSizes));

% 计算每个被试在每个条件组合下的平均表现
for i = 1:length(subjects)
    for g = 1:length(gridTypes)
        for s = 1:length(setSizes)
            % 获取当前被试在当前条件下的所有试次
            idx = data.subjectIdx == subjects{i} & ...
                data.gridTypeIdx == gridTypes{g} & ...
                data.setSizeIdx == setSizes{s};

            if any(idx)
                acc_data(i, g, s) = mean(data.accuracy(idx), 'omitnan');
                rt_data(i, g, s) = mean(data.rt(idx), 'omitnan');
            else
                acc_data(i, g, s) = NaN;
                rt_data(i, g, s) = NaN;
            end
        end
    end
end

% --- 准确率方差分析 ---
fprintf('准确率 - 重复测量方差分析结果:\n');
try
    % 使用 ranova2 (自定义函数) 执行双因素重复测量方差分析
    [p_acc, tbl_acc, stats_acc] = ranova2(acc_data, {'网格类型', '记忆负荷'});

    % 显示结果
    disp(tbl_acc);

    % 进行多重比较（如果主效应显著）
    alpha = 0.05;

    % 网格类型主效应多重比较
    if p_acc(1) < alpha
        fprintf('\n网格类型对准确率的主效应显著 (p=%.4f)，进行多重比较:\n', p_acc(1));
        gridMeans = squeeze(mean(acc_data, 3)); % 计算每个网格类型的平均值（跨记忆负荷）
        [~, ~, stats] = anova1(gridMeans, [], 'off');
        figure('Name', '准确率 - 网格类型多重比较');
        c = multcompare(stats, 'Display', 'on');
        title('多重比较: 网格类型对准确率的影响');
        xlabel('平均准确率差异');
        set(gca, 'YTickLabel', flipud(gridTypes));
    end

    % 记忆负荷主效应多重比较
    if p_acc(2) < alpha
        fprintf('\n记忆负荷对准确率的主效应显著 (p=%.4f)，进行多重比较:\n', p_acc(2));
        sizeMeans = squeeze(mean(acc_data, 2)); % 计算每个记忆负荷的平均值（跨网格类型）
        [~, ~, stats] = anova1(sizeMeans, [], 'off');
        figure('Name', '准确率 - 记忆负荷多重比较');
        c = multcompare(stats, 'Display', 'on');
        title('多重比较: 记忆负荷对准确率的影响');
        xlabel('平均准确率差异');
        set(gca, 'YTickLabel', flipud(setSizes));
    end

    % 交互作用的简单主效应分析
    if p_acc(3) < alpha
        fprintf('\n网格类型和记忆负荷对准确率存在显著的交互作用 (p=%.4f)，进行简单主效应分析\n', p_acc(3));

        % 在每个记忆负荷水平上分析网格类型的简单主效应
        for s = 1:length(setSizes)
            fprintf('\n在记忆负荷 = %s 条件下，网格类型的简单主效应:\n', setSizes{s});
            gridMeansAtSetSize = squeeze(acc_data(:,:,s));
            [p, tbl] = anova1(gridMeansAtSetSize, [], 'off');
            fprintf('F(%.0f,%.0f) = %.2f, p = %.4f\n', ...
                tbl{2,3}, tbl{3,3}, tbl{2,5}, p);

            if p < alpha
                [~, ~, stats] = anova1(gridMeansAtSetSize, [], 'off');
                figure('Name', sprintf('准确率 - 记忆负荷%s下的网格类型多重比较', setSizes{s}));
                multcompare(stats, 'Display', 'on');
                title(sprintf('记忆负荷 = %s 时，网格类型对准确率的影响', setSizes{s}));
                xlabel('平均准确率差异');
                set(gca, 'YTickLabel', flipud(gridTypes));
            end
        end

        % 在每个网格类型水平上分析记忆负荷的简单主效应
        for g = 1:length(gridTypes)
            fprintf('\n在网格类型 = %s 条件下，记忆负荷的简单主效应:\n', gridTypes{g});
            sizeMeansAtGrid = squeeze(acc_data(:,g,:));
            [p, tbl] = anova1(sizeMeansAtGrid, [], 'off');
            fprintf('F(%.0f,%.0f) = %.2f, p = %.4f\n', ...
                tbl{2,3}, tbl{3,3}, tbl{2,5}, p);

            if p < alpha
                [~, ~, stats] = anova1(sizeMeansAtGrid, [], 'off');
                figure('Name', sprintf('准确率 - 网格类型%s下的记忆负荷多重比较', gridTypes{g}));
                multcompare(stats, 'Display', 'on');
                title(sprintf('网格类型 = %s 时，记忆负荷对准确率的影响', gridTypes{g}));
                xlabel('平均准确率差异');
                set(gca, 'YTickLabel', flipud(setSizes));
            end
        end
    end

    acc_anova = struct('p', p_acc, 'table', tbl_acc, 'stats', stats_acc);
catch ME
    warning('准确率重复测量ANOVA失败: %s', ME.message);
    disp(getReport(ME));
    acc_anova = struct('error', ME.message);

    % 备用方案：使用anovan进行混合效应分析
    fprintf('\n尝试备用方案 - 使用anovan进行混合效应分析:\n');
    [p_acc, tbl_acc, stats_acc] = anovan(data.accuracy, ...
        {data.gridTypeIdx, data.setSizeIdx, data.subjectIdx}, ...
        'varnames', {'网格类型', '记忆负荷', '被试'}, ...
        'model', 'full', ...
        'random', 3, ...
        'display', 'on');

    acc_anova.backup = struct('p', p_acc, 'table', tbl_acc, 'stats', stats_acc);
end

% --- 反应时间方差分析 ---
fprintf('\n反应时间 - 重复测量方差分析结果:\n');
try
    % 使用 ranova2 (自定义函数) 执行双因素重复测量方差分析
    [p_rt, tbl_rt, stats_rt] = ranova2(rt_data, {'网格类型', '记忆负荷'});

    % 显示结果
    disp(tbl_rt);

    % 进行多重比较（如果主效应显著）
    alpha = 0.05;

    % 网格类型主效应多重比较
    if p_rt(1) < alpha
        fprintf('\n网格类型对反应时间的主效应显著 (p=%.4f)，进行多重比较:\n', p_rt(1));
        gridMeans = squeeze(mean(rt_data, 3)); % 计算每个网格类型的平均值（跨记忆负荷）
        [~, ~, stats] = anova1(gridMeans, [], 'off');
        figure('Name', '反应时间 - 网格类型多重比较');
        c = multcompare(stats, 'Display', 'on');
        title('多重比较: 网格类型对反应时间的影响');
        xlabel('平均反应时间差异（秒）');
        set(gca, 'YTickLabel', flipud(gridTypes));
    end

    % 记忆负荷主效应多重比较
    if p_rt(2) < alpha
        fprintf('\n记忆负荷对反应时间的主效应显著 (p=%.4f)，进行多重比较:\n', p_rt(2));
        sizeMeans = squeeze(mean(rt_data, 2)); % 计算每个记忆负荷的平均值（跨网格类型）
        [~, ~, stats] = anova1(sizeMeans, [], 'off');
        figure('Name', '反应时间 - 记忆负荷多重比较');
        c = multcompare(stats, 'Display', 'on');
        title('多重比较: 记忆负荷对反应时间的影响');
        xlabel('平均反应时间差异（秒）');
        set(gca, 'YTickLabel', flipud(setSizes));
    end

    % 交互作用的简单主效应分析
    if p_rt(3) < alpha
        fprintf('\n网格类型和记忆负荷对反应时间存在显著的交互作用 (p=%.4f)，进行简单主效应分析\n', p_rt(3));

        % 在每个记忆负荷水平上分析网格类型的简单主效应
        for s = 1:length(setSizes)
            fprintf('\n在记忆负荷 = %s 条件下，网格类型的简单主效应:\n', setSizes{s});
            gridMeansAtSetSize = squeeze(rt_data(:,:,s));
            [p, tbl] = anova1(gridMeansAtSetSize, [], 'off');
            fprintf('F(%.0f,%.0f) = %.2f, p = %.4f\n', ...
                tbl{2,3}, tbl{3,3}, tbl{2,5}, p);

            if p < alpha
                [~, ~, stats] = anova1(gridMeansAtSetSize, [], 'off');
                figure('Name', sprintf('反应时间 - 记忆负荷%s下的网格类型多重比较', setSizes{s}));
                multcompare(stats, 'Display', 'on');
                title(sprintf('记忆负荷 = %s 时，网格类型对反应时间的影响', setSizes{s}));
                xlabel('平均反应时间差异（秒）');
                set(gca, 'YTickLabel', flipud(gridTypes));
            end
        end

        % 在每个网格类型水平上分析记忆负荷的简单主效应
        for g = 1:length(gridTypes)
            fprintf('\n在网格类型 = %s 条件下，记忆负荷的简单主效应:\n', gridTypes{g});
            sizeMeansAtGrid = squeeze(rt_data(:,g,:));
            [p, tbl] = anova1(sizeMeansAtGrid, [], 'off');
            fprintf('F(%.0f,%.0f) = %.2f, p = %.4f\n', ...
                tbl{2,3}, tbl{3,3}, tbl{2,5}, p);

            if p < alpha
                [~, ~, stats] = anova1(sizeMeansAtGrid, [], 'off');
                figure('Name', sprintf('反应时间 - 网格类型%s下的记忆负荷多重比较', gridTypes{g}));
                multcompare(stats, 'Display', 'on');
                title(sprintf('网格类型 = %s 时，记忆负荷对反应时间的影响', gridTypes{g}));
                xlabel('平均反应时间差异（秒）');
                set(gca, 'YTickLabel', flipud(setSizes));
            end
        end
    end

    rt_anova = struct('p', p_rt, 'table', tbl_rt, 'stats', stats_rt);
catch ME
    warning('反应时间重复测量ANOVA失败: %s', ME.message);
    disp(getReport(ME));
    rt_anova = struct('error', ME.message);

    % 备用方案：使用anovan进行混合效应分析
    fprintf('\n尝试备用方案 - 使用anovan进行混合效应分析:\n');
    [p_rt, tbl_rt, stats_rt] = anovan(data.rt, ...
        {data.gridTypeIdx, data.setSizeIdx, data.subjectIdx}, ...
        'varnames', {'网格类型', '记忆负荷', '被试'}, ...
        'model', 'full', ...
        'random', 3, ...
        'display', 'on');

    rt_anova.backup = struct('p', p_rt, 'table', tbl_rt, 'stats', stats_rt);
end
end

function create_visualizations(stats, gridTypes, setSizes)
% 创建图表以可视化不同网格类型和记忆负荷的准确率和反应时间
fprintf('\n======== 创建可视化图表 ========\n\n');

% --- 准确率可视化 ---
figure('Name', '不同网格类型和记忆负荷下的准确率');

% 准备数据
accuracyData = stats.acc_mean;
errBars = stats.acc_se;
groupLabels = gridTypes;
numGroups = length(gridTypes);
numBars = length(setSizes);

% 创建分组柱状图
hb = bar(accuracyData, 'grouped');
hold on;

% 设置图表基本属性
title('不同网格类型和记忆负荷下的准确率');
xlabel('网格类型');
ylabel('准确率');
ylim([0.5 1]); % 通常准确率在0.5-1之间
set(gca, 'XTickLabel', groupLabels);

% 为不同记忆负荷创建图例
legendLabels = cell(1, numBars);
for i = 1:numBars
    legendLabels{i} = ['记忆负荷 = ' num2str(setSizes(i))];
end
legend(legendLabels, 'Location', 'southoutside', 'Orientation', 'horizontal');

% 添加误差条
% 获取柱状图的x坐标
x = zeros(numGroups, numBars);
for i = 1:numBars
    x(:,i) = hb(i).XEndPoints';
end

% 添加误差条
for i = 1:numBars
    errorbar(x(:,i), accuracyData(:,i), errBars(:,i), 'k', 'LineStyle', 'none');
end

% 添加网格线便于阅读
grid on;
hold off;

% --- 反应时间可视化 ---
figure('Name', '不同网格类型和记忆负荷下的反应时间');

% 准备数据
rtData = stats.rt_mean;
rtErrBars = stats.rt_se;

% 创建分组柱状图
hb_rt = bar(rtData, 'grouped');
hold on;

% 设置图表基本属性
title('不同网格类型和记忆负荷下的反应时间');
xlabel('网格类型');
ylabel('反应时间 (秒)');
set(gca, 'XTickLabel', groupLabels);

% 添加图例
legend(legendLabels, 'Location', 'southoutside', 'Orientation', 'horizontal');

% 添加误差条
% 获取柱状图的x坐标
x_rt = zeros(numGroups, numBars);
for i = 1:numBars
    x_rt(:,i) = hb_rt(i).XEndPoints';
end

% 添加误差条
for i = 1:numBars
    errorbar(x_rt(:,i), rtData(:,i), rtErrBars(:,i), 'k', 'LineStyle', 'none');
end

% 添加网格线便于阅读
grid on;
hold off;

% --- 网格类型和记忆负荷的交互作用可视化 ---
figure('Name', '网格类型和记忆负荷对准确率的交互作用');

% 准确率交互作用图
subplot(1, 2, 1);
x_interaction = 1:length(gridTypes);
plot(x_interaction, accuracyData(:,1), '-o', 'LineWidth', 2, 'DisplayName', ['记忆负荷 = ' num2str(setSizes(1))]);
hold on;
plot(x_interaction, accuracyData(:,2), '-s', 'LineWidth', 2, 'DisplayName', ['记忆负荷 = ' num2str(setSizes(2))]);
xlabel('网格类型');
ylabel('准确率');
title('网格类型和记忆负荷对准确率的交互作用');
set(gca, 'XTick', x_interaction);
set(gca, 'XTickLabel', gridTypes);
grid on;
legend('Location', 'best');
ylim([0.5 1]);
hold off;

% 反应时交互作用图
subplot(1, 2, 2);
plot(x_interaction, rtData(:,1), '-o', 'LineWidth', 2, 'DisplayName', ['记忆负荷 = ' num2str(setSizes(1))]);
hold on;
plot(x_interaction, rtData(:,2), '-s', 'LineWidth', 2, 'DisplayName', ['记忆负荷 = ' num2str(setSizes(2))]);
xlabel('网格类型');
ylabel('反应时间 (秒)');
title('网格类型和记忆负荷对反应时间的交互作用');
set(gca, 'XTick', x_interaction);
set(gca, 'XTickLabel', gridTypes);
grid on;
legend('Location', 'best');
hold off;

fprintf('图表已创建。\n');
end

% 修复ranova2函数中的错误
function [p, tbl, stats] = ranova2(data, factorNames)
% 执行双因素重复测量方差分析
% data: 3维数组 [被试数 x 因素1水平数 x 因素2水平数]
% factorNames: 因素名称的单元格数组，如 {'网格类型', '记忆负荷'}

[nSubjects, nLevels1, nLevels2] = size(data);

% 创建因素和交互项名称
if nargin < 2 || isempty(factorNames)
    factorNames = {'因素A', '因素B'};
end
factor1Name = factorNames{1};
factor2Name = factorNames{2};
interactionName = [factor1Name ':' factor2Name];

% 初始化ANOVA结果表
tbl = table();
tbl.Source = {factor1Name; factor2Name; interactionName; 'Error'; 'Total'};
tbl.SS = zeros(5, 1);
tbl.df = zeros(5, 1);
tbl.MS = zeros(5, 1);
tbl.F = zeros(5, 1);
tbl.pValue = zeros(5, 1);

% 计算总平方和
grandMean = mean(data(:), 'omitnan');
totalSS = sum((data(:) - grandMean).^2, 'omitnan');

% 计算因素1（网格类型）的平方和
factor1Means = squeeze(mean(mean(data, 3, 'omitnan'), 1, 'omitnan'));
factor1SS = nSubjects * nLevels2 * sum((factor1Means - grandMean).^2, 'omitnan');
factor1df = nLevels1 - 1;
factor1MS = factor1SS / factor1df;

% 计算因素2（记忆负荷）的平方和 - 修复此处错误
factor2Means = squeeze(mean(mean(data, 2, 'omitnan'), 1, 'omitnan'));
factor2SS = nSubjects * nLevels1 * sum((factor2Means - grandMean).^2, 'omitnan');
factor2df = nLevels2 - 1;
factor2MS = factor2SS / factor2df;

% 计算交互作用的平方和
cellMeans = zeros(nLevels1, nLevels2);
for i = 1:nLevels1
    for j = 1:nLevels2
        cellMeans(i, j) = mean(data(:, i, j), 'omitnan');
    end
end

interactionSS = 0;
for i = 1:nLevels1
    for j = 1:nLevels2
        expected = factor1Means(i) + factor2Means(j) - grandMean;
        observed = cellMeans(i, j);
        interactionSS = interactionSS + nSubjects * (observed - expected)^2;
    end
end
interactiondf = (nLevels1 - 1) * (nLevels2 - 1);
interactionMS = interactionSS / interactiondf;

% 计算误差平方和
errorSS = totalSS - factor1SS - factor2SS - interactionSS;
errordf = nSubjects * nLevels1 * nLevels2 - nLevels1 - nLevels2 + 1 - interactiondf;
errorMS = errorSS / errordf;

% 计算F统计量和p值
factor1F = factor1MS / errorMS;
factor2F = factor2MS / errorMS;
interactionF = interactionMS / errorMS;

factor1p = 1 - fcdf(factor1F, factor1df, errordf);
factor2p = 1 - fcdf(factor2F, factor2df, errordf);
interactionp = 1 - fcdf(interactionF, interactiondf, errordf);

% 填充结果表
tbl.SS = [factor1SS; factor2SS; interactionSS; errorSS; totalSS];
tbl.df = [factor1df; factor2df; interactiondf; errordf; nSubjects*nLevels1*nLevels2-1];
tbl.MS = [factor1MS; factor2MS; interactionMS; errorMS; NaN];
tbl.F = [factor1F; factor2F; interactionF; NaN; NaN];
tbl.pValue = [factor1p; factor2p; interactionp; NaN; NaN];

% 输出p值
p = [factor1p; factor2p; interactionp];

% 输出统计结果
stats = struct();
stats.factor1 = factor1Name;
stats.factor2 = factor2Name;
stats.interaction = interactionName;
stats.means = cellMeans;
stats.factor1Means = factor1Means;
stats.factor2Means = factor2Means;
end