`include "alu.v"
`include "reg_file.v"
`include "mem_module.v"
module cpu(PC, INSTRUCTION, CLK, RESET);
    input [31:0] INSTRUCTION;
    input CLK,RESET;
    output [31:0] PC;

    wire WRITEENABLE, ALUSRC, COMP, ZERO, BRANCH, ANDOUT, JUMP;
    wire [2:0] ALUOP;
    wire [7:0] REGOUT1, REGOUT2, ALURESULT, COMP2MUX, MUX2MUX, MUX2ALU, REG2COMP, IMMCOMP, MUX5OUT;
    wire [31:0] NEXTPC, TARGETOUT, JUMPADDRESS, MUX3OUT, MUX4OUT;
    wire WRITE, READ, BUSYWAIT, REGIN_SELECT;
    wire [7:0] READDATA, ADDRESS;
    wire [7:0] REGIN;

    cpu_mux MUX5(INSTRUCTION[7:0], IMMCOMP, COMP, MUX5OUT);
    twos_complement IMMCOMPLIMENT(INSTRUCTION[7:0], IMMCOMP);
    twos_complement COMPLIMENT(REGOUT2, REG2COMP);
    cpu_mux MUX1(REGOUT2, REG2COMP, COMP, MUX2MUX);  //2s compliment and regout2
    cpu_mux MUX2(MUX2MUX, MUX5OUT, ALUSRC, MUX2ALU); //Immediate value and regout2
    pc_adder PC_ADDER(RESET, PC, NEXTPC, BUSYWAIT);
    control_unit CU(INSTRUCTION[31:24], WRITEENABLE, ALUOP, ALUSRC, COMP, BRANCH, JUMP, READ, WRITE, BUSYWAIT, REGIN_SELECT);
    regfile REG_FILE(REGIN, REGOUT1, REGOUT2, INSTRUCTION[18:16], INSTRUCTION[10:8], INSTRUCTION[2:0], WRITEENABLE, CLK, RESET);
    alu ALU(REGOUT1, MUX2ALU, ALURESULT, ALUOP, ZERO);
    and_gate AND_GATE(BRANCH, ZERO, INSTRUCTION[27], ANDOUT);
    target_Adder TARGET_ADDER(INSTRUCTION[23:16], NEXTPC, TARGETOUT);
    cpu_32mux MUX3(NEXTPC, TARGETOUT, ANDOUT, MUX3OUT);
    cpu_32mux MUX4(MUX3OUT, JUMPADDRESS, JUMP, MUX4OUT);
    target_jump JUMPMODULE(NEXTPC, INSTRUCTION[23:16], JUMPADDRESS);
    program_counter PC_MODULE(PC, MUX4OUT, CLK);
    data_memory MEM_MODULE(CLK, RESET, READ, WRITE, ALURESULT, REGOUT1, READDATA, BUSYWAIT);
    cpu_mux MUX6(ALURESULT, READDATA, REGIN_SELECT, REGIN);
endmodule

module control_unit(OPCODE, WRITEENABLE, ALUOP, ALUSRC, REG2COMP, BRANCH, JUMP, READ, WRITE, BUSYWAIT, REGIN_SELECT);
    input [7:0] OPCODE;
    input BUSYWAIT;
    output reg [2:0] ALUOP;
    output reg ALUSRC, REG2COMP, WRITEENABLE, BRANCH, JUMP, READ, WRITE, REGIN_SELECT;
    initial begin
        BRANCH = 0;
        JUMP = 0;
        REG2COMP = 0;
    end
    always @(*) begin
        #1;
        case(OPCODE)
            //loadi
            8'b00000000:
                begin
                    ALUOP <= 3'b000;    // ALUOP - 000 for mov/loadi
                    WRITEENABLE <= 1'b1;    // need to write the value in the register
                    REG2COMP <= 1'b0;   // need immediate value without complementing it
                    ALUSRC <= 1'b1;    // 1 because we need to get the immediate value in the instruction
                    JUMP <= 1'b0;   // 0 because we don't need to jump
                    BRANCH <= 1'b0; // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'b0;
                end

            //mov
            8'b00000001:
                begin
                    ALUOP <= 3'b000;         // ALUOP - 000 for mov/loadi
                    WRITEENABLE <= 1'b1;      // need to write the value in the register
                    REG2COMP <= 1'b0; // need value in reg2 without complementing it
                    ALUSRC <= 1'b0;    // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;            // 0 because we don't need to jump
                    BRANCH <= 1'b0;          // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'b0;
                end

            //ADD
            8'b00000010:
                begin
                    ALUOP <= 3'b001;         // ALUOP - 001 for add/sub
                    WRITEENABLE <= 1'b1;      // need to write the value in the register
                    REG2COMP <= 1'b0; // need value in reg2 without complementing it
                    ALUSRC <= 1'b0;    // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;            // 0 because we don't need to jump
                    BRANCH <= 1'b0;          // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'b0;
                end

            //SUB
            8'b00000011:
                begin
                    ALUOP <= 3'b001;        // ALUOP - 001 for add/sub
                    WRITEENABLE <= 1'b1;    // need to write the value in the register
                    REG2COMP <= 1'b1;       // need value in reg2 with complementing it
                    ALUSRC <= 1'b0;         // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;           // 0 because we don't need to jump
                    BRANCH <= 1'b0;         // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'b0;
                end

            //AND
            8'b00000100:
                begin
                    ALUOP <= 3'b010;         // ALUOP - 010 for and
                    WRITEENABLE <= 1'b1;      // need to write the value in the register
                    REG2COMP <= 1'b0; // need value in reg2 without complement it
                    ALUSRC <= 1'b0;    // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;            // 0 because we don't need to jump
                    BRANCH <= 1'b0;          // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'b0;
                end

            //OR
            8'b00000101:
                begin
                    ALUOP <= 3'b011;         // ALUOP - 011 for or
                    WRITEENABLE <= 1'b1;      // need to write the value in the register
                    REG2COMP <= 1'b0; // need value in reg2 without complement it
                    ALUSRC <= 1'b0;    // 1 because we need to get the value in the register2
                    JUMP <= 1'b0;            // 0 because we don't need to jump
                    BRANCH <= 1'b0;          // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'b0;
                end

            //JUMP
            8'b00000110:
                begin
                    ALUOP <= 3'bxxx;         // ALUOP - xxx for jump
                    WRITEENABLE <= 1'b0;      // no value to write in the register
                    REG2COMP <= 1'b0; // don't need value any value
                    ALUSRC <= 1'b1;    // 0 because we need to get the value in the register2
                    JUMP <= 1'b1;            // 1 because we do need to jump
                    BRANCH <= 1'b0;          // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'bx;
                end

            //BEQ
            8'b00000111:
                begin
                    ALUOP <= 3'bxxx;         // ALUOP - xxx for brach - check if equal - zero flag
                    WRITEENABLE <= 1'b0;      // no value to write in the register
                    REG2COMP <= 1'b1; // need to complement the value in reg2
                    ALUSRC <= 1'b0;    // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;            // 0 because we don't need to jump
                    BRANCH <= 1'b1;          // 1 because we do need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'bx;
                end
            //MULT
            8'b00001000:
                begin
                    ALUOP <= 3'b100;         // ALUOP - 001 for brach - check if equal - zero flag
                    WRITEENABLE <= 1'b1;      // neet to write value to the register
                    REG2COMP <= 1'b0; // no need to complement the value in reg2
                    ALUSRC <= 1'b0;    // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;            // 0 because we don't need to jump
                    BRANCH <= 1'b0;          // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'bx;
                end
            //SHIFT LEFT
            8'b00001001:
                begin
                    ALUOP <= 3'b101;         // ALUOP - 001 for brach - check if equal - zero flag
                    WRITEENABLE <= 1'b1;      // neet to write value to the register
                    REG2COMP <= 1'b0; // no need to complement the value in reg2
                    ALUSRC <= 1'b1;    // 1 because we need to get the immediate value
                    JUMP <= 1'b0;            // 0 because we don't need to jump
                    BRANCH <= 1'b0;          // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'bx;
                end
            //SHIFT RIGHT
            8'b00001010:
                begin
                    ALUOP <= 3'b101;         // ALUOP - 001 for brach - check if equal - zero flag
                    WRITEENABLE <= 1'b1;      // neet to write value to the register
                    REG2COMP <= 1'b1; // need to complement immediate value
                    ALUSRC <= 1'b1;    // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;            // 0 because we don't need to jump
                    BRANCH <= 1'b0;          // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'bx;
                end
            //ARITHMETIC SHIFT RIGHT
            8'b00001011:
                begin
                    ALUOP <= 3'b110;        // ALUOP - 001 for brach - check if equal - zero flag
                    WRITEENABLE <= 1'b1;    // need to write value to the register
                    REG2COMP <= 1'b0;       // no need to complement the immediate value
                    ALUSRC <= 1'b1;         // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;           // 0 because we don't need to jump
                    BRANCH <= 1'b0;         // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'bx;
                end
            //ROTATE RIGHT
            8'b00001100:
                begin
                    ALUOP <= 3'b111;        // ALUOP - 111 for rotate
                    WRITEENABLE <= 1'b1;    // need to write value to the register
                    REG2COMP <= 1'b0;       // no need to complement the immediate value
                    ALUSRC <= 1'b1;         // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;           // 0 because we don't need to jump
                    BRANCH <= 1'b0;         // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'bx;
                end
            //BNE
            8'b00001101:
                begin
                    ALUOP <= 3'bxxx;        // ALUOP - xxx for branch - check if not equal - zero flag
                    WRITEENABLE <= 1'b0;    // no need to write value to the register
                    REG2COMP <= 1'b1;       // no need to complement the immediate value
                    ALUSRC <= 1'b0;         // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;           // 0 because we don't need to jump
                    BRANCH <= 1'b1;         // 1 because we need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'bx;
                end
            //lwd
            8'b00001110:
                begin
                    ALUOP <= 3'b000;        // ALUOP - Forward
                    WRITEENABLE <= 1'b1;    // need to write value to the register
                    REG2COMP <= 1'b0;       // no need to complement the immediate value
                    ALUSRC <= 1'b0;         // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;           // 0 because we don't need to jump
                    BRANCH <= 1'b0;         // 0 because we don't need to branch
                    READ <= 1'b1;
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'b1;
                end
            //lwi
            8'b00001111:
                begin
                    ALUOP <= 3'b000;        // ALUOP - Forward
                    WRITEENABLE <= 1'b1;    // need to write value to the register
                    REG2COMP <= 1'b0;       // no need to complement the immediate value
                    ALUSRC <= 1'b1;         // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;           // 0 because we don't need to jump
                    BRANCH <= 1'b0;         // 0 because we don't need to branch
                    READ <= 1'b1;
                    WRITE <= 1'b0;
                    REGIN_SELECT <= 1'b1;
                end
            //swd
            8'b00010000:
                begin
                    ALUOP <= 3'b000;        // ALUOP - xxx for branch - check if not equal - zero flag
                    WRITEENABLE <= 1'b0;    // no need to write value to the register
                    REG2COMP <= 1'b0;       // no need to complement the immediate value
                    ALUSRC <= 1'b0;         // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;           // 0 because we don't need to jump
                    BRANCH <= 1'b0;         // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b1;
                    REGIN_SELECT <= 1'bx;
                end
            //swi
            8'b00010001:
                begin
                    ALUOP <= 3'b000;        // ALUOP - xxx for branch - check if not equal - zero flag
                    WRITEENABLE <= 1'b0;    // no need to write value to the register
                    REG2COMP <= 1'b0;       // no need to complement the immediate value
                    ALUSRC <= 1'b1;         // 0 because we need to get the value in the register2
                    JUMP <= 1'b0;           // 0 because we don't need to jump
                    BRANCH <= 1'b0;         // 0 because we don't need to branch
                    READ <= 1'b0;   
                    WRITE <= 1'b1;
                    REGIN_SELECT <= 1'bx;
                end
        endcase
    end
endmodule

module cpu_mux(IN0, IN1, MUXSELECT, MUXOUT);
    input [7:0] IN0, IN1;
    input MUXSELECT;
    output reg [7:0] MUXOUT;

    always @(*)
    begin
        case(MUXSELECT)
            1: MUXOUT = IN1;
            0: MUXOUT = IN0;
        endcase
    end
endmodule

module cpu_32mux(IN0, IN1, MUXSELECT, MUXOUT);
    input [31:0] IN0, IN1;
    input MUXSELECT;
    output reg [31:0] MUXOUT;

    always @(*)
    begin
        case(MUXSELECT)
            1: MUXOUT = IN1;
            0: MUXOUT = IN0;
        endcase
    end
endmodule

module twos_complement(IN, OUT);
    input [7:0] IN;
    output [7:0] OUT;
    assign OUT = ~IN + 1;
endmodule

module pc_adder(RESET, CURRENTPC, NEXTPC, BUSYWAIT);
    input  RESET;
    input [31:0] CURRENTPC;
    input BUSYWAIT;
    output reg [31:0] NEXTPC;
    always @(*)
    begin
        case(RESET)
            1:NEXTPC= 0;
            0:
                case(BUSYWAIT)
                    1: NEXTPC = CURRENTPC;
                    0: NEXTPC = CURRENTPC+4;
                endcase
        endcase
    end
endmodule

module program_counter(CURRENTPC, NEWPC, CLK);
    input [31:0] NEWPC;
    input CLK;
    output reg [31:0] CURRENTPC;
    always @(posedge CLK)
        CURRENTPC = #1 NEWPC;
endmodule

module and_gate(IN1, IN2, IN3, OUT);
    input IN1, IN2, IN3;
    output OUT;
    assign OUT = (IN1 & ((IN2 & ~IN3) | (~IN2 & IN3))) ? 1 : 0;
endmodule

module target_Adder(IMM, NEXTPC, OUT);

    input signed [7:0] IMM;
    input [31:0] NEXTPC;
    output reg [31:0] OUT;
   
    reg [31:0] signExtended;
    reg [31:0] shifted;

    always @(IMM) 
    begin
        signExtended = { {24{IMM[7]}} , IMM[7:0]};
        shifted = signExtended << 2;
        #2 OUT = NEXTPC + shifted;
    end
endmodule

module target_jump(NEXTPC, IMM, JUMPADDRESS);
    input [31:0] NEXTPC;
    input [7:0] IMM;
    output reg [31:0] JUMPADDRESS;

    reg [31:0] signExtended;
    reg [31:0] shifted;

    always @(IMM) 
    begin
        signExtended = { {24{IMM[7]}} , IMM[7:0]};
        shifted = signExtended << 2;
        #2 JUMPADDRESS = NEXTPC + shifted;
    end
endmodule
