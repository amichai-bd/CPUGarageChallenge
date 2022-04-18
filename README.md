# CPUGarageChallenge
Intel CPU Garage Challenge
Desigin a CPU compatible with the "hack" ISA.  
For more information regarding the specification see https://www.nand2tetris.org/

## Key Featrues
4 Stage Pipe line
Treating the DataMem as "register file" due to the support of A, M, D registers-Register operations. (M - is the the Memory register)
Fetching 20 instructions per cycle - able to excecute up to 10 instruction.
The 20 insturciton is due to the "delay" of a cycle of updating the PC - This way the next 10 instruction are available Back2Back.
Option to accelerate copmutation using HW Devider.
![image](https://user-images.githubusercontent.com/79047032/160799765-5a025648-9aa0-4e2b-9d32-aa07504cf9ef.png)


## Simulation
Using modelsim (vlog & vsim commands) to simulate & test the design.  
The source files (same files for FPGA)  ``` FPGA_CPUGarage/sv/* ```  
Using Deticated files for simulation: (memory, TB, defines)  ``` source/* ```  
Generated trackers on memory access used for debug  ``` modelsim/reference_log/*  , modelsim/trk_d_mem_access.log ```  
Reference model - Starting point - golden solution from Design  ``` original_reference/* ```  

## FPGA
Open the qpf gui file: ``` FPGA_CPUGarage/FPGA_CPUGarage.qpf ```  

## Expected Results:  
![WhatsApp Image 2022-04-10 at 1 20 59 PM](https://user-images.githubusercontent.com/81047407/162614144-98dbe61f-8140-4e1b-a03d-fe7e120ceb8f.jpeg)
