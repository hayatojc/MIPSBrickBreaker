# MIPSBrickBreaker

Host Application is MARS.
This program requires the Keyboard and Display MMIO          
and the Bitmap Display to be connected to MIPS.              

1. Open the program in MARS.
2. Run -> Assemble
3. Tools -> Bitmap Display:				     
        Bitmap Display Settings:                                     
	Unit Width: 8						     
	Unit Height: 8						     
	Display Width: 512					     
	Display Height: 512					     
	Base Address for Display: 0x10008000 ($gp)
Click connect to Mips
4. Tools -> Keyboard and Display MMIO Simulator
	the "a" key moves left and the "d" key moves right
Click connect to Mips
5.Run

ENJOY! This is a multi leveled game. Try to win
