// Group 11
// David Ramón Alamán
// Davide Finazzi
// Jonathan Lundström
// Register File for Lab 2
module RF  #(parameter N = 8, parameter addressBits = 2) ( 
    /* --------------------------------- Inputs --------------------------------- */
    input logic clk,
    input logic rst_n,
    input logic selectDestinationA,
    input logic selectDestinationB,
    
    input logic [1:0] selectSource,
    input logic [addressBits-1:0] writeAddress,
    input logic write_en,
    input logic [addressBits-1:0] readAddressA,
    input logic [addressBits-1:0] readAddressB,

    input logic [N-1:0] A, 
    input logic [N-1:0] B, 
    input logic [N-1:0] C, 
    /* --------------------------------- Outputs -------------------------------- */
    output logic [N-1:0] destination1A,
    output logic [N-1:0] destination2A,
    output logic [N-1:0] destination1B,
    output logic [N-1:0] destination2B
);
    logic [N-1:0] mem [(2**addressBits)-1:0];
    logic [N-1:0] sourceData;
    logic [N-1:0] readA, readB;
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            for(int i = 0; i < 2**addressBits; i++) begin
                if (i == 1) begin
                    mem[i] <= -1;
                end else begin
                    mem[i] <= 0;
                end
            end
        end else begin
            for(int i = 0; i < 2**addressBits; i++) begin
                if(write_en && writeAddress == i) begin
                    mem[i] <= sourceData;
                end
            end
        end
    end
    
    always_comb begin
        // Source Select Mux
        case (selectSource)
            2'b00: sourceData = A;
            2'b01: sourceData = B;
            2'b10: sourceData = C;
            default: sourceData = 0;
        endcase

        //Read Address Mux
        readA = 0;
        readB = 0;
        for(int i = 0; i < 2**addressBits; i++) begin
            if(readAddressA == i) begin
                readA = mem[i];
            end
            if(readAddressB == i) begin
                readB = mem[i];
            end
        end

        if(selectDestinationA) begin
            destination1A = 0;
            destination2A = readA;
        end else begin
            destination1A = readA;
            destination2A = 0;
        end
        if(selectDestinationB) begin
            destination1B = 0;
            destination2B = readB;
        end else begin
            destination1B = readB;
            destination2B = 0;
        end

    end

endmodule