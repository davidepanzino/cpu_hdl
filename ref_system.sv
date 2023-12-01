module ref_system #(
  parameter N               = 8,
  parameter ROM_addressBits = 6,
  parameter RF_addressBits  = 3
) (
  input  logic clk, rst_n,
  input  logic [3+2*(RF_addressBits):0] ROM_data,
  input  logic [N-1:0] SRAM_data [(2**N)-1:0],
  output logic [N-1:0] RF_Ref [(2**RF_addressBits)-1:0]
);

logic [N-1:0] RF [(2**RF_addressBits)-1:0];
assign RF_Ref = RF;

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        for(int i = 0; i < 2**RF_addressBits; i++) begin
            if (i == 1) begin
                RF[i] <= -1;
            end else begin
                RF[i] <= 0;
            end
        end
    end else begin
        logic [3:0] inst;
        logic [RF_addressBits-1:0] ra, rb;
        {inst, ra, rb} = ROM_data;
        case (inst)
            ADD: RF[ra] <= RF[ra] + RF[rb];
            SUB: RF[ra] <= RF[ra] - RF[rb];
            AND: RF[ra] <= RF[ra] & RF[rb];
            OR:  RF[ra] <= RF[ra] | RF[rb];
            XOR: RF[ra] <= RF[ra] ^ RF[rb];
            NOT: RF[ra] <= ~ RF[rb];
            MOV: RF[ra] <= RF[rb];
            LOAD: begin
                //$display ("rb %0x, rf %0x, ram %0x, %b", SRAM_data[RF[rb]], RF[rb], rb, ROM_data);
                RF[ra] <= SRAM_data[RF[rb]];
            end
            LOAD_IM: RF[ra] <= signed'(rb);
            STORE, NOP, BRN_Z, BRN_N, BRN_O, BRN:;
            default: begin
                if ($isunknown(inst)) begin
                end else begin
                    $error("Invalid OP for ref system %4b", inst);
                end
            end
        endcase
    end
end

endmodule