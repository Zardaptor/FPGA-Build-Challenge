@echo off
set VIVADO_BIN=C:\AMDDesignTools\2026.1\Vivado\bin
call "%VIVADO_BIN%\xvlog.bat" -sv Experiment-5-Advanced\RTL\*.v Experiment-5-Advanced\RTL\pipeline\*.v Experiment-5-Advanced\Testbench\tb_rv32i_pipeline.v > sim_log.txt 2>&1
call "%VIVADO_BIN%\xelab.bat" -debug typical -top tb_rv32i_pipeline -snapshot tb_snap >> sim_log.txt 2>&1
call "%VIVADO_BIN%\xsim.bat" tb_snap -R >> sim_log.txt 2>&1
echo DONE >> sim_log.txt
