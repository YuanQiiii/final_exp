% 视觉工作记忆实验数据分析
% 用于分析不同网格类型和记忆负荷对视觉工作记忆的影响

function analyze_vwm_data()
% --- 数据加载和初始化 ---
[filename, pathname] = uigetfile('*.mat', '选择包含results结构体的数据文件');
if isequal(filename, 0)
    disp('用户取消了操作');
    return;
end

% 加载数据
fullpath = fullfile(pathname, filename);
load(fullpath);

% 检查数据结构
if ~exist('results', 'var')
    error('数据文件中不存在results变量');
end

% 提取实验设计参数
gridTypes = {'NoGrid', 'Grid6x6', 'Grid3x3', 'Grid2x2', 'Grid1x1'};
setSizes = [3, 4]; % 修正为实际实验中使用的记忆负荷

% --- 数据预处理 ---
% 提取有效数据
data = extract_data(results, gridTypes, setSizes);

% --- 描述性统计 ---
desc_stats = compute_descriptive_stats(data, gridTypes, setSizes);
display_descriptive_stats(desc_stats, gridTypes, setSizes);

% --- 方差分析 ---
[acc_anova, rt_anova] = run_anova_analysis(data);

% --- 可视化 ---
create_visualizations(desc_stats, gridTypes, setSizes);

% 不再包含信号检测理论分析
end

function data = extract_data(results, gridTypes, setSizes)
% 提取需要分析的数据
trials = results.trials;

% 初始化数据结构
data = struct();
data.accuracy = [];
data.rt = [];
data.gridType = {};
data.setSize = [];

% 遍历所有试次
for i = 1:length(trials)
    % 检查是否有效数据
    if ~isnan(trials(i).accuracy) && ~isnan(trials(i).rt)
        % 添加到数据集
        data.accuracy(end+1) = trials(i).accuracy;
        data.rt(end+1) = trials(i).rt;
        data.gridType{end+1} = trials(i).gridType;
        data.setSize(end+1) = trials(i).setSize;
    end
end

% 转换为分类变量
data.gridTypeIdx = categorical(data.gridType, gridTypes);
data.setSizeIdx = categorical(data.setSize);
end

function stats = compute_descriptive_stats(data, gridTypes, setSizes)
% 计算描述性统计量
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

        if ~isempty(acc_data)
            stats.acc_mean(g, s) = mean(acc_data);
            stats.acc_std(g, s) = std(acc_data);
            stats.acc_se(g, s) = stats.acc_std(g, s) / sqrt(stats.count(g, s));

            stats.rt_mean(g, s) = mean(rt_data);
            stats.rt_std(g, s) = std(rt_data);
            stats.rt_se(g, s) = stats.rt_std(g, s) / sqrt(stats.count(g, s));
        end
    end
end
end

function display_descriptive_stats(stats, gridTypes, setSizes)
% 显示描述性统计结果
fprintf('\n======== 描述性统计 ========\n\n');

% 准确率结果
fprintf('准确率 (均值 ± 标准误):\n');
fprintf('%-10s | %-15s | %-15s | %-10s\n', '网格类型', ['记忆负荷 = ' num2str(setSizes(1))], ['记忆负荷 = ' num2str(setSizes(2))], '样本量');
fprintf('%-10s | %-15s | %-15s | %-10s\n', '----------', '---------------', '---------------', '----------');

for g = 1:length(gridTypes)
    fprintf('%-10s | %.3f ± %.3f | %.3f ± %.3f | %d / %d\n', ...
        gridTypes{g}, ...
        stats.acc_mean(g, 1), stats.acc_se(g, 1), ...
        stats.acc_mean(g, 2), stats.acc_se(g, 2), ...
        stats.count(g, 1), stats.count(g, 2));
end

