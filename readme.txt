Microcoding is an efficient way of designing complex digital circuits. It is driving many historic and contemporary CPUs and controllers. However, it is underutilized by electronic hobby community due to lack of tooling and design patterns and practices. As my main interest is retrocomputing, running into microcode was unavoidable, and soon I realized that developing a microcode compiler would popularize this design methodology, and make designs using it more mantainable and extensible than the usual FSM designs. 

The "MCC" microcode compiler written in C# converts a program comprised of symbolic microinstructions and few "macros" into 2 memory blocks:

- "mapper" that maps higher level CPU instructions into start points of microcode routines
- "microcode" that describes steps in executing a higher level instruction

In addition, MCC will generate a templatized microcode controller / sequencer circuit. These 3 taken together can comprise 50% of the total code needed for a CPU for example, and it addition will drive the rest of the design towards standard multiplexer/register pattern.

MCC compiler can be easily integrated into FPGA toolchain - the only new file type being the .mcc source code, all the others are standard .hex, .bin, .cgf .coe, .mif files. Non-FPGA based implementations can use it too, for example generated files can be burned into (E)EPROMs, and the templatized sequencer can be built with 10 or so 74XX TTL ICs. In addition MCC supports limited memory file conversion mode too, which can come handy working with any embedded CPU/MCU design.

To make sure it all works end to end, and to document it with working examples, I validated the MCC by creating 2 microcoded designs:

- CDP1802 compatible CPU (1805 functionality partially implemented to show ease of extensibility)
- Teletype to video memory controller

To make sure it all works, I integrated them into a simple computer system (very much similar to Cosmac ELF) that is able to run 1802 monitor and Basic.

Both the compiler and the designs to validate it are readily available on github, and documented to some extent in project logs. Time permitting, I plan to continue developing it, but above all I am looking forward to feedback and collaboration from this community. 

