class constraint_random_class #(
    parameter M = 4, // size of register address
    parameter N = 4, // size of register data
    parameter P = 6  // PC size and instruction memory address
  );

rand logic             offset_sign;
rand logic [2:0]       ONZ;
rand logic [3:0]       instruction;
rand logic [M-1:0]     ra, rb;
rand logic [2*M-2:0]   temp_offset;
rand logic [4+2*M-1:0] jump_instr, no_jump_instr;

int  lims[1:0];
logic overflow;
logic [2:0] OP;
logic [P-1:0] PC;
logic [N-1:0] immediate_value;
logic [2*M-1:0] offset;

function new();
    PC = 0;
endfunction

/*function void pre_randomize();
    lims[0] = 0;
    lims[1] = (2**(M-1)-1);
    $display("lims %d, %d", lims[0], lims[1]);
endfunction*/

function void post_randomize();
    case (instruction)
        ADD:      OP = 3'b000;
        SUB:      OP = 3'b001;
        AND:      OP = 3'b010;
        OR:       OP = 3'b011;
        XOR, NOT: OP = 3'b100;
        MOV:      OP = 3'b111;
    endcase
    immediate_value = $signed(rb);
    offset = {offset_sign, temp_offset};
    jump_instr    = {instruction, offset};
    no_jump_instr = {instruction, ra, rb};
    //$display("%d, %x, %x, %x, %x", $time, offset_sign, temp_offset, PC, offset);
endfunction

constraint instr_c {instruction >= 0; instruction <= 14;};
constraint offset_c {(offset_sign == 1) -> (temp_offset inside {[PC:0]});
    (offset_sign == 0) -> (temp_offset inside {[0:2**(M-1)-1]});};
//constraint offset_c {offset inside {[lims[0]:lims[1]]};};
constraint onz_c {(instruction == BRN_Z) -> (ONZ inside {3'b000, 3'b001});
    (instruction == BRN_N) -> (ONZ inside {3'b000, 3'b010});
    (instruction == BRN_O) -> (ONZ inside {3'b000, 3'b100});};
constraint order {solve instruction before ONZ;};
endclass