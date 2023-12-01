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

`include "instructions.sv"


module FSM #(
  parameter M = 4, // size of register address
  parameter N = 4, // size of register data
  parameter P = 6  // PC size and instruction memory address
) (
  input  logic clk,
  input  logic rst_n,
  output logic ov_warning,
  /* ---------------------- signals to/from register file --------------------- */
  output logic [  1:0] select_source,
  output logic [M-1:0] write_address,
  output logic             write_en,
  output logic [M-1:0] read_address_A, read_address_B,
  output logic select_destination_A, select_destination_B,
  output logic [N-1:0] immediate_value,
  /* --------------------------- signals to/from ALU -------------------------- */
  output logic [2:0] OP,
  output logic       s_rst,
  input  logic [2:0] ONZ,
  output logic enable,
  /* --------------------------- signals from instruction memory -------------- */
  input  logic [4+2*M-1:0] instruction_in,
  output logic              en_read_instr,
  output logic [P-1:0] read_address_instr,
  /*---------------------------Signals to the data memory--------------*/
  output logic SRAM_readEnable,
  output logic SRAM_writeEnable
);

enum logic [1:0] { idle = 2'b11, fetch = 2'b00, decode = 2'b01, execute= 2'b10} state, next;
/* ----------------------------- PROGRAM COUNTER ---------------------------- */
logic [  P-1:0] PC     ;
logic [  P-1:0] PC_next;
logic           ov     ;
logic           ov_reg ;
logic [2*M-1:0] offset ;

/*-----------------------------------------------------------------------------*/
// Add signals and logic here
logic [3:0]       instruction_code;
logic [M-1:0]     ra, rb;
logic [2:0]       ONZ_next, ONZ_reg;
logic [4+2*M-1:0] instruction_next, instruction_reg;

assign ov_warning = ov_reg;

/*-----------------------------------------------------------------------------*/

//State register
always @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    state <= idle;
  end else begin
    state <= next;
  end
end

/*-----------------------------------------------------------------------------*/
// Describe your next state and output logic here

// Next state logic
always_comb begin
  case (state)
    idle:    next = ov_reg ? idle : fetch;
    fetch:   next = decode;
    decode:  next = execute;
    execute: next = ov_reg ? idle : fetch;
    default: next = idle;
  endcase
end

// Combinational output logic
always_comb begin

  instruction_code     = 0;
  read_address_instr   = PC;
  en_read_instr        = 0;
  enable               = 0;
  read_address_A       = 0;
  read_address_B       = 0;
  OP                   = 0;
  select_destination_A = 0;
  select_destination_B = 0;
  SRAM_readEnable      = 0;
  SRAM_writeEnable     = 0;
  select_source        = 0;
  immediate_value      = 0;
  write_address        = 0;
  write_en             = 0;
  s_rst                = 0;
  PC_next              = PC;
  ONZ_next             = 0;
  ov                   = ov_reg;
  
  case (state)
    idle: begin
      /* RF */
      select_source        = 2'b00;
      write_address        = 0;
      write_en             = 1'b0;
      read_address_A       = 0;    
      read_address_B       = 0;
      select_destination_A = 1'b0;
      select_destination_B = 1'b0;
      immediate_value      = 0;
      /* ALU */
      OP                   = 3'b000;
      s_rst                = 1'b0;
      enable               = 1'b0;
      /* ROM */
      en_read_instr        = 1'b0;
      read_address_instr   = PC;
      offset               = 1;
      /* RAM*/
      SRAM_readEnable      = 1'b0;
      SRAM_writeEnable     = 1'b0;
    end
    fetch: begin
      /* RF */
      select_source        = 2'b00;
      write_address        = 0;
      write_en             = 1'b0;
      read_address_A       = 0;    
      read_address_B       = 0;
      select_destination_A = 1'b0;
      select_destination_B = 1'b0;
      immediate_value      = 0;
      /* ALU */
      OP                   = 3'b000;
      s_rst                = 1'b0;
      enable               = 1'b0;
      /* ROM */
      en_read_instr        = 1'b1;
      read_address_instr   = PC;
    end
    decode: begin 
      ONZ_next         = ONZ;
      instruction_next = instruction_in;
      instruction_code = instruction_in[4+2*M-1:2*M];
      ra               = instruction_in[2*M-1 : M];
      rb               = instruction_in[M-1:0];
      case (instruction_code)
        ADD, SUB, AND, OR, XOR     : begin
          /* RF */
          read_address_A       = ra;    
          read_address_B       = rb;
          /* ALU */
          OP                   = instruction_code[2:0];
          enable               = 1'b1;
        end
        NOT     : begin
          /* RF */
          read_address_A       = 1;    
          read_address_B       = rb;
          /* ALU */
          OP                   = 3'b100;
          enable               = 1'b1;
        end
        MOV     : begin
          /* RF */
          read_address_A       = ra;    
          read_address_B       = rb;
          /* ALU */
          OP                   = 3'b111;
          enable               = 1'b1;
        end
        NOP     : begin
        end
        LOAD    : begin
          /* RF */
          read_address_A       = ra;    
          read_address_B       = rb;
          select_destination_A = 1'b1;
          select_destination_B = 1'b1;
          /* RAM*/
          SRAM_readEnable      = 1'b1;
        end
        STORE   : begin
          /* RF */
          read_address_A       = rb;    
          read_address_B       = ra;
          select_destination_A = 1'b1;
          select_destination_B = 1'b1;
          /* RAM*/
          SRAM_writeEnable     = 1'b1;
        end
        LOAD_IM : begin
          /* RF */
          select_source        = 2'b10;
          write_address        = ra;
          write_en             = 1'b1;
          immediate_value      = $signed(rb);
        end
        BRN_Z, BRN_N, BRN_O, BRN : begin
          s_rst                = 1'b1;
        end
      endcase
    end
    execute: begin
      instruction_code = instruction_reg[4+2*M-1:2*M];
      ra               = instruction_reg[2*M-1 : M];
      rb               = instruction_reg[M-1:0];
      case (instruction_code)
        ADD, SUB, AND, OR, XOR, NOT, MOV: begin
          /* RF */
          select_source        = 2'b00;
          write_address        = ra;
          write_en             = 1'b1;
          /* ALU */
          enable               = 1'b0;
          {ov,PC_next}         = PC+1;          
        end
        NOP     : begin
          {ov,PC_next}         = PC+1; 
        end
        LOAD    : begin
          /* RF */
          select_source        = 2'b01;
          write_address        = ra;
          write_en             = 1'b1;
          {ov,PC_next}         = PC+1;
        end
        STORE   : begin
          {ov,PC_next}         = PC+1;
        end
        LOAD_IM : begin
          /* RF */
          {ov,PC_next}         = PC+1;
        end
        BRN_Z   : begin
          s_rst = 0;
          if(ONZ_reg[0] == 1) 
            offset  = {ra, rb};
          else 
            offset = 1;
          if (offset[2*M-1]==1) begin
            {ov,PC_next} = PC - offset[2*M-2:0];
          end else begin
            {ov,PC_next} = PC + offset[2*M-2:0];
          end
        end
        BRN_N : begin
          s_rst = 0;
          if(ONZ_reg[1] == 1) 
            offset  = {ra, rb};
          else 
            offset = 1;
          if (offset[2*M-1]==1) begin
            {ov,PC_next} = PC - offset[2*M-2:0];
          end else begin
            {ov,PC_next} = PC + offset[2*M-2:0];
          end
        end
        
        BRN_O   : begin
          s_rst = 0;
          if(ONZ_reg[2] == 1) 
            offset  = {ra, rb};
          else 
            offset = 1;
          if (offset[2*M-1]==1) begin
            {ov,PC_next} = PC - offset[2*M-2:0];
          end else begin
            {ov,PC_next} = PC + offset[2*M-2:0];
          end
        end
        BRN     : begin
          s_rst  = 0;
          offset = {ra, rb};
          if (offset[2*M-1]==1) begin
            {ov,PC_next} = PC - offset[2*M-2:0];
          end else begin
            {ov,PC_next} = PC + offset[2*M-2:0];
          end
        end
      endcase
    end
  endcase
end

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    instruction_reg <= 0;
    ONZ_reg         <= 0;
    ov_reg          <= 0;
    PC              <= 0;
  end else begin
    instruction_reg <= instruction_next;
    ONZ_reg         <= ONZ_next;
    ov_reg          <= ov;
    PC              <= PC_next;
  end
end

// PC and overflow
/*always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    PC     <= 0;
    ov_reg <= 0;
  end else if (state == decode) begin
    PC     <= PC_next;
    ov_reg <= ov;
  end
end*/

endmodule