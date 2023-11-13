// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype wire
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

`ifndef MPRJ_IO_PADS
`define MPRJ_IO_PADS 32
`endif

        module user_proj_example #(
            parameter BITS = 32,
            parameter DELAYS=10
        )(
`ifdef USE_POWER_PINS
            inout vccd1,	// User area 1 1.8V supply
            inout vssd1,	// User area 1 digital ground
`endif

            // Wishbone Slave ports (WB MI A)
            input wb_clk_i,
            input wb_rst_i,
            input wbs_stb_i, // master要發送請求
            input wbs_cyc_i, // bus enable的訊號
            input wbs_we_i,  // master想要讀或寫
            input [3:0] wbs_sel_i, // master 讀寫的位元組eable，用於實現單字節寫等
            input [31:0] wbs_dat_i, // master從slave讀取的數據
            input [31:0] wbs_adr_i, // master 想要讀寫的位址
            output reg wbs_ack_o, // slave的請求處理
            output reg [31:0] wbs_dat_o, // slave 提供給master 的讀取的數據

            // Logic Analyzer Signals
            input  [127:0] la_data_in,
            output reg [127:0] la_data_out,
            input  [127:0] la_oenb,

            // IOs
            input  [`MPRJ_IO_PADS-1:0] io_in,
            output reg [`MPRJ_IO_PADS-1:0] io_out,
            output reg [`MPRJ_IO_PADS-1:0] io_oeb,

            // IRQ
            output reg [2:0] irq
        );

wire            valid;
wire [3:0]      we;
wire [BITS-1:0] rdata; //read data from bram
reg  [BITS-1:0] count;

assign valid = (wbs_stb_i == 1) && (wbs_cyc_i == 1) && (wbs_adr_i[31:24] == 8'h38);
assign we    = {4{wbs_we_i & valid}};

bram user_bram (
         .CLK(wb_clk_i),
         .WE0(we),
         .EN0(valid),
         .Di0(wbs_dat_i),
         .Do0(rdata),
         .A0(wbs_adr_i)
     );

always @(posedge wb_clk_i)
begin
    if (wb_rst_i)
    begin
        count <= 0;
    end
    else
    begin
        if(count == DELAYS)
        begin
            count <= 0;
        end
        else
        begin
            if(valid == 1 && wbs_ack_o != 1)
            begin
                count <= count + 1;
            end
            else
                count <= count;
        end
    end
end

always @(posedge wb_clk_i)
begin
    if (wb_rst_i)
    begin
        wbs_ack_o <= 0;
    end
    else
    begin
        if(count == DELAYS)
        begin
            wbs_ack_o <= 1;
        end
        else
        begin
            wbs_ack_o <= 0;
        end
    end
end

always @(posedge wb_clk_i)
begin
    if (wb_rst_i)
    begin
        wbs_dat_o <= 0;
    end
    else
    begin
        wbs_dat_o <= rdata;
    end
end
endmodule

`default_nettype wire
