# LPC_analyse
LPC_analyse based on speach signal processing
##操作指南
因为没有做GUI，操作需要对代码稍加更改进行操作。

具体操作：更改读入文件路径选择源文件。通过注释的时段改变激励信号。（可以将激励信号用文件读入使用trumpet-c4）运行代码在图床中进行观察。
将调用lpc（）函数的语句注释，换做调用Arcov函数，其中Arcov函数也包含在该文件夹中。

##文件说明
文件说明：本项目通过LPC分析获得预测滤波器和声道模型，并展示了预测滤波器预测的信号，预测误差
周期冲激信号通过声道模型的效果和白噪声通过声道模型的效果。LPC系数的估计通过调用matlab
的LPC函数实现。同时声道模型的激励信号可以换成读入的一段音频，观察通过声道模型后的信号。

##补充说明
Acrov文件为lpc_coffer函数。LPC_analyse 为主脚本。注意使用lpc_coffer函数替换lpc函数时要将LPC_analyse 文件中的lpc函数调用语句注释，将lpc_coffer函数复制到LPC_analyse 文件中，和lpc函数相同格式调用