% 反应时间结果
fprintf('\n反应时间 (秒) (均值 ± 标准误):\n');
fprintf('%-10s | %-15s | %-15s | %-10s\n', '网格类型', ['记忆负荷 = ' num2str(setSizes(1))], ['记忆负荷 = ' num2str(setSizes(2))], '样本量');
fprintf('%-10s | %-15s | %-15s | %-10s\n', '----------', '---------------', '---------------', '----------');

for g = 1:length(gridTypes)
    fprintf('%-10s | %.3f ± %.3f | %.3f ± %.3f | %d / %d\n', ...
        gridTypes{g}, ...
        stats.rt_mean(g, 1), stats.rt_se(g, 1), ...
        stats.rt_mean(g, 2), stats.rt_se(g, 2), ...
        stats.count(g, 1), stats.count(g, 2));
end
end

function [acc_anova, rt_anova] = run_anova_analysis(data)
% 执行双因素方差分析
fprintf('\n======== 方差分析 ========\n\n');

% 准确率方差分析
fprintf('准确率方差分析:\n');
[p_acc, tbl_acc, stats_acc] = anovan(data.accuracy, {data.gridTypeIdx, data.setSizeIdx}, ...
    'varnames', {'网格类型', '记忆负荷'}, 'model', 'full');

% 反应时间方差分析
fprintf('\n反应时间方差分析:\n');
[p_rt, tbl_rt, stats_rt] = anovan(data.rt, {data.gridTypeIdx, data.setSizeIdx}, ...
    'varnames', {'网格类型', '记忆负荷'}, 'model', 'full');

% 如果主效应显著，进行多重比较
alpha = 0.05;

if p_acc(1) < alpha
    fprintf('\n网格类型对准确率的影响显著，进行多重比较:\n');
    figure('Name', '网格类型对准确率的多重比较');
    multcompare(stats_acc, 'Dimension', 1);
end

if p_acc(2) < alpha
    fprintf('\n记忆负荷对准确率的影响显著，进行多重比较:\n');
    figure('Name', '记忆负荷对准确率的多重比较');
    multcompare(stats_acc, 'Dimension', 2);
end

if p_rt(1) < alpha
    fprintf('\n网格类型对反应时间的影响显著，进行多重比较:\n');
    figure('Name', '网格类型对反应时间的多重比较');
    multcompare(stats_rt, 'Dimension', 1);
end

if p_rt(2) < alpha
    fprintf('\n记忆负荷对反应时间的影响显著，进行多重比较:\n');
    figure('Name', '记忆负荷对反应时间的多重比较');
    multcompare(stats_rt, 'Dimension', 2);
end

% 返回ANOVA结果
acc_anova = struct('p', p_acc, 'table', tbl_acc, 'stats', stats_acc);
rt_anova = struct('p', p_rt, 'table', tbl_rt, 'stats', stats_rt);
end

function create_visualizations(stats, gridTypes, setSizes)
% 创建可视化图表
figure('Name', '视觉工作记忆实验结果', 'Position', [100, 100, 1000, 800]);

% 设置颜色和条形图参数
colors = {[0.3 0.6 0.9], [0.9 0.3 0.3]};
x = 1:length(gridTypes);
width = 0.35;

% 1. 准确率条形图
subplot(2, 2, 1);
hold on;

% 绘制条形图和误差棒
h1 = bar(x - width/2, stats.acc_mean(:, 1), width, 'FaceColor', colors{1});
h2 = bar(x + width/2, stats.acc_mean(:, 2), width, 'FaceColor', colors{2});
errorbar(x - width/2, stats.acc_mean(:, 1), stats.acc_se(:, 1), '.k');
errorbar(x + width/2, stats.acc_mean(:, 2), stats.acc_se(:, 2), '.k');

% 设置图表属性
title('不同网格类型和记忆负荷对准确率的影响');
xlabel('网格类型');
ylabel('准确率');
set(gca, 'XTick', 1:length(gridTypes), 'XTickLabel', gridTypes, 'XTickLabelRotation', 45);
legend([h1, h2], {['记忆负荷 = ' num2str(setSizes(1))], ['记忆负荷 = ' num2str(setSizes(2))]}, 'Location', 'southeast');
ylim([0.5 1]);
grid on;

