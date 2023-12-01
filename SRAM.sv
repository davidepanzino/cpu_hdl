//-------------- Copyright (c) notice -----------------------------------------
//
// The SV code, the logic and concepts described in this file constitute
// the intellectual property of the authors listed below, who are affiliated
// to KTH (Kungliga Tekniska Högskolan), School of EECS, Kista.
// Any unauthorised use, copy or distribution is strictly prohibited.
// Any authorised use, copy or distribution should carry this copyright notice
// unaltered.
//-----------------------------------------------------------------------------
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
//                                                                         #
//This file is part of IL1332 and IL2234 course.                           #
//                                                                         #
//    The source code is distributed freely: you can                       #
//    redistribute it and/or modify it under the terms of the GNU          #
//    General Public License as published by the Free Software Foundation, #
//    either version 3 of the License, or (at your option) any             #
//    later version.                                                       #
//                                                                         #
//    It is distributed in the hope that it will be useful,                #
//    but WITHOUT ANY WARRANTY; without even the implied warranty of       #
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
//    GNU General Public License for more details.                         #
//                                                                         #
//    See <https://www.gnu.org/licenses/>.                                 #
//                                                                         #
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
module SRAM #(parameter N = 8, ROM_addressBits = 6, RF_addressBits = 3) (
  input  logic                           clk             ,
  input  logic                           SRAM_readEnable ,
  input  logic                           SRAM_writeEnable,
  input  logic [N-1:0] SRAM_address    ,
  input  logic [                  N-1:0] SRAM_data_in    ,
  output logic [                  N-1:0] SRAM_data
);

  logic [N-1:0] SRAM_memory [(2**N)-1:0];
  //Describe the behavior of the SRAM here
  always_ff @(posedge clk) begin
    SRAM_data <= 0;
    for(int i = 0; i < (2**N); i++) begin
      if(SRAM_address == i) begin
        if(SRAM_readEnable && !SRAM_writeEnable) begin
          SRAM_data <= SRAM_memory[i];
        end else if (!SRAM_readEnable && SRAM_writeEnable) begin
          SRAM_memory[i] <= SRAM_data_in;
        end
      end
    end
  end
endmodule