Ez a mappa a leadáshoz osszegyujtott, letisztitott forrasokat tartalmazza.

Tartalom:
- Vivado: a hardverprojekt ujraepitesehez szukseges HDL, XDC, blokkdiagram, sajat IP es szimulacios forrasok.
- Vitis: a szoftverprojekt ujraepitesehez szukseges XSA es az alkalmazas forrasai.

Javasolt hasznalat:
1. Vivado oldalon hozz letre egy uj projektet, majd add hozza a `Vivado` mappa megfelelo forrasait.
2. Add hozza a `Vivado\\custom_ip\\fir_coeff_bank_axi_1_0` mappat local IP repository-kent.
3. Importald a `cpu_hdmi_system.bd` blokkdiagramot, majd generald ujra a designt.
4. A hardver exportja utan Vitis-ben hozz letre uj platformot a `Vitis\\hardware\\hdmi_top.xsa` fajlbol.
5. Hozz letre egy uj alkalmazasprojektet, es hasznald a `Vitis\\fir_control_app\\src` mappa fajljait.

Megjegyzes:
- A mappabol szandekosan hianyoznak a generalt cache, run, build es egyeb ideiglenes allomanyok.
- A ket UART koefficiens fajl csak kenyelmi segedlet, nem kotelezo a projekt ujraepitesehez.
