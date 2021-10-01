MEMORY
{
	PAGE 0:	VECS:	origin = 0xff80,	length = 0x80
			PROG:	origin = 0x2400,	length = 0x1a00
			
	PAGE 1:	SPRAM:	origin = 0x200,		length = 0x2200
			STACK:	origin = 0x0080,	length = 0x100
}

SECTIONS
{
	.vectors:	{}	>	VECS 	PAGE 0
	.text:		{}	>	PROG 	PAGE 0
	table_a:		>	PROG	PAGE 0
	.data			>	PROG	PAGE 0
	.bss:           >	SPRAM 	PAGE 1
	.stack:		{}	>	STACK 	PAGE 1
}


