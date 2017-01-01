PONG
====

Implementation of the pong game without software.
https://en.wikipedia.org/wiki/Pong

-----

Use _LOGISIM_ (https://sourceforge.net/projects/circuit/files/latest/download) to play with it.
Start the clock and use the buttons UP/DOWN to move each paddle.

Possibility to run it on a FPGA by setting the input buttons and the LED screen.

The ball always starts at the same place.
Points are not displayed. Just remember the score!

----

Pong written in _NIOS II assembly code_
Runs on RISC processor implemented on FPGA supporting the instructions written in the PDF.

Big file +600lines (can be broken into multiple one)

The parameters should be generic and the game can be run on different screens if those settings are changed accordingly.

This has been developed to run on a _FPGA4U_ (https://fpga4u.epfl.ch/wiki/Main_Page)
The code can be simulated using _nios2sim.jar_
