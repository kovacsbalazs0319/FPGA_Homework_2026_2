Ez a mappa a Vitis projekt ujraepitesehez szukseges forrasokat tartalmazza.

Tartalom:
- `hardware\\hdmi_top.xsa`: a Vivado-bol exportalt hardware handoff.
- `fir_control_app\\src`: az alkalmazas forrasfajljai.
- `gaussian_5x5_uart_coeffs.txt` es `laplace_5x5_uart_coeffs_centered.txt`: kenyelmi UART bemenetmintak.

Ujraepiteshez:
1. Hozz letre uj Vitis platformot a `hardware\\hdmi_top.xsa` alapjan.
2. Hozz letre uj application projectet.
3. Masold be vagy importald a `fir_control_app\\src` tartalmat az alkalmazas forraskent.
