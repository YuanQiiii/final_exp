# 加载必要的包
library(R.matlab)  # 用于读取MATLAB数据
library(tidyverse) # 数据处理和可视化
library(ez)        # ANOVA分析
library(lme4)      # 混合效应模型
library(emmeans)   # 事后比较
library(ggpubr)    # 组合图形
library(viridis)   # 配色方案

# 设置工作目录（请根据实际情况修改）
# setwd("C:/Users/exqin/Desktop/TODO/实心大实验/final_exp")

# 函数：读取一个被试的数据文件
read_participant_data <- function(file_path) {
  # 读取MATLAB文件
  mat_data <- readMat(file_path)
  
  # 提取trials数据
  trials <- mat_data$results[1, 1]$trials
  
  # 创建数据框
  n_trials <- length(trials)
  
  # 初始化数据框
  data <- data.frame(
    participantID = rep(mat_data$results[1, 1]$participantID, n_trials),
    block = numeric(n_trials),
    trialInBlock = numeric(n_trials),
    trialOverall = numeric(n_trials),
    gridType = character(n_trials),
    setSize = numeric(n_trials),
    isChangeTrial = logical(n_trials),
    rt = numeric(n_trials),
    accuracy = numeric(n_trials),
    stringsAsFactors = FALSE
  )
  
  # 填充数据框
  for (i in 1:n_trials) {
    data$block[i] <- trials[[i]]$block
    data$trialInBlock[i] <- trials[[i]]$trialInBlock
    data$trialOverall[i] <- trials[[i]]$trialOverall
    data$gridType[i] <- trials[[i]]$gridType
    data$setSize[i] <- trials[[i]]$setSize
    data$isChangeTrial[i] <- as.logical(trials[[i]]$isChangeTrial)
    data$rt[i] <- trials[[i]]$rt
    data$accuracy[i] <- trials[[i]]$accuracy
  }
  
  return(data)
}

# 函数：读取所有被试数据并合并
read_all_participant_data <- function(data_dir = ".") {
  # 获取所有最终数据文件
  data_files <- list.files(path = data_dir, 
                           pattern = "*_finalData.mat$", 
                           full.names = TRUE)
  
  # 如果没有找到文件，给出提示
  if (length(data_files) == 0) {
    stop("未找到数据文件，请检查目录和文件命名")
  }
  
  # 读取并合并所有数据
  all_data <- data.frame()
  for (file in data_files) {
    cat("正在读取文件:", file, "\n")
    participant_data <- read_participant_data(file)
    all_data <- rbind(all_data, participant_data)
  }
  
  return(all_data)
}

