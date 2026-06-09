Ez a mappa a Vivado projekt ujraepitesehez szukseges forrasokat tartalmazza.

Almappak:
- `hdl`: a top-level es a sajat HDL modulok.
- `constraints`: az XDC fajlok.
- `block_design`: a processzoros alrendszer blokkdiagramja es a kapcsolodo IP definiciok.
- `custom_ip`: a sajat AXI egyutthato-bank IP teljes forrasa.
- `simulation`: a szimulacios testbench fajlok.

Ujraepiteshez:
1. Uj Vivado projekt letrehozasa.
2. A `hdl`, `constraints` es `simulation` fajlok importalasa.
3. A `custom_ip\\fir_coeff_bank_axi_1_0` mappa felvetele IP repository-kent.
4. A `block_design\\cpu_hdmi_system.bd` importalasa, majd output product/generalas.
