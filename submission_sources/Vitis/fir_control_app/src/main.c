#include "xparameters.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "xuartlite_l.h"

static int decimal4_to_q8_8_raw(int decimal4_value)
{
    long long scaled;

    /* Round the 4-decimal fixed-point input to the nearest Q8.8 integer. */
    if (decimal4_value >= 0) {
        scaled = (long long)decimal4_value * 256 + 5000;
    } else {
        scaled = (long long)decimal4_value * 256 - 5000;
    }

    return (int)(scaled / 10000);
}

static void load_default_coefficients(void)
{
    int coeff_index;

    /* Clear all 25 coefficient registers before loading the identity tap. */
    for (coeff_index = 0; coeff_index < 25; ++coeff_index) {
        Xil_Out32(XPAR_FIR_COEFF_BANK_AXI_0_BASEADDR + 4 * coeff_index, 0);
    }

    /*
     * The streaming FIR uses the bottom-right tap as the "current" sample
     * location, so an identity kernel is EH 24 = +1.0000.
     */
    Xil_Out32(XPAR_FIR_COEFF_BANK_AXI_0_BASEADDR + 4 * 24, 256);
}

int main(void)
{
    u8 received_byte;
    char input_line[64];
    int input_length = 0;
    int decimal4_coefficients[25];
    int stored_coefficients = 0;
    int coeff_index;

    XUartLite_SetControlReg(XPAR_XUARTLITE_0_BASEADDR,
                            XUL_CR_FIFO_RX_RESET | XUL_CR_FIFO_TX_RESET);

    load_default_coefficients();

    xil_printf("\r\nUART FIR coefficient loader ready.\r\n");
    xil_printf("Send 25 coefficients line by line.\r\n");
    xil_printf("Accepted input: +0.0011 or EH 0: +0.0011\r\n");
    xil_printf("Default kernel after reset: EH 24 = +1.0000, others 0.\r\n\r\n");

    while (1) {
        /* Poll the UART until a new character arrives. */
        while (XUartLite_IsReceiveEmpty(XPAR_XUARTLITE_0_BASEADDR)) {
        }

        received_byte = XUartLite_RecvByte(XPAR_XUARTLITE_0_BASEADDR);

        if (received_byte == '\r' || received_byte == '\n') {
            int sign = 1;
            int int_part = 0;
            int frac_part = 0;
            int frac_digits = 0;
            int value = 0;
            int valid = 1;
            int found_number = 0;
            char *cursor;

            while (XUartLite_IsTransmitFull(XPAR_XUARTLITE_0_BASEADDR)) {
            }
            XUartLite_SendByte(XPAR_XUARTLITE_0_BASEADDR, '\r');
            while (XUartLite_IsTransmitFull(XPAR_XUARTLITE_0_BASEADDR)) {
            }
            XUartLite_SendByte(XPAR_XUARTLITE_0_BASEADDR, '\n');

            input_line[input_length] = '\0';
            cursor = input_line;

            /* Accept optional leading whitespace and the "EH n:" prefix. */
            while (*cursor == ' ' || *cursor == '\t') {
                ++cursor;
            }

            if ((cursor[0] == 'E' || cursor[0] == 'e') &&
                (cursor[1] == 'H' || cursor[1] == 'h')) {
                cursor += 2;

                while (*cursor == ' ' || *cursor == '\t') {
                    ++cursor;
                }

                while (*cursor >= '0' && *cursor <= '9') {
                    ++cursor;
                }

                while (*cursor == ' ' || *cursor == '\t') {
                    ++cursor;
                }

                if (*cursor == ':') {
                    ++cursor;
                }
            }

            while (*cursor == ' ' || *cursor == '\t') {
                ++cursor;
            }

            if (*cursor == '+') {
                ++cursor;
            } else if (*cursor == '-') {
                sign = -1;
                ++cursor;
            }

            while (*cursor >= '0' && *cursor <= '9') {
                found_number = 1;
                int_part = int_part * 10 + (*cursor - '0');
                ++cursor;
            }

            if (*cursor == '.') {
                ++cursor;

                while (*cursor >= '0' && *cursor <= '9') {
                    if (frac_digits < 4) {
                        frac_part = frac_part * 10 + (*cursor - '0');
                    }
                    ++frac_digits;
                    ++cursor;
                }
            }

            while (frac_digits < 4) {
                frac_part *= 10;
                ++frac_digits;
            }

            while (*cursor == ' ' || *cursor == '\t') {
                ++cursor;
            }

            if (*cursor != '\0') {
                valid = 0;
            }

            if (!found_number) {
                valid = 0;
            }

            /* More than 4 fractional digits would not match the decimal4 format. */
            if (frac_digits > 4) {
                valid = 0;
            }

            if (valid) {
                /* Store coefficients as signed integers scaled by 10^4. */
                value = sign * (int_part * 10000 + frac_part);
                decimal4_coefficients[stored_coefficients] = value;
                ++stored_coefficients;

                xil_printf("Stored coefficient %d/25\r\n", stored_coefficients);

                if (stored_coefficients == 25) {
                    xil_printf("\r\nFull coefficient set received.\r\n");

                    for (coeff_index = 0; coeff_index < 25; ++coeff_index) {
                        int abs_value = decimal4_coefficients[coeff_index];
                        char sign_char = '+';

                        if (abs_value < 0) {
                            sign_char = '-';
                            abs_value = -abs_value;
                        }

                        xil_printf("EH %d: %c%d.%04d\r\n",
                                   coeff_index,
                                   sign_char,
                                   abs_value / 10000,
                                   abs_value % 10000);
                    }

                    /* Convert and write the full 5x5 coefficient set in register order. */
                    for (coeff_index = 0; coeff_index < 25; ++coeff_index) {
                        int q8_8_raw = decimal4_to_q8_8_raw(
                            decimal4_coefficients[coeff_index]);
                        Xil_Out32(XPAR_FIR_COEFF_BANK_AXI_0_BASEADDR + 4 * coeff_index,
                                  (u32)q8_8_raw);
                    }

                    xil_printf("\r\nCoefficients applied to FIR.\r\n");
                    xil_printf("Ready for next 25 coefficients.\r\n");
                    stored_coefficients = 0;
                }
            } else if (input_length != 0) {
                xil_printf("Invalid format. Use +0.0011 or EH n: +0.0011\r\n");
            }

            /* Start collecting the next input line after Enter. */
            input_length = 0;
        } else if ((received_byte == 8 || received_byte == 127) && input_length > 0) {
            --input_length;

            /* Echo backspace in a terminal-friendly way. */
            while (XUartLite_IsTransmitFull(XPAR_XUARTLITE_0_BASEADDR)) {
            }
            XUartLite_SendByte(XPAR_XUARTLITE_0_BASEADDR, 8);
            while (XUartLite_IsTransmitFull(XPAR_XUARTLITE_0_BASEADDR)) {
            }
            XUartLite_SendByte(XPAR_XUARTLITE_0_BASEADDR, ' ');
            while (XUartLite_IsTransmitFull(XPAR_XUARTLITE_0_BASEADDR)) {
            }
            XUartLite_SendByte(XPAR_XUARTLITE_0_BASEADDR, 8);
        } else if (input_length < (int)sizeof(input_line) - 1) {
            input_line[input_length] = (char)received_byte;
            ++input_length;

            /* Echo regular characters so the typed coefficient is visible on UART. */
            while (XUartLite_IsTransmitFull(XPAR_XUARTLITE_0_BASEADDR)) {
            }
            XUartLite_SendByte(XPAR_XUARTLITE_0_BASEADDR, received_byte);
        } else {
            xil_printf("\r\nLine too long.\r\n");
            input_length = 0;
        }
    }

    return 0;
}
