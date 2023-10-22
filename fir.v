`timescale 1ns / 1ps
module fir
       #(  parameter pADDR_WIDTH = 12,
           parameter pDATA_WIDTH = 32,
           parameter Tape_Num    = 11
        )
       (
           output  wire                     awready,
           output  wire                     wready,
           input   wire                     awvalid,
           input   wire [(pADDR_WIDTH-1):0] awaddr,
           input   wire                     wvalid,
           input   wire [(pDATA_WIDTH-1):0] wdata,
           output  wire                     arready,
           input   wire                     rready,
           input   wire                     arvalid,
           input   wire [(pADDR_WIDTH-1):0] araddr,
           output  wire                     rvalid,
           output  wire [(pDATA_WIDTH-1):0] rdata,
           input   wire                     ss_tvalid,
           input   wire [(pDATA_WIDTH-1):0] ss_tdata,
           input   wire                     ss_tlast,
           output  wire                     ss_tready,
           input   wire                     sm_tready,
           output  wire                     sm_tvalid,
           output  wire [(pDATA_WIDTH-1):0] sm_tdata,
           output  wire                     sm_tlast,

           // bram for tap RAM
           output  wire [3:0]               tap_WE,
           output  wire                     tap_EN,
           output  wire [(pDATA_WIDTH-1):0] tap_Di,
           output  wire [(pADDR_WIDTH-1):0] tap_A,
           input   wire [(pDATA_WIDTH-1):0] tap_Do,

           // bram for data RAM
           output  wire [3:0]               data_WE,
           output  wire                     data_EN,
           output  wire [(pDATA_WIDTH-1):0] data_Di,
           output  wire [(pADDR_WIDTH-1):0] data_A,
           input   wire [(pDATA_WIDTH-1):0] data_Do,

           input   wire                     axis_clk,
           input   wire                     axis_rst_n
       );
//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
parameter    AXIL_IDLE       = 'd0;
parameter    AXIL_RADDR      = 'd1;
parameter    AXIL_RDATA      = 'd2;
parameter    AXIL_WADDR      = 'd3;
parameter    AXIL_WDATA      = 'd4;
reg  [2:0]   AXIL_cs, AXIL_ns;

parameter    AXIS_IDLE       = 'd0;
parameter    AXIS_FIRST      = 'd1;
parameter    AXIS_COMPUTE  = 'd2;
parameter    AXIS_OUTPUT     = 'd3;
reg  [1:0]   AXIS_cs, AXIS_ns;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
reg  [31:0]  ap;
reg  [31:0]  data_length;

reg  [3:0]  fir_compute_count;
reg  [3:0]  first_data_index;
wire [3:0]  data_index;
reg         ss_tready_reg, sm_tvalid_reg;
reg         data_reset_done;
reg         last_output;
reg  signed  [31:0]  accumulate;

assign  tap_EN = 1;
assign  tap_WE = (AXIL_cs == AXIL_WDATA && awaddr >= 32'h0020)? 4'b1111 : 0;
assign  tap_Di = wdata;
assign  tap_A  = (AXIL_cs == AXIL_WDATA && AXIS_cs == AXIS_IDLE)? awaddr - 32'h0020 : (AXIL_cs == AXIL_RADDR && AXIS_cs == AXIS_IDLE)? araddr - 32'h0020 : (fir_compute_count << 2);

assign  data_EN = 1;
assign  data_WE = (AXIS_cs == AXIS_IDLE || AXIS_cs == AXIS_FIRST)? 4'b1111:0;
assign  data_Di = (AXIS_cs == AXIS_IDLE)? 0 : ss_tdata;  // reset to 0 when AXIS_cs == `AXIS_IDLE
assign  data_A  = (AXIS_cs == AXIS_COMPUTE)? (data_index << 2) : (first_data_index <<2 );

assign  ss_tready  = ss_tready_reg;
assign  sm_tvalid  = sm_tvalid_reg;
assign  sm_tdata   = accumulate;
assign  sm_tlast   = last_output;
assign  data_index = (first_data_index >= fir_compute_count)? (first_data_index - fir_compute_count) : 11 - (fir_compute_count - first_data_index);

