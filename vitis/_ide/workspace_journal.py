# 2026-06-08T12:19:23.412138600
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.create_platform_component(name = "hdmi_fir_platform",hw_design = "$COMPONENT_LOCATION/../../hdmi_top.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0",compiler = "gcc")

platform = client.get_component(name="hdmi_fir_platform")
status = platform.build()

comp = client.create_app_component(name="uart_control_app",platform = "$COMPONENT_LOCATION/../hdmi_fir_platform/export/hdmi_fir_platform/hdmi_fir_platform.xpfm",domain = "standalone_microblaze_riscv_0")

status = platform.build()

comp = client.get_component(name="uart_control_app")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

status = platform.build()

comp.build()

client.delete_component(name="hdmi_fir_platform")

client.delete_component(name="componentName")

client.delete_component(name="uart_control_app")

client.delete_component(name="componentName")

platform = client.create_platform_component(name = "hdmi_fir_platform",hw_design = "$COMPONENT_LOCATION/../../hdmi_top.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0",compiler = "gcc")

status = platform.build()

comp = client.create_app_component(name="fir_control_app",platform = "$COMPONENT_LOCATION/../hdmi_fir_platform/export/hdmi_fir_platform/hdmi_fir_platform.xpfm",domain = "standalone_microblaze_riscv_0")

status = platform.build()

comp = client.get_component(name="fir_control_app")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../hdmi_top.xsa")

status = platform.build()

status = platform.build()

comp.build()

status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../hdmi_top.xsa")

status = platform.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

