// Group 11
// David Ramón Alamán
// Davide Finazzi
// Jonathan Lundström
// ALU logic to other operations


module ALU  #(parameter N = 8) (
    input logic clk, arstn, rst, en,
    input logic [2:0] OP, 
    input logic signed [N-1:0] A, 
    input logic signed [N-1:0] B, 
    /* --------------------------------- Outputs -------------------------------- */
    output logic  [2:0] ONZ,
    output logic signed [N-1:0] Result 
);
// Add your ALU description here
logic [2:0] temp_ONZ;
logic signed [N-1:0] temp_result;

always_comb begin
    logic Overflow;
    case (OP)
        3'b000: begin // Add
            {Overflow, temp_result} = A + B;
            temp_ONZ[2] = Overflow ^ temp_result[N-1];
            temp_ONZ[1] = temp_result[N-1];
            temp_ONZ[0] = &(~temp_result);
        end
        3'b001: begin // Sub
            {Overflow, temp_result} = A - B;
            temp_ONZ[2] = Overflow ^ temp_result[N-1];
            temp_ONZ[1] = temp_result[N-1];
            temp_ONZ[0] = &(~temp_result);
        end
        3'b010: begin // And
            temp_result = A & B;
            temp_ONZ[2] = 0;
            temp_ONZ[1] = temp_result[N-1];
            temp_ONZ[0] = &(~temp_result);
        end
        3'b011: begin // Or
            temp_result = A | B;
            temp_ONZ[2] = 0;
            temp_ONZ[1] = temp_result[N-1];
            temp_ONZ[0] = &(~temp_result);
        end
        3'b100 : begin //Xor
            temp_result = A ^ B;
            temp_ONZ[2] = 0;
            temp_ONZ[1] = temp_result[N-1];
            temp_ONZ[0] = &(~temp_result);
            end
        3'b101 : begin //Inc
            {Overflow, temp_result} = A + 1;
            temp_ONZ[2] = Overflow ^ temp_result[N-1];
            temp_ONZ[1] = temp_result[N-1];
            temp_ONZ[0] = &(~temp_result);
            end
        3'b110 : begin //MovA
            temp_result = A;
            temp_ONZ[2] = 0;
            temp_ONZ[1] = temp_result[N-1];
            temp_ONZ[0] = &(~temp_result);      
            end
        3'b111 : begin //MovB
            temp_result = B;
            temp_ONZ[2] = 0;
            temp_ONZ[1] = temp_result[N-1];
            temp_ONZ[0] = &(~temp_result);
            end
        default: begin
            temp_ONZ = 3'h0;
            temp_result = 0;
        end
    endcase
end

/* ------------ Output register ------------- */

always_ff @(posedge clk or negedge arstn) begin
    if (!arstn) begin
        Result <= 0;
    end
    else begin
        Result <= temp_result;
    end
end

/* ------------ ONZ register ------------- */

always_ff @(posedge clk or negedge arstn) begin
    if (!arstn | rst) begin
        ONZ <= 0;
    end 
    else if (en) begin
        ONZ <= temp_ONZ;
    end
end

endmodule
