set_property SRC_FILE_INFO {cfile:c:/Users/Balazs/Desktop/MSC1/FPGA/homework/HDMI_FIR_Homework.gen/sources_1/bd/cpu_hdmi_system/ip/cpu_hdmi_system_clk_wiz_1_0/cpu_hdmi_system_clk_wiz_1_0.xdc rfile:../../../HDMI_FIR_Homework.gen/sources_1/bd/cpu_hdmi_system/ip/cpu_hdmi_system_clk_wiz_1_0/cpu_hdmi_system_clk_wiz_1_0.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
current_instance inst
set_property src_info {type:SCOPED_XDC file:1 line:54 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.100
