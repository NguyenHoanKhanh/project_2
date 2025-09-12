`define ALU_WIDTH 14
`define ADD 0
`define SUB 1
`define SLT 2
`define SLTU 3
`define XOR 4
`define OR 5
`define AND 6
`define SLL 7
`define SRL 8
`define SRA 9
`define EQ 10
`define NEQ 11
`define GE 12
`define GEU 13

`define OPCODE_WIDTH 11
`define RTYPE 0 //Arithmetic operations between two registers
`define ITYPE 1 //Arithmetic operations between one register and immediate value
`define LOAD_WORD 2 //Retrieve data from memory to store in register (rs1 +imm)
`define STORE_WORD 3 //Retrieve data from register to store in memory (rs1 + imm)
`define BRANCH 4 //Branch instruction(pc = pc + 4)
`define JAL 5 //Calculate to jump and store value in target register (pc + imm) 
`define JALR 6 //Calculate target to jump (rs1 + imm)
`define LUI 7 //LUI expect (rd = imm, imm << 12) not rs1 + imm
`define AUIPC 8 //PC + imm is stored in rd 
`define SYSTEM 9 
`define FENCE 10

`define EXCEPTION_WIDTH 4
`define ILLEGAL 0
`define ECALL 1
`define EBREAK 2
`define MRET 3

`define OPCODE_RTYPE 7'b0110011 
`define OPCODE_ITYPE 7'b0010011
`define OPCODE_LOAD 7'b0000011
`define OPCODE_STORE 7'b0100011
`define OPCODE_BRANCH 7'b1100011
`define OPCODE_JAL 7'b1101111
`define OPCODE_JALR 7'b1100111
`define OPCODE_LUI 7'b0110111
`define OPCODE_AUIPC 7'b0010111
`define OPCODE_SYSTEM 7'b1110011
`define OPCODE_FENCE 7'b0001111

`define FUNCT3_ADD 3'b000
`define FUNCT3_SLL 3'b001
`define FUNCT3_SLT 3'b010 
`define FUNCT3_SLTU 3'b011
`define FUNCT3_XOR 3'b100
`define FUNCT3_OR 3'b110
`define FUNCT3_AND 3'b111
`define FUNCT3_SRA 3'b101
`define FUNCT3_EQ 3'b000
`define FUNCT3_NEQ 3'b001
`define FUNCT3_LT 3'b100
`define FUNCT3_GE 3'b101
`define FUNCT3_LTU 3'b110
`define FUNCT3_GEU 3'b111 

`define FUNCT_LB 3'b000 //char 8 bit
`define FUNCT_LH 3'b001 //short 16 bit  
`define FUNCT_LW 3'b010 //int 32 bit
`define FUNCT_LBU 3'b100 // char unsigned 8 bit
`define FUNCT_LHU 3'b101 // short unsigned 16 bit
`define FUNCT_SB 3'b000 //char 8 bit 
`define FUNCT_SH 3'b001 //short 16 bit
`define FUNCT_SW 3'b010 //int 32 bit

// Funct7 will decide the operation from the instruction and not based 
// on the instruction bits anymore
`define FUNCT7_ZERO 7'b0000000
`define FUNCT7_SUB 7'b0100000
`define FUNCT7_SLL 7'b0000000
`define FUNCT7_SLT 7'b0000000
`define FUNCT7_SLTU 7'b0000000
`define FUNCT7_XOR 7'b0000000
`define FUNCT7_SRL 7'b0000000
`define FUNCT7_SRA 7'b0100000
`define FUNCT7_OR 7'b0000000
`define FUNCT7_AND 7'b0000000