# 主分析函数
analyze_data <- function() {
  # 读取所有数据
  cat("正在读取数据文件...\n")
  all_data <- read_all_participant_data()
  
  # 数据预处理
  cat("正在进行数据预处理...\n")
  
  # 将gridType转换为因子并排序
  all_data$gridType <- factor(all_data$gridType, 
                             levels = c("NoGrid", "Grid6x6", "Grid3x3", "Grid2x2", "Grid1x1"))
  
  # 将setSize转换为因子
  all_data$setSize <- factor(all_data$setSize)
  
  # 移除反应时缺失或极端值的试次
  clean_data <- all_data %>%
    filter(!is.na(rt) & rt > 0.2 & rt < 2.5)
  
  # 描述性统计
  cat("正在计算描述性统计...\n")
  
  # 按网格类型和记忆负荷计算平均准确率
  accuracy_summary <- clean_data %>%
    group_by(participantID, gridType, setSize) %>%
    summarize(
      mean_accuracy = mean(accuracy, na.rm = TRUE),
      sd_accuracy = sd(accuracy, na.rm = TRUE),
      n = n(),
      .groups = 'drop'
    )
  
  # 按网格类型和记忆负荷计算平均反应时
  rt_summary <- clean_data %>%
    filter(accuracy == 1) %>% # 只分析正确试次的反应时
    group_by(participantID, gridType, setSize) %>%
    summarize(
      mean_rt = mean(rt, na.rm = TRUE),
      sd_rt = sd(rt, na.rm = TRUE),
      n = n(),
      .groups = 'drop'
    )
  
  # 计算总体平均值
  overall_accuracy <- clean_data %>%
    group_by(gridType, setSize) %>%
    summarize(
      mean_accuracy = mean(accuracy, na.rm = TRUE),
      se_accuracy = sd(accuracy, na.rm = TRUE) / sqrt(n()),
      n = n(),
      .groups = 'drop'
    )
  
  overall_rt <- clean_data %>%
    filter(accuracy == 1) %>%
    group_by(gridType, setSize) %>%
    summarize(
      mean_rt = mean(rt, na.rm = TRUE),
      se_rt = sd(rt, na.rm = TRUE) / sqrt(n()),
      n = n(),
      .groups = 'drop'
    )
  
  # 打印描述性统计结果
  cat("\n准确率描述性统计:\n")
  print(overall_accuracy)
  
  cat("\n反应时描述性统计:\n")
  print(overall_rt)
  
  # 绘制准确率图形
  cat("正在生成准确率可视化图形...\n")
  acc_plot <- ggplot(overall_accuracy, aes(x = setSize, y = mean_accuracy, 
                                         color = gridType, group = gridType)) +
    geom_line(size = 1) +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = mean_accuracy - se_accuracy, 
                      ymax = mean_accuracy + se_accuracy), 
                  width = 0.2) +
    scale_color_viridis_d() +
    labs(x = "记忆负荷 (项目数量)", 
         y = "平均准确率", 
         color = "网格类型") +
    theme_minimal(base_size = 14) +
    theme(legend.position = "bottom",
          panel.grid.minor = element_blank()) +
    scale_y_continuous(limits = c(0.5, 1), breaks = seq(0.5, 1, 0.1)) +
    ggtitle("不同网格类型和记忆负荷下的准确率")
  
  # 绘制反应时图形
  cat("正在生成反应时可视化图形...\n")
  rt_plot <- ggplot(overall_rt, aes(x = setSize, y = mean_rt, 
                                   color = gridType, group = gridType)) +
    geom_line(size = 1) +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = mean_rt - se_rt, 
                      ymax = mean_rt + se_rt), 
                  width = 0.2) +
    scale_color_viridis_d() +
    labs(x = "记忆负荷 (项目数量)", 
         y = "平均反应时 (秒)", 
         color = "网格类型") +
    theme_minimal(base_size = 14) +
    theme(legend.position = "bottom",
          panel.grid.minor = element_blank()) +
    ggtitle("不同网格类型和记忆负荷下的反应时")
  
  # 组合图形
  combined_plot <- ggarrange(acc_plot, rt_plot, 
                            ncol = 2, common.legend = TRUE, legend = "bottom")
  
  # 保存图形
  ggsave("accuracy_plot.png", acc_plot, width = 8, height = 6, dpi = 300)
  ggsave("rt_plot.png", rt_plot, width = 8, height = 6, dpi = 300)
  ggsave("combined_plot.png", combined_plot, width = 12, height = 6, dpi = 300)
  
  # ANOVA分析 - 准确率
  cat("正在进行准确率的统计分析...\n")
  acc_aov <- ezANOVA(
    data = accuracy_summary,
    dv = mean_accuracy,
    wid = participantID,
    within = .(gridType, setSize),
    detailed = TRUE,
    type = 3
  )
  
  # ANOVA分析 - 反应时
  cat("正在进行反应时的统计分析...\n")
  rt_aov <- ezANOVA(
    data = rt_summary,
    dv = mean_rt,
    wid = participantID,
    within = .(gridType, setSize),
    detailed = TRUE,
    type = 3
  )
  
  # 打印ANOVA结果
  cat("\n准确率ANOVA结果:\n")
  print(acc_aov)
  
  cat("\n反应时ANOVA结果:\n")
  print(rt_aov)
  
  # 简单效应分析：在不同记忆负荷下比较网格类型
  cat("正在进行简单效应分析...\n")
  
  # 构建准确率的线性混合效应模型
  acc_model <- lmer(accuracy ~ gridType * setSize + (1|participantID), 
                   data = clean_data)
  
  # 构建反应时的线性混合效应模型
  rt_model <- lmer(rt ~ gridType * setSize + (1|participantID), 
                  data = clean_data[clean_data$accuracy == 1, ])
  
  # 进行事后比较
  acc_emm <- emmeans(acc_model, ~ gridType | setSize)
  rt_emm <- emmeans(rt_model, ~ gridType | setSize)
  
  # 准确率的简单效应分析
  acc_contrasts <- pairs(acc_emm)
  
  # 反应时的简单效应分析
  rt_contrasts <- pairs(rt_emm)
  
  # 打印事后比较结果
  cat("\n准确率的简单效应分析结果:\n")
  print(acc_contrasts)
  
  cat("\n反应时的简单效应分析结果:\n")
  print(rt_contrasts)
  
  # 返回所有分析结果
  return(list(
    data = clean_data,
    accuracy_summary = accuracy_summary,
    rt_summary = rt_summary,
    acc_aov = acc_aov,
    rt_aov = rt_aov,
    acc_model = acc_model,
    rt_model = rt_model,
    acc_contrasts = acc_contrasts,
    rt_contrasts = rt_contrasts,
    plots = list(
      acc_plot = acc_plot,
      rt_plot = rt_plot,
      combined_plot = combined_plot
    )
  ))
}

# 运行主分析函数
results <- analyze_data()

# 保存分析结果
cat("正在保存分析结果...\n")
save(results, file = "visual_wm_analysis_results.RData")

cat("分析完成！结果已保存为 'visual_wm_analysis_results.RData'。\n")