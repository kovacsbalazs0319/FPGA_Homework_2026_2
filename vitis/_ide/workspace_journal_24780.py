# 2026-06-09T17:40:57.585363800
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.get_component(name="hdmi_fir_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../hdmi_top.xsa")

status = platform.build()

status = platform.build()

comp = client.get_component(name="fir_control_app")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

vitis.dispose()