//---------------------------------------------------------------------
//   AXI_Lite
//---------------------------------------------------------------------
assign  arready = (AXIL_cs == AXIL_RADDR)? 1 : 0; // AR
assign  awready = (AXIL_cs == AXIL_WADDR)? 1 : 0; // AW
assign  rdata   = (AXIL_cs == AXIL_RDATA)? (araddr == 32'h0000)? ap : (araddr == 32'h00010)? data_length : (araddr >= 32'h0020)? tap_Do : 0 : 0; // R
assign  rvalid  = (AXIL_cs == AXIL_RDATA)? 1 : 0; // R
assign  wready  = (AXIL_cs == AXIL_WDATA)? 1 : 0; // W

//---------------------------------------------------------------------
//   Your DESIGN
//---------------------------------------------------------------------
always @(posedge axis_clk or negedge axis_rst_n)
begin
    if(!axis_rst_n)
        AXIL_cs <= AXIL_IDLE;
    else
        AXIL_cs <= AXIL_ns;
end

always@(*)
begin
    case(AXIL_cs)
        AXIL_IDLE:
            AXIL_ns = (arvalid)? AXIL_RADDR : (awvalid)? AXIL_WADDR : AXIL_IDLE;
        AXIL_RADDR:
            AXIL_ns = (arvalid && arready)? AXIL_RDATA : AXIL_RADDR;
        AXIL_RDATA:
            AXIL_ns = (rready && rvalid)? AXIL_IDLE : AXIL_RDATA;
        AXIL_WADDR:
            AXIL_ns = (awvalid && awready)? AXIL_WDATA : AXIL_WADDR;
        AXIL_WDATA:
            AXIL_ns = (wready && wvalid)? AXIL_IDLE : AXIL_WDATA;
        default:
            AXIL_ns = AXIL_IDLE;
    endcase
end

always @(posedge axis_clk)
begin
    if (!axis_rst_n)
    begin
        ap <= 32'h0000_0004;  // ap[2:0] = 'b100
        data_length <= 0;
    end
    else
    begin
        if (AXIL_cs == AXIL_WDATA)
        begin
            if (awaddr == 32'h0000)
            begin
                ap <= wdata;
            end
            else if(awaddr == 32'h0010)
            begin
                data_length <= wdata;
            end
        end
        else if (AXIL_cs == AXIL_RDATA)
        begin
            ap[1] <= (awaddr == 32'h0000)? 0 : ap[1];  // reset ap_done when address 0x00 is read
        end
        else
        begin
            ap[0] <= (ap[0] == 0)? 0 : (AXIS_cs == AXIS_IDLE)? 1 : 0;  // ap_start, reset when start AXI_stream data transfer
            ap[1] <= (ap[1] == 1)? 1 : (last_output == 1 && AXIS_cs == AXIS_OUTPUT)? 1 : 0;  // ap_done
            ap[2] <= (ap[2] == 1)? (ap[0] == 1)? 0 : 1 : (ss_tlast == 1 && AXIS_cs == AXIS_IDLE)? 1 : 0;  // ap_idle
        end
    end
end

//---------------------------------------------------------------------
//   AXI_Stream
//---------------------------------------------------------------------
always @(posedge axis_clk or negedge axis_rst_n)
begin
    if(!axis_rst_n)
        AXIS_cs <= AXIS_IDLE;
    else
        AXIS_cs <= AXIS_ns;
end

always@(*)
begin
    case(AXIS_cs)
        AXIS_IDLE:
            AXIS_ns = (ap[0] == 1)? AXIS_FIRST : AXIS_IDLE;
        AXIS_FIRST:
            AXIS_ns = AXIS_COMPUTE;
        AXIS_COMPUTE:
            AXIS_ns = (fir_compute_count == 11)? AXIS_OUTPUT : AXIS_COMPUTE;
        AXIS_OUTPUT:
            AXIS_ns = (last_output == 1)? AXIS_IDLE : AXIS_FIRST;
        default:
            AXIS_ns = AXIS_IDLE;
    endcase
end

always@(posedge axis_clk or negedge axis_rst_n)
begin
    if (!axis_rst_n)
    begin
        last_output <= 0;
        data_reset_done <= 0;
        ss_tready_reg <= 0;
        sm_tvalid_reg <= 0;
        first_data_index <= 0;
        fir_compute_count <= 0;
        accumulate <= 0;
    end
    else
    begin
        if (AXIS_cs == AXIS_IDLE)
        begin
            ss_tready_reg <= 0;
            sm_tvalid_reg <= 0;
            first_data_index <= data_reset_done? 0 : first_data_index + 1;
            data_reset_done <= (data_reset_done == 1)? 1 : (first_data_index==10)? 1 : 0;
        end
        else if (AXIS_cs == AXIS_FIRST)
        begin
            ss_tready_reg <= 1;
            sm_tvalid_reg <= 0;
            fir_compute_count <= 1;
        end
        else if (AXIS_cs == AXIS_COMPUTE)
        begin
            ss_tready_reg <= 0;
            sm_tvalid_reg <= (fir_compute_count == 11)? 1 : 0;
            fir_compute_count <= (fir_compute_count == 11)? 0 : fir_compute_count + 1;
            accumulate <= accumulate + $signed(tap_Do) * $signed(data_Do);
        end
        else if (AXIS_cs == AXIS_OUTPUT)
        begin
            ss_tready_reg <= 0;
            sm_tvalid_reg <= 0;
            first_data_index <= (first_data_index == 10)? 0 : first_data_index + 1;
            accumulate <= 0;
            last_output <= (ss_tlast == 1)? 1 : 0;
        end
    end
end
endmodule
