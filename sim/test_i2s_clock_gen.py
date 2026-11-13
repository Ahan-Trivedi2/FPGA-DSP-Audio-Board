import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_clock_gen(dut):
    Clock(dut.clk, 81.38, unit="ns")
    cocotb.start_soon(dut.clk.start())
    dut.rst.value = 1
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0
    await FallingEdge(dut.clk)
    dut.rst.value = 0
