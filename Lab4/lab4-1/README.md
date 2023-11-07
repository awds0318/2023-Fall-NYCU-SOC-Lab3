## Simulation for FIR
```sh
cd ~/caravel-soc_fpga-lab/lab-exmem-fir/testbench/counter_la_fir
./run_clean
./run_sim
```

## Setup Toolchain
Get presetup Vitis Virtual Machine from course TA or setup following toolchains yourself.
* Ubuntu 20.04+ and Xilinx Vitis [HLS tools installation guide](https://github.com/bol-edu/course-lab_1/blob/2022.1/HLS%20Tools%20Installation%20Guide%202022.1_ubuntu.md)
* GTKWave and RISC-V GCC Toolchains
* iverilog & vvp
```bash
sudo apt update
sudo apt install gtkwave git -y
sudo wget -O /tmp/riscv32-unknown-elf.gcc-12.1.0.tar.gz https://github.com/stnolting/riscv-gcc-prebuilt/releases/download/rv32i-4.0.0/riscv32-unknown-elf.gcc-12.1.0.tar.gz
sudo mkdir /opt/riscv
sudo tar -xzf /tmp/riscv32-unknown-elf.gcc-12.1.0.tar.gz -C /opt/riscv
echo 'export PATH=$PATH:/opt/riscv/bin' >> ~/.bashrc
source ~/.bashrc

sudo apt-get install iverilog
```