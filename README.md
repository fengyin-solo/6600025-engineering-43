# solo-6600025: CAN 总线数据帧解析与诊断仪

## 技术栈
- Frontend: Vue 3 + TypeScript + Vite + Pinia + Tailwind CSS + ECharts
- Backend: Java 17 + Spring Boot 3.2.0

## 核心特性
1. **DBC 文件解析**：解析 DBC 格式信号定义，提取 CAN 信号参数
2. **OBD-II 标准 PID 支持**：EngineRPM、VehicleSpeed、CoolantTemp 等标准诊断
3. **实时帧捕获**：模拟 CAN 帧实时采集，支持过滤与搜索
4. **ECharts 时序曲线**：多信号实时趋势对比图
5. **总线负载率分析**：总线利用率统计
6. **CSV 导出**：帧数据导出为 CSV 格式
