1.对于curpd.excel直接刷新即可
fpd.excel:
1.基础建设组在数仓跑完spr并将最后结果导到data_ananlysis库,同时在data_ananlysis库更新完zhibin_application_info_v1表（代码见spr以及information更新sql文件夹）
2.对于fpd、spd、tpd需要将excel中 数据->连接->fpdadd1(或者spd\tpd)->属性->定义->命令文本 代码做以下修改
  1)将sql代码中data_analysis.spr_r_data_20160826表名更新为data_analysis库中spr最新的数据比如更新为：data_analysis.spr_r_data_20160901
  2）将代码里时间2016-08-26更新为spr表名对应的时间，比如：2016-09-01
  3）刷新excel即可