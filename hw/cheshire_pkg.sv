// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>

/// Contains the structs and configurations necessary for the Cheshire Platform
package cheshire_pkg;

  `include "axi/typedef.svh"
  `include "axi/assign.svh"
  `include "register_interface/typedef.svh"
  `include "apb/typedef.svh"

  /// Inputs of X-Bar
  typedef enum int {
    AXI_XBAR_IN_CVA6,
    AXI_XBAR_IN_DEBUG,
    AXI_XBAR_IN_DDR_LINK,
    AXI_XBAR_IN_VGA,
    AXI_XBAR_IN_DMA,
    AXI_XBAR_NUM_INPUTS
  } axi_xbar_inputs_e;

  /// Outputs of X-Bar
  typedef enum int {
    AXI_XBAR_OUT_DEBUG,
    AXI_XBAR_OUT_REGBUS,
    AXI_XBAR_OUT_DMA_CONF,
    AXI_XBAR_OUT_LLC,
    AXI_XBAR_OUT_DDR_LINK,
    AXI_XBAR_NUM_OUTPUTS
  } axi_xbar_outputs_e;

  /// Parameters for AXI types
  localparam int unsigned AXI_ADDR_WIDTH           = 48;
  localparam int unsigned AXI_DATA_WIDTH           = 64;
  localparam int unsigned AXI_USER_WIDTH           = 1;
  localparam int unsigned AXI_STRB_WIDTH           = AXI_DATA_WIDTH/8;  // Using byte strobes

  localparam int unsigned AXI_XBAR_MASTER_ID_WIDTH = 2;
  localparam int unsigned AXI_XBAR_SLAVE_ID_WIDTH  = AXI_XBAR_MASTER_ID_WIDTH + $clog2(AXI_XBAR_NUM_INPUTS); 

  localparam int unsigned AXI_XBAR_COMBS           = AXI_XBAR_NUM_INPUTS * AXI_XBAR_NUM_OUTPUTS;
  localparam logic [AXI_XBAR_COMBS-1:0] AXI_XBAR_CONNECTIVITY = {AXI_XBAR_COMBS{1'b1}};

  /// Configuration struct of X-Bar
  localparam axi_pkg::xbar_cfg_t axi_xbar_cfg = '{
    NoSlvPorts:         AXI_XBAR_NUM_INPUTS,
    NoMstPorts:         AXI_XBAR_NUM_OUTPUTS,
    MaxMstTrans:        12,
    MaxSlvTrans:        12,
    FallThrough:        0,
    LatencyMode:        axi_pkg::CUT_ALL_PORTS,
    PipelineStages:     1,
    AxiIdWidthSlvPorts: AXI_XBAR_MASTER_ID_WIDTH,
    AxiIdUsedSlvPorts:  AXI_XBAR_MASTER_ID_WIDTH,
    UniqueIds:          0,
    AxiAddrWidth:       48,
    AxiDataWidth:       64,
    NoAddrRules:        6
  };

  /// Address rule struct
  typedef struct packed {
    logic [31:0] idx;
    logic [47:0] start_addr;
    logic [47:0] end_addr;
  } address_rule_48_t;

  /// Address map of the AXI X-Bar
  /// NUM_OUTPUT rules + 1 additional for LLC (SPM and DRAM)
  localparam address_rule_48_t [AXI_XBAR_NUM_OUTPUTS:0] axi_xbar_addrmap = '{
    '{ idx: AXI_XBAR_OUT_DDR_LINK,      start_addr: 48'h100000000000, end_addr: 48'h200000000000},
    '{ idx: AXI_XBAR_OUT_LLC,           start_addr: 48'h000080000000, end_addr: 48'h000100000000},
    '{ idx: AXI_XBAR_OUT_LLC,           start_addr: 48'h000070000000, end_addr: 48'h000070020000},
    '{ idx: AXI_XBAR_OUT_DMA_CONF,      start_addr: 48'h000060000000, end_addr: 48'h000060001000},
    '{ idx: AXI_XBAR_OUT_REGBUS,        start_addr: 48'h000001000000, end_addr: 48'h000060000000},
    '{ idx: AXI_XBAR_OUT_DEBUG,         start_addr: 48'h000000000000, end_addr: 48'h000000001000}
  };

  /// Inputs of the Regbus Demux
  typedef enum int {
    REGBUS_IN_XBAR,
    REGBUS_NUM_INPUTS
  } regbus_inputs_e;

  /// Outputs of the Regbus Demux
  typedef enum int {
    REGBUS_OUT_BOOTROM,
    REGBUS_OUT_CSR,
    REGBUS_OUT_LLC,
    REGBUS_OUT_DDR_LINK,
    REGBUS_OUT_UART,
    REGBUS_OUT_I2C,
    REGBUS_OUT_SPIM,
    REGBUS_OUT_VGA,
    REGBUS_OUT_CLINT,
    REGBUS_OUT_PLIC,
    REGBUS_OUT_EXTERNAL,
    REGBUS_NUM_OUTPUTS
  } regbus_outputs_e;

  /// Address map of the Regbus Demux
  localparam address_rule_48_t [REGBUS_NUM_OUTPUTS-1:0] regbus_addrmap = '{
    '{ idx: REGBUS_OUT_EXTERNAL, start_addr: 48'h10000000, end_addr: 48'h60000000 },  // EXTERNAL  - 1.25 GiB
    '{ idx: REGBUS_OUT_PLIC,     start_addr: 48'h0c000000, end_addr: 48'h10000000 },  // PLIC      -   64 MiB 
    '{ idx: REGBUS_OUT_CLINT,    start_addr: 48'h04000000, end_addr: 48'h04100000 },  // CLINT     -    1 MiB
    '{ idx: REGBUS_OUT_VGA,      start_addr: 48'h02006000, end_addr: 48'h02007000 },  // VGA       -    4 KiB
    '{ idx: REGBUS_OUT_SPIM,     start_addr: 48'h02005000, end_addr: 48'h02006000 },  // SPIM      -    4 KiB
    '{ idx: REGBUS_OUT_I2C,      start_addr: 48'h02004000, end_addr: 48'h02005000 },  // I2C       -    4 KiB
    '{ idx: REGBUS_OUT_UART,     start_addr: 48'h02003000, end_addr: 48'h02004000 },  // UART      -    4 KiB
    '{ idx: REGBUS_OUT_DDR_LINK, start_addr: 48'h02002000, end_addr: 48'h02003000 },  // DDR Link  -    4 KiB
    '{ idx: REGBUS_OUT_LLC,      start_addr: 48'h02001000, end_addr: 48'h02002000 },  // LLC       -    4 KiB
    '{ idx: REGBUS_OUT_CSR,      start_addr: 48'h02000000, end_addr: 48'h02001000 },  // CSR       -    4 KiB
    '{ idx: REGBUS_OUT_BOOTROM,  start_addr: 48'h01000000, end_addr: 48'h01020000 }   // Bootrom   -  128 KiB
  };

  /// Type definitions
  ///
  /// Register bus with 48 bit address and 32 bit data
  `REG_BUS_TYPEDEF_ALL(reg_a48_d32, logic [47:0], logic [31:0], logic [3:0])

  /// Register bus with 48 bit address and 64 bit data
  `REG_BUS_TYPEDEF_ALL(reg_a48_d64, logic [47:0], logic [63:0], logic [7:0])

  /// AXI bus with 48 bit address and 64 bit data
  `AXI_TYPEDEF_ALL(axi_a48_d64_mst_u0, logic [47:0], logic [AXI_XBAR_MASTER_ID_WIDTH-1:0], logic [63:0], logic [7:0], logic [0:0])
  `AXI_TYPEDEF_ALL(axi_a48_d64_slv_u0, logic [47:0], logic [AXI_XBAR_SLAVE_ID_WIDTH-1:0], logic [63:0], logic [7:0], logic [0:0])
  
  /// Same AXI bus with 48 bit address and 64 bit data but with CVA6s 4 bit ID
  `AXI_TYPEDEF_ALL(axi_cva6, logic [47:0], logic [3:0], logic [63:0], logic [7:0], logic [0:0])

  /// AXI bus for LLC (one additional ID bit)
  `AXI_TYPEDEF_ALL(axi_a48_d64_mst_u0_llc, logic [47:0], logic [AXI_XBAR_SLAVE_ID_WIDTH:0], logic [63:0], logic [7:0], logic [0:0])
  
  /// AXI bus with 48 bit address and 32 bit data
  `AXI_TYPEDEF_ALL(axi_a48_d32_slv_u0, logic [47:0], logic [AXI_XBAR_SLAVE_ID_WIDTH-1:0], logic [31:0], logic [3:0], logic [0:0])

  /// Identifier used for user-signal based ATOPs by CVA6
  localparam logic [0:0] CVA6_IDENTIFIER = 1'b1;

  /// CVA6 Configuration struct
  localparam ariane_pkg::ariane_cfg_t CheshireArianeConfig = '{
    /// Default config
    RASDepth: 2,
    BTBEntries: 32,
    BHTEntries: 128,
    /// Non idempotent regions
    NrNonIdempotentRules: 1,
    NonIdempotentAddrBase: { 
        64'h0100_0000
    },
    // Everything up until the SPM is assumed non idempotent
    NonIdempotentLength: {
        64'h6F00_0000
    },
    /// DRAM, SPM, Boot ROM, Debug Module
    NrExecuteRegionRules: 4,
    ExecuteRegionAddrBase: {
        64'h8000_0000, 64'h7000_0000, 64'h0100_0000, 64'h0
    },
    ExecuteRegionLength: {
        64'h8000_0000, 64'h0002_0000, 64'h0002_0000, 64'h1000
    },
    /// Cached regions: DRAM, Upper half of SPM
    NrCachedRegionRules: 2,
    CachedRegionAddrBase: {
        64'h8000_0000, 64'h7001_0000
    },
    CachedRegionLength: {
        64'h8000_0000, 64'h0001_0000
    },
    Axi64BitCompliant: 1'b1,
    SwapEndianess: 1'b0,
    /// Debug
    DmBaseAddress: 64'h0,
    NrPMPEntries: 0
  };

  /// Interrupts
  typedef struct packed {
    logic uart;
    logic spim_spi_event;
    logic spim_error;
    logic i2c_host_timeout;
    logic i2c_ack_stop;
    logic i2c_acq_overflow;
    logic i2c_tx_overflow;
    logic i2c_tx_nonempty;
    logic i2c_tx_empty;
    logic i2c_trans_complete;
    logic i2c_sda_unstable;
    logic i2c_stretch_timeout;
    logic i2c_sda_interference;
    logic i2c_scl_interference;
    logic i2c_nak;
    logic i2c_rx_overflow;
    logic i2c_fmt_overflow;
    logic i2c_rx_watermark;
    logic i2c_fmt_watermark;
    logic zero;
  } cheshire_interrupt_t;

  /// Debug Module parameter
  localparam logic [15:0] PartNum = 1012;
  localparam logic [31:0] IDCode = (dm::DbgVersion013 << 28) | (PartNum << 12) | 32'h1;

  /// Testbench start adresses
  localparam SPM_BASE = axi_xbar_addrmap[AXI_XBAR_OUT_LLC].start_addr;
  localparam SCRATCH_REGS_BASE = regbus_addrmap[REGBUS_OUT_CSR].start_addr;

  /// Cheshire Config
  /// Can be used to exclude parts of the system
  typedef struct packed {
    bit UART;
    bit SPI;
    bit I2C;
    bit DMA;
    bit DDR_LINK;
    bit DRAM;
    bit VGA;
    /// Width of the VGA red channel, ignored if VGA set to 0
    logic [31:0] VGARedWidth;
    /// Width of the VGA green channel, ignored if VGA set to 0
    logic [31:0] VGAGreenWidth;
    /// Width of the VGA blue channel, ignored if VGA set to 0
    logic [31:0] VGABlueWidth;
    /// The Clock frequency after coming out of reset
    logic [31:0] ResetFreq;
  } cheshire_cfg_t;

  /// Default FPGA config for Cheshire Platform
  localparam cheshire_cfg_t CheshireCfgFPGADefault = '{
    UART: 1'b1,
    SPI: 1'b1,
    I2C: 1'b1,
    DMA: 1'b1,
    DDR_LINK: 1'b0,
    DRAM: 1'b1,
    VGA: 1'b1,
    VGARedWidth: 32'd5,
    VGAGreenWidth: 32'd6,
    VGABlueWidth: 32'd5,
    ResetFreq: 32'd50000000
  };

  /// Default ASIC config for Cheshire Platform
  localparam cheshire_cfg_t CheshireCfgASICDefault = '{
    UART: 1'b1,
    SPI: 1'b1,
    I2C: 1'b1,
    DMA: 1'b1,
    DDR_LINK: 1'b1,
    DRAM: 1'b1,
    VGA: 1'b1,
    VGARedWidth: 32'd2,
    VGAGreenWidth: 32'd3,
    VGABlueWidth: 32'd3,
    ResetFreq: 32'd200000000
  };

endpackage