% 2. 反应时间条形图
subplot(2, 2, 2);
hold on;

% 绘制条形图和误差棒
h3 = bar(x - width/2, stats.rt_mean(:, 1), width, 'FaceColor', colors{1});
h4 = bar(x + width/2, stats.rt_mean(:, 2), width, 'FaceColor', colors{2});
errorbar(x - width/2, stats.rt_mean(:, 1), stats.rt_se(:, 1), '.k');
errorbar(x + width/2, stats.rt_mean(:, 2), stats.rt_se(:, 2), '.k');

% 设置图表属性
title('不同网格类型和记忆负荷对反应时间的影响');
xlabel('网格类型');
ylabel('反应时间 (秒)');
set(gca, 'XTick', 1:length(gridTypes), 'XTickLabel', gridTypes, 'XTickLabelRotation', 45);
legend([h3, h4], {['记忆负荷 = ' num2str(setSizes(1))], ['记忆负荷 = ' num2str(setSizes(2))]}, 'Location', 'northeast');
grid on;

% 3. 准确率交互作用图
subplot(2, 2, 3);
hold on;

% 绘制线图
plot(x, stats.acc_mean(:, 1), '-o', 'LineWidth', 2, 'Color', colors{1}, 'MarkerFaceColor', colors{1});
plot(x, stats.acc_mean(:, 2), '-s', 'LineWidth', 2, 'Color', colors{2}, 'MarkerFaceColor', colors{2});

% 添加误差棒
for i = 1:length(gridTypes)
    errorbar(i, stats.acc_mean(i, 1), stats.acc_se(i, 1), 'Color', colors{1});
    errorbar(i, stats.acc_mean(i, 2), stats.acc_se(i, 2), 'Color', colors{2});
end

% 设置图表属性
title('网格类型和记忆负荷对准确率的交互作用');
xlabel('网格类型');
ylabel('准确率');
set(gca, 'XTick', 1:length(gridTypes), 'XTickLabel', gridTypes, 'XTickLabelRotation', 45);
legend({['记忆负荷 = ' num2str(setSizes(1))], ['记忆负荷 = ' num2str(setSizes(2))]}, 'Location', 'southeast');
ylim([0.5 1]);
grid on;

% 4. 反应时间交互作用图
subplot(2, 2, 4);
hold on;

% 绘制线图
plot(x, stats.rt_mean(:, 1), '-o', 'LineWidth', 2, 'Color', colors{1}, 'MarkerFaceColor', colors{1});
plot(x, stats.rt_mean(:, 2), '-s', 'LineWidth', 2, 'Color', colors{2}, 'MarkerFaceColor', colors{2});

% 添加误差棒
for i = 1:length(gridTypes)
    errorbar(i, stats.rt_mean(i, 1), stats.rt_se(i, 1), 'Color', colors{1});
    errorbar(i, stats.rt_mean(i, 2), stats.rt_se(i, 2), 'Color', colors{2});
end

% 设置图表属性
title('网格类型和记忆负荷对反应时间的交互作用');
xlabel('网格类型');
ylabel('反应时间 (秒)');
set(gca, 'XTick', 1:length(gridTypes), 'XTickLabel', gridTypes, 'XTickLabelRotation', 45);
legend({['记忆负荷 = ' num2str(setSizes(1))], ['记忆负荷 = ' num2str(setSizes(2))]}, 'Location', 'northeast');
grid on;

% 调整图表布局并保存
sgtitle('视觉工作记忆实验结果分析');
set(gcf, 'Color', 'w');
saveas(gcf, 'VWM_Results_Summary.png');
fprintf('\n图表已保存为: VWM_Results_Summary.png\n');
end