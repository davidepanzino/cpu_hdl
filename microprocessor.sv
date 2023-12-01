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
module microprocessor #(parameter N = 8, ROM_addressBits = 6, RF_addressBits = 3) (
  /* --------------------------------- Inputs --------------------------------- */
  input  logic                           clk             ,
  input  logic                           rst_n           ,
  input  logic [ 3+2*(RF_addressBits):0] ROM_data        ,
  input  logic [                  N-1:0] SRAM_data       ,
  /* --------------------------------- Outputs -------------------------------- */
  output logic                           overflowPC      ,
  //Memory
  output logic                           ROM_readEnable  ,
  output logic                           SRAM_readEnable ,
  output logic                           SRAM_writeEnable,
  output logic [    ROM_addressBits-1:0] ROM_address     ,
  output logic [(2**RF_addressBits)-1:0] SRAM_address    ,
  output logic [                  N-1:0] SRAM_data_in
);

  // RF
  logic RF_selectDestA, RF_selectDestB, RF_writeEnable;
  logic [1:0] RF_selectSource;
  logic [RF_addressBits-1:0] RF_writeAddress, RF_readAddressA, RF_readAddressB;
  logic [N-1:0] RF_AluRes, RF_Im, RF_destAluA, RF_destAluB;
  RF #(.N(N), .addressBits(RF_addressBits)) rf (
    clk,
    rst_n,
    RF_selectDestA,
    RF_selectDestB,
    RF_selectSource,
    RF_writeAddress,
    RF_writeEnable,
    RF_readAddressA,
    RF_readAddressB,
    RF_AluRes, SRAM_data, RF_Im,
    RF_destAluA, SRAM_data_in, RF_destAluB, SRAM_address);
  
  // ALU
  logic ALU_rst, ALU_en;
  logic [2:0] ALU_OP, ALU_ONZ;
  ALU #(N) alu (
    clk,
    rst_n,
    ALU_rst,
    ALU_en,
    ALU_OP,
    RF_destAluA,
    RF_destAluB,
    ALU_ONZ,
    RF_AluRes
  );

  // FSM
  FSM #(.N(N), .M(RF_addressBits), .P(ROM_addressBits)) fsm (
    clk,
    rst_n,
    overflowPC,
    RF_selectSource,
    RF_writeAddress,
    RF_writeEnable,
    RF_readAddressA,
    RF_readAddressB,
    RF_selectDestA,
    RF_selectDestB,
    RF_Im,
    ALU_OP,
    ALU_rst,
    ALU_ONZ,
    ALU_en,
    ROM_data,
    ROM_readEnable,
    ROM_address,
    SRAM_readEnable,
    SRAM_writeEnable
  );

endmodule