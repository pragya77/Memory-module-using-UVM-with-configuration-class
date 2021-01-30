# Memory-module-using-UVM-with-configuration-class
In this project, I created a memory DUT and then to verify its functionality, used UVM and created testbench, interface, test, environment, agent, monitor, driver, sequencer, scoreboard components and sequence and sequence item objects. Used clocking block to synchronize monitor and driver, constraints, assertions and covergroups for complete verification. Added a configuration class for better reusability.
If reset is set, register is set with a pre-defined value otherwise the data from a particular address is either read or data is written to a particular address. The expected data is compared with the actual data in the scoreboard.
Simulated the code and observed the accuracy of the functionality on eda playground using Synopsys VCS.
