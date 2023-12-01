//`include "instructions.sv"
//`include "ref_system.sv"

class random_instruction  #(parameter N = 8, ROM_addressBits = 6, RF_addressBits = 3);
    randc logic [3:0] op;
    rand logic [RF_addressBits-1:0] ra, rb;
    
    constraint valid_op{ op >=0; op <= 14;}
    constraint brn_limit {(op inside{[11:14]}) -> {({ra,rb} < (2**ROM_addressBits))};}
    constraint store_load_not_same {(op inside{[8:9]}) -> {ra != rb};}
    constraint write_to_zero {(op inside{[0:6], 8, 10}) -> {(ra != 0)};}
    constraint write_to_one {(op inside{[0:6], 8, 10}) -> {(ra != 1)};}
endclass
class random_instructions #(parameter N = 8, ROM_addressBits = 6, RF_addressBits = 3);
    rand random_instruction ROM_data_obj [2**ROM_addressBits-1:0];
    logic [3+2*(RF_addressBits):0] ROM_data [2**ROM_addressBits-1:0];
    
    function new();
        for(int i = 0; i < 2**ROM_addressBits; i++) begin
            ROM_data_obj[i]=new();      
        end 
    endfunction
    
    //Post/pre functions are run highlest first.
    function void post_randomize;
        int rf_load_count = 0;
        for(int i = 0; i < 2**ROM_addressBits; i++) begin
            // Clear sram *i = i;
            //load_im r3 = 1
            //mov r2 = r1
            //add r2 = r2 + r3
            //store r2 = r3
            //mov r4 = r2
            //xor r4 = r4 r1
            //brn_z -5
            if(i == 0) begin
                ROM_data_obj[i].op = LOAD_IM;
                ROM_data_obj[i].ra = 3;
                ROM_data_obj[i].rb = 1;
            end else if(i == 1) begin
                ROM_data_obj[i].op = MOV;
                ROM_data_obj[i].ra = 2;
                ROM_data_obj[i].rb = 1;
            end else if(i == 2) begin
                ROM_data_obj[i].op = ADD;
                ROM_data_obj[i].ra = 2;
                ROM_data_obj[i].rb = 3;
            end else if(i == 3) begin
                ROM_data_obj[i].op = STORE;
                ROM_data_obj[i].ra = 2;
                ROM_data_obj[i].rb = 2;
            end else if(i == 4) begin
                ROM_data_obj[i].op = MOV;
                ROM_data_obj[i].ra = 4;
                ROM_data_obj[i].rb = 2;
            end else if(i == 5) begin
                ROM_data_obj[i].op = SUB;
                ROM_data_obj[i].ra = 4;
                ROM_data_obj[i].rb = 1;
            end else if(i == 6) begin
                ROM_data_obj[i].op = BRN_Z;
                {ROM_data_obj[i].ra, ROM_data_obj[i].rb} = 2;
            end else if(i == 7) begin
                ROM_data_obj[i].op = BRN;
                {ROM_data_obj[i].ra, ROM_data_obj[i].rb} = 1<<(RF_addressBits + RF_addressBits-1) | 5;
            
            // Clamp branch operations
            end else if (rf_load_count<2**RF_addressBits-2) begin
                // Start with Load IM
                ROM_data_obj[i].op = LOAD_IM;
                ROM_data_obj[i].ra = rf_load_count + 2;
                rf_load_count++;
            end else if (ROM_data_obj[i].op >= 11 && ROM_data_obj[i].op <= 14) begin
                {ROM_data_obj[i].ra,ROM_data_obj[i].rb} = ({ROM_data_obj[i].ra,ROM_data_obj[i].rb} & ('h0F)) | 'h1;
            end
            ROM_data[i] = {ROM_data_obj[i].op, ROM_data_obj[i].ra, ROM_data_obj[i].rb};
        end 
    endfunction
endclass

const bit PRINT_SUCCESS = 0;
const bit PRINT_ERRORS = 1;
`define test(NAME, EXPECTED, ACTUAL) \
    begin \
        totalTests += 1; \
        assert(ACTUAL === EXPECTED) begin \
            if (PRINT_SUCCESS) $display("%0t, '%s', Pass, %s, Expected, '%x', Result, '%x'", $time, NAME, `"ACTUAL`", EXPECTED, ACTUAL); \
        end else begin \
            totalErrors += 1; \
            if (PRINT_ERRORS) $error("%0t, '%s', Fail, '%s', Expected, '%x', Result, '%x'", $time, NAME, `"ACTUAL`", EXPECTED, ACTUAL); \
        end \
    end
`define test_rf(NAME, EXPECTED, ACTUAL) \
    begin \
        totalRfTests += 1; \
        for(int i = 0; i < 2**RF_addressBits; i++) begin \
            assert(ACTUAL[i] === EXPECTED[i]) begin \
                if (PRINT_SUCCESS) $display("%0t, '%s', Pass, %s[%0d], Expected, '%x', Result, '%x'", $time, NAME, `"ACTUAL`", i, EXPECTED[i], ACTUAL[i]); \
            end else begin \
                totalRfErrors += 1; \
                if (PRINT_ERRORS) $error("%0t, '%s', Fail, '%s[%0d]', Expected, '%x', Result, '%x', %b", $time, NAME, `"ACTUAL`", i, EXPECTED[i], ACTUAL[i], DUT.ROM_data); \
            end \
        end \
    end

module test_bench #(parameter N = 8, ROM_addressBits = 7, RF_addressBits = 3, NUMBER_OF_TESTS = 5000)();
    int totalTests = 0;
    int totalErrors = 0;
    int totalIterations = 0;
    int totalRfTests = 0;
    int totalRfErrors = 0;
    
    //microprocessor_n_memory
    logic clk, rst_n;
    logic overflowPC;
    
    logic [2**RF_addressBits-1:0] written_SRAM; //says if a cell of the SRAM has already been written by a load instruction or if it's never been accessed hence we need to randomize a value for this cell
    logic [N-1:0] RF_Ref [(2**RF_addressBits)-1:0];
    
    random_instructions #(N, ROM_addressBits, RF_addressBits) pck=new();
    
    microprocessor_n_memory #(N, ROM_addressBits, RF_addressBits) DUT(.*);
    
    ref_system #(N, ROM_addressBits, RF_addressBits) ref_dut(DUT.ROM_readEnable, rst_n, DUT.ROM_data, DUT.SRAM.SRAM_memory, RF_Ref);
    
    covergroup inst_cg (ref logic read_en, ref logic [3+2*(RF_addressBits):0] ROM_data) @(posedge read_en) ;
        OPs: coverpoint ROM_data[3+2*(RF_addressBits):2*(RF_addressBits)] {
            bins alu[] = {[0:6]};
            bins nop[] = {7};
            bins mem[] = {[8:9]};
            bins load_im[] = {10};
            bins brn[] = {[11:14]};
            illegal_bins invalid[] = {[15:$]};
        }
        OP_alu: coverpoint ROM_data[3+2*RF_addressBits:2*RF_addressBits] {bins alu[] = {[0:6]};}
        OP_nop: coverpoint ROM_data[3+2*RF_addressBits:2*RF_addressBits] {bins nop[] = {7};}
        OP_mem: coverpoint ROM_data[3+2*RF_addressBits:2*RF_addressBits] {bins mem[] = {[8:9]};}
        OP_load_im: coverpoint ROM_data[3+2*RF_addressBits:2*RF_addressBits] {bins load_im[] = {10};}
        OP_brn: coverpoint ROM_data[3+2*RF_addressBits:2*RF_addressBits] {bins brn[] = {[11:14]};}
        Data: coverpoint ROM_data[2*RF_addressBits - 1: 0];
        Instructions: cross OPs, Data;
        BRN_Offset: cross OP_brn, Data;
    endgroup
    
    inst_cg cg;
    always begin
        #5 clk = ~clk;
    end
    
    initial begin
        clk = 0;
        rst_n = 1;
        for(int i=0; i<2**RF_addressBits; i++)
            written_SRAM = 0;
        #5;
        rst_n = 0;
        #5;
        rst_n = 1;  
    end
    
    //check reset states
    initial begin
        @(posedge rst_n);
        //RF
        `test("RF not correctly reset", '1, DUT.CPU.rf.mem[1])
        for(int i=0; i<2**RF_addressBits; i++) begin
            if(i!=1)
                `test("RF not correctly reset", 0, DUT.CPU.rf.mem[i])
        end
        //FSM
        `test("FSM not correctly reset", 2'b11, DUT.CPU.fsm.state)
        //ALU
        `test("ALU not correctly reset", 0, DUT.CPU.alu.ONZ)
        `test("ALU not correctly reset", 0, DUT.CPU.alu.Result)
    end
    
    
    
    initial
    begin
        cg = new(DUT.ROM_readEnable, DUT.ROM_data);
        //generating instructions
        #1
        pck.randomize();
        DUT.ROM.ROM_memory = pck.ROM_data;
        
        forever begin
            @(posedge clk);
            if(DUT.ROM_data[3+2*(RF_addressBits):2*(RF_addressBits)] == 4'b1001) //STORE instruction
                written_SRAM[DUT.ROM_data[2*RF_addressBits: RF_addressBits]] = 1;
            if(DUT.ROM_data[3+2*(RF_addressBits):2*(RF_addressBits)] == 4'b1000 && written_SRAM[DUT.ROM_data[RF_addressBits-1:0]]==0) //LOAD instruction and that cell has never been accessed by a store function hence there is nothing in it so I randomize its value
                DUT.SRAM.SRAM_memory[DUT.ROM_data[RF_addressBits-1:0]] = $random;
    
            if(overflowPC || totalIterations >= NUMBER_OF_TESTS) begin
                $display("Finished Running Tests");
                $display("Total Iterations: %5d", totalIterations);
                
                $display("Total RF Checks:  %5d", totalRfTests);
                $display("Total RF Errors:  %5d", totalRfErrors);
                $display("Total Asserts:    %5d", totalTests);
                $display("Total Errors:     %5d", totalErrors);
                $display("__________________________");
                $display("OP Coverage:      %8.2f", cg.OPs.get_coverage());
                $display("  OP_alu          %8.2f", cg.OP_alu.get_coverage());
                $display("  OP_nop          %8.2f", cg.OP_nop.get_coverage());
                $display("  OP_mem          %8.2f", cg.OP_mem.get_coverage());
                $display("  OP_load_im      %8.2f", cg.OP_load_im.get_coverage());
                $display("  OP_brn          %8.2f", cg.OP_brn.get_coverage());
                $display("OP_brn + Offset   %8.2f", cg.BRN_Offset.get_coverage());
                $display("Total Coverage:   %8.2f", cg.Instructions.get_coverage());
                $finish;
            end
        end
    end


    // Control signals

    /*logic ROM_av;
    always_ff @(negedge clk) begin
        if (DUT.ROM_data === 'x) begin
            ROM_av <= 1;
        end else begin
            ROM_av <= 0;
        end
    end*/

    property rom_enable;
        DUT.ROM_readEnable until_with (DUT.CPU.fsm.state != 0);
    endproperty

    //test_con("ROM Read Enable error", 1, rom_enable, (property(@(posedge clk) rom_enable)))
    assert property(@(posedge clk) rom_enable) //$display("ENABLE OK %t", $time); 
        else $error("ROM Read Enable error @ %t", $time);

    initial begin
        @(posedge rst_n);

        forever begin
            @(negedge DUT.ROM_readEnable);
            `test_rf("RF - Ref Check",
                RF_Ref,
                DUT.CPU.rf.mem)
            @(negedge clk);
            case (DUT.ROM_data[3+2*(RF_addressBits):2*(RF_addressBits)])
                ADD, SUB, AND, OR, XOR: begin
                    `test("ALU - A operand selection failed",
                        DUT.ROM.ROM_memory[DUT.ROM_address][2*RF_addressBits-1:RF_addressBits],
                        DUT.CPU.RF_readAddressA)
                    `test("ALU - B operand selection failed",
                        DUT.ROM.ROM_memory[DUT.ROM_address][RF_addressBits-1:0],
                        DUT.CPU.RF_readAddressB)
                    `test("ALU - Failed to assert destination A",
                        0,
                        DUT.CPU.RF_selectDestA)
                    `test("ALU - Failed to assert destination B",
                        0,
                        DUT.CPU.RF_selectDestB)
                end
                MOV: begin
                    `test("MOV - A operand selection failed",
                        DUT.ROM.ROM_memory[DUT.ROM_address][2*RF_addressBits-1:RF_addressBits],
                        DUT.CPU.RF_readAddressA)
                    `test("MOV - B operand selection failed",
                        DUT.ROM.ROM_memory[DUT.ROM_address][RF_addressBits-1:0],
                        DUT.CPU.RF_readAddressB)
                    `test("MOV - Failed to assert destination A",
                        0,
                        DUT.CPU.RF_selectDestA)
                    `test("MOV - Failed to assert destination B",
                        0,
                        DUT.CPU.RF_selectDestB)
                end
                NOT: begin
                    `test("NOT - A operand selection failed",
                        1,
                        DUT.CPU.RF_readAddressA)
                    `test("NOT - B operand selection failed",
                        DUT.ROM.ROM_memory[DUT.ROM_address][RF_addressBits-1:0],
                        DUT.CPU.RF_readAddressB)
                    `test("NOT - Failed to assert destination A",
                        0,
                        DUT.CPU.RF_selectDestA)
                    `test("NOT - Failed to assert destination B",
                        0,
                        DUT.CPU.RF_selectDestB)
                end
                NOP: begin
                    `test("NOP - Asserted write_en",
                        0,
                        DUT.CPU.RF_writeEnable)
                    `test("NOP - Asserted SRAM_writeEnable",
                        0,
                        DUT.CPU.SRAM_writeEnable)
                    `test("NOP - Asserted SRAM_readEnable",
                        0,
                        DUT.CPU.SRAM_readEnable)
                end
                LOAD: begin
                    `test("LOAD - Address selection failed",
                        DUT.ROM.ROM_memory[DUT.ROM_address][RF_addressBits-1:0],
                        DUT.CPU.RF_readAddressB)
                    `test("LOAD - Failed to select A port destination",
                        1,
                        DUT.CPU.RF_selectDestA)
                    `test("LOAD - Failed to select B port destination",
                        1,
                        DUT.CPU.RF_selectDestB)
                    `test("LOAD - Failed to assert SRAM read enable",
                        1,
                        DUT.CPU.SRAM_readEnable)
                end
                STORE: begin
                    `test("STORE - Data selection failed",
                        DUT.ROM.ROM_memory[DUT.ROM_address][RF_addressBits-1:0],
                        DUT.CPU.RF_readAddressA)
                    `test("STORE - Data selection failed",
                        DUT.ROM.ROM_memory[DUT.ROM_address][2*RF_addressBits-1:RF_addressBits],
                        DUT.CPU.RF_readAddressB)
                    `test("STORE - Failed to assert destination A",
                        1,
                        DUT.CPU.RF_selectDestA)
                    `test("STORE - Failed to assert destination B",
                        1,
                        DUT.CPU.RF_selectDestB)
                    `test("STORE - Failed to assert SRAM write enable",
                        1,
                        DUT.CPU.SRAM_writeEnable)
                end
                LOAD_IM: begin
                    `test("LOAD_IM - Address selection failed",
                        DUT.ROM_data[2*RF_addressBits-1:RF_addressBits],
                        DUT.CPU.RF_writeAddress)
                    `test("LOAD_IM - Failed to assert RF write enable",
                        1,
                        DUT.CPU.RF_writeEnable)
                end
                BRN_Z, BRN_N, BRN_O, BRN: begin
                    `test("BRN - Failed to assert s_rst",
                        1,
                        DUT.CPU.ALU_rst)
                end
            endcase

            @(negedge clk);

            case (DUT.ROM_data[3+2*(RF_addressBits):2*(RF_addressBits)])
                NOP: begin
                    `test("NOP - Asserted write_en",
                        0,
                        DUT.CPU.RF_writeEnable)
                    `test("NOP - Asserted SRAM_writeEnable",
                        0,
                        DUT.CPU.SRAM_writeEnable)
                    `test("NOP - Asserted SRAM_readEnable",
                        0,
                        DUT.CPU.SRAM_readEnable)
                end
                ADD, SUB, AND, OR, XOR, MOV, NOT, LOAD: begin
                    `test("RWB - Write address incorrect",
                        DUT.ROM_data[2*RF_addressBits-1:RF_addressBits],
                        DUT.CPU.RF_writeAddress)
                    `test("RWB - Failed to assert write_en",
                        1,
                        DUT.CPU.RF_writeEnable)
                end
            endcase
            totalIterations += 1;
        end
    end
endmodule