***定时20ms循环处理话音数据包***
*
*
*********************************
			.title	"IS95前向信道设计"
			.global	_c_int00
			.mmregs	
			.copy		"walsh.inc"		;从"walsh.inc" 文件中复制walsh表
STACK		.usect		"stack",10H		;堆栈的设置
			.bss		pn1,2048
			.bss		pn2,2048
			.bss		w,1536
			.bss		wa,1536
			.bss		iq,32			;依次存储4组8个样点波形
										;SIN0+COS0;SIN0+COS180;SIN180+COS0;SIN180+COS180	
			.bss		p,4				;P用于42级缓存三个,用于Wlash地址是4个
			.bss		q,4				;P用于42级掩码三个,用于Wlash地址是4个
			.bss		v,1				;用于记录pn码循环的位置0-2047
			.bss  		k,1				;k为偏置系数
			.bss		x,1		
			.bss		y,1
			.bss		z,1	
			.data
cos:		.word		07fffH,05a82H,00000H,0a57fH,08002H,0a57fH,00000H,05A82H	
sin:		.word		00000H,05A82H,07fffH,05a82H,00000H,0a57fH,08002H,0a57fH	
PA0			.set		0	
PA1			.set		1				;速率标志1，2，4，8
PA2			.set		2	
PA3			.set		3
PA4			.set		4
PA5			.set		5
PA6			.set		6
PA7			.set		7
PA8			.set		8
PA9			.set		9				;输出调制波形
			.sect	".vectors"			;中断向量表
rst:		B		_c_int00			;0号复位中断
			NOP
			NOP
			.space	15*4*16				;空1-15号中断
int0:		B		clock				;16号外部中断,GPS中断
			NOP
			NOP
			.space	2*4*16				;空17-18中断
tint:		B		timeout				;定时中断向量19
			NOP
			NOP
			.space	12*4*16				;空20-31中断
			.text 						;主程序
_c_int00
			STM		#STACK+10,SP  				;置堆栈指针
************************************************************
*初始化,产生四种SIN与COS相加的波形
*cos+sin;cos-sin;sin-cos;-cos-sin
************************************************************	
			SSBX	SXM					;=1符号扩展
			LD		#cos,A
			STM		#w,AR2				;立即数寻址,
			STM		#wa,AR3
			RPT		#7
			READA	*AR2+				;间接寻址,w中存8个cos样点
			LD		#sin,A
			RPT		#7
			READA	*AR3+				;wa中存8个sin样点
			STM		#iq,AR4
			STM		#w,AR2
			STM		#wa,AR3
			STM		#7,BRC
			RPTB	ttt-1	
			LD		*AR2+,A
			ADD		*AR3+,A
			STL		A,*AR4+				;*(iq)=cos0+sin0
ttt:		STM		#w,AR2
			STM		#wa,AR3
			STM		#7,BRC
			RPTB	ttt1-1	
			LD		*AR2+,A
			SUB		*AR3+,A
			STL		A,*AR4+				;*(iq+8)=cos0+sin180
ttt1:		STM		#w,AR2
			STM		#wa,AR3
			STM		#7,BRC
			RPTB	ttt2-1	
			LD		*AR3+,A
			SUB		*AR2+,A				;*(iq+16)=cos180+sin0
			STL		A,*AR4+	
ttt2:		STM		#w,AR2
			STM		#wa,AR3
			STM		#7,BRC
			RPTB	ttt3-1	
			LD		*AR2+,A
			NEG		A
			SUB		*AR3+,A
			STL		A,*AR4+				;*(iq+24)=cos180+sin180

xulie1		STM		#32766,BRC			;32767
			LD		#0x0001,A			;1在X1位(低位)是本周期的头
			STM		#15,AR4				;15-0记数器
			STM		#pn1,AR3			;
			ST		#0x0001,*AR3		;先输出一个1
			RPTB	PP-1				;
			LD		#0,B				;清零
			XOR		A,-4,B				;X5
			XOR		A,-6,B				;X7
			XOR		A,-7,B				;X8
			XOR		A,-8,B				;X9
			XOR		A,-12,B				;X13
			XOR		A,-14,B				;X15
			AND		#0x0001,B			;得反馈位
			SFTL	A,1					;A左移1位
			OR		B,A					;B送给A
			BANZ	PP1,*AR4-			;AR4不是0,跳转PP1,AR4-1(数组没记满)
			STL		B,*+AR3				;
			STM		#15,AR4				;
			B		PP2					;
PP1:		ADD		*AR3,1,B			;
			STL		B,*AR3				;
PP2:		NOP							;
PP:			LD		*AR3,A				;
			AND		#0xFFFE,A			;把最后一位改为零
			STL		A,*AR3				;
xulie2		STM		#32766,BRC			;32767
			LD		#0x0001,A			;1在X1位(低位)是本周期的头
			STM		#15,AR4				;15-0记数器
			STM		#pn2,AR3			;
			ST		#0x0001,*AR3		;先输出一个1
			RPTB	PP-1				;
			LD		#0,B				;清零
			XOR		A,-2,B				;X3
			XOR		A,-3,B				;X4
			XOR		A,-4,B				;X5
			XOR		A,-5,B				;X6
			XOR		A,-9,B				;X10
			XOR		A,-10,B				;X11
			XOR		A,-11,B				;X12
			XOR		A,-14,B				;X15
			AND		#0x0001,B			;得反馈位
			SFTL	A,1					;A左移1位
			OR		B,A					;B送给A
			BANZ	PP1,*AR4-			;AR4不是0,跳转PP1,AR4-1(数组没记满)
			STL		B,*+AR3				;
			STM		#15,AR4				;
			B		PP2					;
PPPP1:		ADD		*AR3,1,B			;
			STL		B,*AR3				;
PPPP2:		NOP							;
PPPP:		LD		*AR3,A				;
			AND		#0xFFFE,A			;把最后一位改为零
			STL		A,*AR3				;
*************************************************************
ttt3:		SSBX	INTM				;=1,关闭所有可屏蔽中断
			RSBX	SXM                 ;=0禁止符号位扩展
			ST		#0,*(x)				;初始化x=0,x为十次定时记数
			STM		#0,SWWSR			;插入0等待周期
			STM		#0xffa8,PMST		;改变中断向量映射到0xff80
			STM		#9007h,CLKMD		;PLLMUL=9,CLKIN=10M,CLKOUT=CLKIN X (PLLMUL+1)=100M

			STM		#19999,PRD				;该为PRD=20000-1;TDDR=10-1 主频100M 则定时2ms
			STM 	#0039h,TCR
			
***********************************************************
*使各种速率均变换成相同的调制码元速率,即19.2KB/S,每20MS有384个码元,以便实施统一的分组交织;
***********************************************************
susp		STM		#y,AR4				;把地址Y赋给AR4;添加帧质量指示
			PORTR	PA1,*AR4			;从端口1读一个速率标志赋给变量Y;速率标志1，2，4，8(人为定义速率标志)
			BIT		*AR4,15-0			;测试变量Y的第15位(右一位);这一位为1代表速率1;为1,则TC=1;为0,则TC=0;
			BC		bbb1,NTC			;TC=0条件满足,跳转到bbb1;TC=1条件不满足,执行下一条语句;BC是条件满足时跳转;NTC是TC=0;
			CALL	crc12				;调用子程序crc12;!!!!!!!(在crc12后面补00000000)八个;
			LD		#191,A				;循环次数A192次(72+12+8);
			CALL	juanji				;调用卷积码;
			STM		#wa,AR5				;码元重复1次,wa输出;								为什么数据没有变,还有没有必要搬移一遍?
		    STM		#w,AR3				;w输入;开始码元重组;								答:因为模块化编程,必须要搬一次.
		    RPT		#383				;
			MVDD	*AR3+,*AR5+			;AR3数据搬移到AR5;AR3,AR5地址都+1;
			CALL	jiaozhi				;交织
			CALL	raoluan				;加密
			CALL	kuopin				;扩频
			CALL	pianzhi1			;编织1
			CALL	pianzhi2			;编织2
			CALL	qpsk				;
			B       bbb					;无条件跳转到bbb;													四个支路都有相同的调用,可不可以删掉,在最后加调用?
bbb1:		BIT		*AR4,15-1			;测试变量Y的第14位(右2位);这一位为1代表速率2;为1,则TC=1;为0,则TC=0;答:可以;
			BC		bbb2,NTC			;条件跳转;
			CALL	crc8				;调用;
			LD		#95,A				;循环次数88+8=96;
			CALL	juanji				;
			STM		#wa,AR5				;码元重复2次,wa输出
		    STM		#w,AR3				;w输入
			STM		#191,BRC			;
			RPTB	ccb1-1				;
			MVDD	*AR3,*AR5+			;第一次输入搬移输出
			MVDD	*AR3+,*AR5+			;第二次输入搬移输出(码元重复一次)
			B		bbb					;跳转到bbb;
bbb2:		BIT		*AR4,15-2			;速率4
			BC		bbb3,NTC			;
			STM		#w,AR3				;
		    STM		#wa,AR4				;
		    RPT		#39					;?????????????????????????????????????????????????
		    MVDD	*AR3+,*AR4+			;
		    LD		#47,A				;
		    CALL	juanji				;
		    STM		#wa,AR5				;码元重复4次,wa输出w输入
		    STM		#w,AR3				;
		    STM		#95,BRC				;
			RPTB	ccb2-1				;
			MVDD	*AR3,*AR5+			;
			MVDD	*AR3,*AR5+			;
			MVDD	*AR3,*AR5+			;
			MVDD	*AR3+,*AR5+			;
			B		bbb					;
bbb3:		STM		#w,AR3				;速率8
		    STM		#wa,AR4				;
		    RPT		#15					;数据搬移;是因为1/4和1/8没有CRC校验;模块化编程,没有CRC校验程序,仍然要把数据从输入搬到输出;
		    MVDD	*AR3+,*AR4+			;
		    LD		#23,A				;15+00000000
		    CALL	juanji				;
		    STM		#wa,AR5				;码元重复8次,wa输出w输入
		    STM		#w,AR3				;
		    STM		#47,BRC				;下面的程序快循环48次(48比特);
			RPTB	ccc-1				;
			MVDD	*AR3,*AR5+			;
			MVDD	*AR3,*AR5+			;
			MVDD	*AR3,*AR5+			;
			MVDD	*AR3,*AR5+			;
			MVDD	*AR3,*AR5+			;
			MVDD	*AR3,*AR5+			;
			MVDD	*AR3,*AR5+			;
			MVDD	*AR3+,*AR5+			;
bbb:		CALL	jiaozhi				;交织
			CALL	raoluan				;加密
			CALL	kuopin				;扩频
			CALL	pianzhi1			;编织1
			CALL	pianzhi2			;编织2
			CALL	qpsk				;
			nop							;
*********************************************************************
*记数器,等20MS,程序等待,定不到20毫秒,
*********************************************************************		
susp1		LD		*(x),A				;
			BC		susp,AEQ			;X=10的时候条件跳转;判断是否到20ms,取第二个数据包处理  
			B 		susp1				;无条件跳转;
*********************************************************************		
timeout 	ADDM 	#1,*(x)				;X+1;定时中断子程序1加到十即20ms;功能是 每到2毫秒,X加1
			LD 		#10,A				;10赋给A			
        	SUB 	*(x),A				;A-X=A
        	BC 		secout,ALEQ			;条件A累加器小于等于零跳转
        	B 		exit				;
secout		ST 		#0,*(x)				;X清零,
exit		NOP
       		RETE
*********************************************************************		
*外部GPS时钟2秒钟复位一次
*根据偏置系数K确定引导序列的起始位置v
*********************************************************************
clock:		PORTR	PA0,*(k)				;读偏置系数,绝对寻址
			LD		*(k),2,A				;K左移两位(相邻偏置系数差64位,从K*4开始),放A里面
			AND		#0x7fc,A				;9个1,2个0,K最大511(9位)
			STL		A,*(v)					;起始位置,V是偏移量
			STM		#0FFFFh,IFR             ;所有中断标志置1
			STM 	#0008h,IMR				;TINT0=1定时中断开放
			RSBX 	INTM					;=0,开放所有可屏蔽中断
			LDM		TCR,A					;
			AND 	#0FFEFH,A				;
			STLM	A,TCR					;TSS=0,定时器启动工作
			RETE							;
********************************************************************
*CRC效验子程序
*12位帧质量指示码产生器
*w存储172位要效验的信息
*wa存储184位输出信息
*f(x)=x12+x11+x10+x9+x8+x4+x+1		
*********************************************************************
crc12		STM		#w,AR3				;产生反馈位,整体移位,有抽头的位置再相加.
		    STM		#wa,AR4				;
		    LD		#0XFFF,B			;B为12位移存器初始化,右为刚入,左为最早入
		 	STM		#171,BRC			;计算172位CRC效验
		 	RPTB	next-1				;快循环到,循环172次
			SFTL	B,-11,A				;取最高延迟位(在左边);B累加器右移动11位,取最高延迟位到A里面去
			MVDD	*AR3,*AR4+			;数据由w->wa;数据搬移;输入地址还要和多项式相加产生反馈位
			XOR		*AR3+,A				;最高延迟位与输入模2加产生反馈输入;异或,模2加,此时A累加器中存的是反馈位
			AND		#0X0001,A			;相与,使A累加器中只剩下最右边一位,即反馈位	
			SFTL	B,1					;移存器移位,左移
			AND		#0X0FFE,B			;相与,最后一位清零
			XOR		A,11,B				;产生移存器的X12,异或(11就是12)
			XOR		A,10,B				;产生移存器的X11
			XOR		A,9,B				;产生移存器的X10
			XOR		A,8,B				;产生移存器的X9
			XOR		A,7,B				;产生移存器的X8
			XOR		A,3,B				;产生移存器的X4
			XOR		A,B					;产生移存器的X(输出了172位信息位,缺12位校验位)
next:		NOP							;将存在累加器A中的校验12位码传递到信息位的最后12个字
			SFTL	B,-11,A				;取B最高延迟位(对应的是校验位最低位)到A里面去
			AND		#0X0001,A			;
			STL		A,*AR4+				;输出
			SFTL	B,-10,A				;次高位
			AND		#0X0001,A			;
			STL		A,*AR4+				;输出
			SFTL	B,-9,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-8,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-7,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-6,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-5,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-4,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-3,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-2,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-2,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			AND		#0X0001,B			;
			STL		B,*AR4+				;
			RET							;
***********************************************************************************
*crc效验：F（X）=X8+X7+X4+X3+X+1
*8位帧质量指示码产生器
*w存储80位要效验的信息
*wa存储88位输出信息
***********************************************************************************
crc8		STM		#w,AR3				;W输入
		    STM		#wa,AR4				;WA输出
		   	LD		#0XFF,B				;B为8位移存器初始化,右为刚入,左为最早入
		 	STM		#79,BRC				;计算80位CRC效验
		 	RPTB	nex-1				;
			SFTL	B,-7,A				;取最高延迟位
			MVDD	*AR3,*AR4+			;数据由w->wa
			XOR		*AR3+,A				;最高延迟位与输入模2加产生反馈输入
			AND		#0X0001,A			;
			SFTL	B,1					;移存器移位
			AND		#0X0FE,B			;
			XOR		A,7,B				;产生移存器的X8
			XOR		A,6,B				;产生移存器的X7
			XOR		A,3,B				;产生移存器的X4
			XOR		A,2,B				;产生移存器的X3
			XOR		A,B					;产生移存器的X
nex:		NOP							;将存在累加器A中的校验8位码传递到信息位的最后8个字
			SFTL	B,-7,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-6,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-5,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-4,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-3,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-2,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			SFTL	B,-2,A				;
			AND		#0X0001,A			;
			STL		A,*AR4+				;
			AND		#0X0001,B			;
			STL		B,*AR4+				;
			RET							;
**********************************************************************************
*卷积编码g0=111101011(抽头)
*        g1=101110001
*wa为输入数据，w为编码输出
*包括8位尾比特处理
*卷积码是信道编码,它是纠随机错误的;提高信道的抗干扰能力;码率是1/2,约束度为9,加尾比特是8bit,为了让译码从零状态开始;(2,1,9)
**********************************************************************************
juanji		STLM	A,BRC				;把A中的值赋给BRE;循环次数184,88,40,16;累加器A事先赋好了卷积码要编码的比特位数192-1,96-1;47;23;在主程序中赋值
			STM		#wa,AR2				;WA输入,WA数组首地址赋给AR2
			STM		#w,AR3				;W输出,W数组首地址赋给AR3
			LD		#0,B				;清零;B累加器做移存器,只用最左边的8位
			RPTB	ddd-1				;快循环到DDD-1;
			LD		*AR2,A				;把AR2中的输入信息送到A累加器
			XOR		B,A					;B和A异或的值放在A累加器;输入信息和X1相加
			XOR		B,-1,A				;再和X2相加;问为什么B和A没有+1?只有在产生C0,C1之后才+1@@@@@@
			XOR		B,-2,A				;再和X3相加
			XOR		B,-4,A				;再和X5相加
			XOR		B,-6,A				;再和X7相加
			XOR		B,-7,A				;再和X8相加
			AND		#0X0001,A			;A累加器;
			STL		A,*AR3+				;A的值赋给AR3;AR3地址+1;到此产生的是C0
			LD		*AR2,A				;把AR2中的输入信息送到A累加器;
			XOR		B,-1,A				;A和X2相加
			XOR		B,-2,A				;再和X3相加
			XOR		B,-3,A				;再和X4相加
			XOR		B,-7,A				;再和X8相加
			AND		#0X0001,A			;A累加器+1;
			STL		A,*AR3+				;A的值赋给AR3;AR3地址+1;到此产生的是C1
			SFTL	B,1					;B左移一位
			AND		#0XFE,B				;
			OR		*AR2+,B				;或;把输入信息填入B累加器左1位;输入信息+1
ddd:		NOP							;改法:取掉第二个循环,且第一个循环次数+8,并在输入信息后面+00000000(8个)
			STM		#7,BRC				;循环8次;是因为尾比特8个零;
			RPTB	eee-1				;
			LD		#0,A				;输入信息改为0;
			XOR		B,A					;
			XOR		B,-1,A				;
			XOR		B,-2,A				;
			XOR		B,-4,A				;
			XOR		B,-6,A				;
			XOR		B,-7,A				;
			AND		#0X0001,A			;
			STL		A,*AR3+				;
			LD		#0,A				;
			XOR		B,-1,A				;
			XOR		B,-2,A				;
			XOR		B,-3,A				;
			XOR		B,-7,A				;
			AND		#0X0001,A			;
			STL		A,*AR3+				;
			SFTL	B,1					;
eee:		NOP							;
			RET							;
*************************************************************************
*IS-95分组正向业务信道交织器														卷积码是信道编码器,纠随机错误,无法纠突发性错误,移动信道是突发性错误,
*将384码元分成6个64码元组,先对每个64分组进行64位码倒序寻址,再进行6X64矩阵交织		交织编码器是为了把突发性错误打散成随机性错误.
*输入数据在wa中，中间倒序寻址数据在w中,最后数据仍在wa中
*************************************************************************			
jiaozhi		STM		#wa,AR2				;交织前的数据
			STM		#w,AR3				;交织后的数据
			STM		#32,AR0				;64/2=32
			STM		#64-1,BRC			;循环64次(有64列)
			RPTB		#jj1-1			;
			MVDD   		 *AR2,*AR3+		;输入地址不变,输出地址+1
			MAR		*AR2+0B				;(双操作数不支持+0B)单支持				完成第一行64比特反转寻址交织
jj1:			STM		#wa+64,AR2		;输入地址+64位地址
			RPTB		#jj2-1			;
			MVDD    	*AR2,*AR3+		;
			MAR		*AR2+0B				;				完成第二行64比特反转寻址交织
jj2:			STM		#wa+2*64,AR2	;
			RPTB		#jj3-1			;
			MVDD    	*AR2,*AR3+		;
			MAR		*AR2+0B				;				完成第三行64比特反转寻址交织	
jj3:			STM		#wa+3*64,AR2	;
			RPTB		#jj4-1			;
			MVDD    	*AR2,*AR3+		;
			MAR		*AR2+0B				;				完成第四行64比特反转寻址交织
jj4:			STM		#wa+4*64,AR2	;
			RPTB		#jj5-1			;
			MVDD    	*AR2,*AR3+		;
			MAR		*AR2+0B				;				完成第五行64比特反转寻址交织
jj5: 			STM		#wa+5*64,AR2	;
			RPTB		#jj6-1			;
			MVDD    	*AR2,*AR3+		;
			MAR		*AR2+0B				;				完成第六行64比特反转寻址交织
jj6:			STM		#wa,AR2			;
			STM		#w,AR3				;
			STM		#64-1,BRC			;循环64次(有64列)
			STM		#64,AR0				;上下列之间差64位
			RPTB	jjj1-1				;
			MVDD	*AR3,*AR2+			;(双操作数不支持+0)单支持				1
			MAR		*AR3+0				;+AR0的意思,输入地址加64
			MVDD	*AR3,*AR2+			;输入搬输出								2
			MAR		*AR3+0				;
			MVDD	*AR3,*AR2+			;										3
			MAR		*AR3+0				;
			MVDD	*AR3,*AR2+			;										4
			MAR		*AR3+0				;
			MVDD	*AR3,*AR2+			;										5
			MAR		*AR3+0				;
			MVDD	*AR3,*AR2+			;										6
			LDM		AR3,A				;AR3里的值送给A累加器
			SUB		#(5*64)-1,A			;地址从前一列最后一位跳到后一列第一位(-1就是+1)
			STLM	A,AR3				;AR3里的值送给A累加器
jjj1:		RET							;
*************************************************************************
*扰乱加密P(x)=x42+x35+x33+x31																;信息安全,保护客户隐私
*             +x27+x26+x25+x22+x21+x19+x18+x17+x16											;
*             +x10+x7+x6+x5+x3+x2+x+1														;
*加扰之前的数据在wa中，加扰后数据在w中,p,p+1与p+2中分别放移存器低14位中14位和高14位
*q,q+1与q+2中分别放掩码标志码低14位中14位和高14位
*************************************************************************		
raoluan 	STM		#wa,AR4				;输入
		    STM		#w,AR5				;输出
		    STM		#383,AR3			;循环384次(加密384个码元)
		    PORTR	PA2,*(p)			;读移存器M序列(42位)的初始状态;获得移存器初态低14位
		    LD		*(p),A				;绝对寻址,A读取了16位;
		    AND		#0X3fff,A			;相与;取A的右14位
		    STL		A,*(p)				;
		    PORTR	PA3,*(p+1)			;								获得移存器初态中14位
		    LD		*(p+1),A			;
		    AND		#0X3fff,A			;
		    STL		A,*(p+1)			;
		   PORTR	PA4,*(p+2)			;								获得移存器初态高14位
		    LD		*(p+2),A			;
		    AND		#0X3fff,A			;
		    STL		A,*(p+2)			;
		    PORTR	PA5,*(q)			;							获得掩码标志码低14位(掩码也是42位)
		    LD		*(q),A				;
		    AND		#0X3fff,A			;
		    STL		A,*(q)				;
		    PORTR	PA6,*(q+1)			;							获得掩码标志码中14位
		    LD		*(q+1),A			;
		    AND		#0X3fff,A			;
		    STL		A,*(q+1)			;
		   PORTR	PA7,*(q+2)			;							获得掩码标志码高14位
		    LD		*(q+2),A			;
		    AND		#0X3fff,A			;
		    STL		A,*(q+2)			;
bbc:		STM		#63,BRC				;下面这一级产生反馈位				64分频器
			RPTB	bbc1-1				;
			LD		#0,B				;B累加器清零;(B反馈位)(A移存位)
		    LD		*(p),A				;低14位给A
		    XOR		A,B       			;异或给B	X1		X
		    XOR		A,-1,B				;右移		X2
		    XOR		A,-2,B				;			X3
		    XOR		A,-4,B				;			X5
		    XOR		A,-5,B				;			X6
		    XOR		A,-6,B				;			X7
		    XOR		A,-9,B				;			X10				
		    LD		*(p+1),A			;
		    XOR		A,-1,B				;X16
		    XOR		A,-2,B				;X17
		    XOR		A,-3,B				;X18
		    XOR		A,-4,B				;X19
		    XOR		A,-6,B				;X21
		    XOR		A,-7,B				;X22
		    XOR		A,-10,B				;X25
		    XOR		A,-11,B				;X26
		    XOR		A,-12,B				;X27
			LD		*(p+2),A			;
			XOR		A,-2,B				;X31
			XOR		A,-4,B				;X33
			XOR		A,-6,B				;X35
			XOR		A,-13,B				;X42
			AND		#0X0001,B			;新产生的1位反馈位,将存入B中
			LD		*(p+1),-13,A		;42级移位
			AND		#0X0001,A			;
			ADD		*(p+2),1,A			;中14位给高1位
			AND		#0X03FF,A			;14个一
			STL		A,*(p+2)			;得高14位
			LD		*(p),-13,A			;低14位给中1位
			AND		#0X0001,A			;
			ADD		*(p+1),1,A			;
			AND		#0X03FF,A			;
			STL		A,*(p+1)			;得中14位
			LD		*(p),1,A			;左移一位
			XOR		B,A					;和反馈位异或
			AND		#0X03FF,A			;
			STL		A,*(p)				;得低14位
bbc1:		NOP							;
			LD		#0,B				;						掩码与移存器状态相与再模二加产生1BIT输出位
			LD		*(p),A				;
			AND		*(q),A				;低14位P和Q相与
			STM		#13,BRC				;循环14次
			RPTB	bbc2-1				;
			XOR		A,B					;与后的14为相模二加
			SFTL	A,-1				;
bbc2:		LD		*(p+1),A			;中
			AND		*(q+1),A			;
			STM		#13,BRC				;
			RPTB	bbc3-1				;
			XOR		A,B					;
			SFTL	A,-1				;
bbc3:		LD		*(p+2),A			;高
			AND		*(q+2),A			;
			STM		#13,BRC				;
			RPTB	bbc4-1				;
			XOR		A,B					;
			SFTL	A,-1				;
bbc4:		AND		#0X0001,B			;
            STL		B,*AR4				;密钥 和 信息 相加
		    MVDD	*AR4+,*AR5+			;输出
bbc6:		BANZ	bbc,*AR3-			;判断AR3里的值;是零,往下走;不是零,减1并跳转			;不可以用快循环(RBITB),因为快循环不可以嵌套;
			RET							;
*********************************************************************************
**输入是加扰后的19.2b/s的数据存在W中384比特											1-7寻呼,32同步,0,业务;
*WALSH码表存在文件table.inc中，4个字一个64位W码，存在程序区
*PA8口输入W地址号
*扩频后数据存在wa中，384*4=1536
*
*********************************************************************************
kuopin		STM		#p,AR4				;*(p)中是4个64位Walsh地址码
		    PORTR	PA8,*(z)			;从端口8获得W地址号放变量Z中
		    LD		*(z),2,A			;Z是WALSH号乘4,给A
		    AND		#0xfc,A				;
		    STL		A,*(z)				;
		    ADD		#table_a,A			;A:64位WALSH号
		    STM		#3,BRC
		    RPTB	KP11-1					;
		    READA	*AR4+				;累加器寻址;程序区内容放数据区
			ADD		#1,A				;A+1
KP11:	    STM		#p,AR4				;						p中是64位正码(0)		信息(0,1)和WALSH码加
		    STM		#q,AR5				;						q中是64位反码(1)
		    LD		*AR4+,A				;P给A
		    CMPL	A					;A取反
		    STL		A,*AR5+				;反码
			LD		*AR4+,A				;
		    CMPL	A					;
		    STL		A,*AR5+				;
			LD		*AR4+,A				;
		    CMPL	A					;
		    STL		A,*AR5+				;
		    LD		*AR4+,A				;
		    CMPL	A					;
		    STL		A,*AR5+				;
		    STM		#wa,AR3				;输出
		    STM		#w,AR7				;输入
		    STM		#383,BRC			;信息位384
		    RPTB	LOOP-1				;
		    LD		*AR7+,A				;
		    STM		#p,AR4				;1
		    STM		#q,AR5				;0
		    BC		LOOP1,ANEQ			;判断,A累加器不等于零的时候跳转		循环不能放外面
		    MVDD	*AR4+,*AR3+			;0;输出P							
		  	MVDD	*AR4+,*AR3+			;
		  	MVDD	*AR4+,*AR3+			;
		  	MVDD	*AR4+,*AR3+			;
		    B       LOOP-1				;
LOOP1:		MVDD	*AR5+,*AR3+			;1;输出Q
		   	MVDD	*AR5+,*AR3+			;
			MVDD	*AR5+,*AR3+			;
		   	MVDD	*AR5+,*AR3+			;
		   	NOP							;
LOOP:		NOP							;
			RET							;
**********************************************************************************			
*I信道引导序列											区分基站,达到手机定位的目的,软流量,软切换			M序列太大了,先产生好再加,速度快,占空间
*P1(x)=x15+x13+x9+x8+x7+x5+1						15个一,14个0,14个0的下一位是周期的头								  边产生边加,省空间,速度慢
*v中记录上一个数据包结束PN1所在周期中的比特位置			K,偏制系数,K=0与K=1差64位,K=0是周期的头
*输入数据在wa中1536个字,输出在w中1536个字				1.2288M*2S/32768=75周期,
**********************************************************************************		

****************************************************************************************
pianzhi1    STM		#wa,AR3				;输入
		    STM		#w,AR5				;输出,间接,WA有1536个字
		    LD		#pn1,A				;首地址给A
		    ADD		*(v),A				;V起点,绝对寻址
		    STLM	A,AR4				;
		    LD		*(v),A				;
		    SUB		#512,A				;A-512,2048-1536=512
		    BC		ppp,AGEQ			;A不小于0,跳转到PPP
		    STM		#1535,BRC			;
		    RPTB	ppp1-1				;
		    LD		*AR3+,A				;
		    XOR		*AR4+,A				;
		    STL		A,*AR5+				;
ppp1:	    B		ppp2				;
ppp:        LD		#2047,A				;32768/16=2048
		    SUB		*(v),A				;
		    STLM	A,BRC				;循环次数为2048-V  BRC=2048-V-1
		    RPTB	ppp3-1				;
		    LD		*AR3+,A				;
		    XOR		*AR4+,A				;
		    STL		A,*AR5+				;
ppp3:	    LD		*(v),A				;
		    SUB		#513,A				;循环次数为V-512	BRC=V-512-1
		    STLM	A,BRC				;
 			RPTB	ppp2-1				;
		    STM		#pn1,AR4			;
		    LD		*AR3+,A				;
		    XOR		*AR4+,A				;
		    STL		A,*AR5+				;
ppp2:	    RET							;
**********************************************************************************			
*Q信道引导序列
*PQ(x)=x15+x12+x11+x10+x6+x5+x4+x3+1
*v中记录上一个数据包结束PN1所在周期中的比特位置
*输入数据在wa中1536个字,输出在wa中1536个字
**********************************************************************************		
pianzhi2	STM		#wa,AR3
		    STM		#wa,AR5
		    LD		#pn2,A
		    ADD		*(v),A
		    STLM	A,AR4
		    LD		*(v),A
		    SUB		#512,A
		    BC		qqq,AGEQ
		    STM		#1535,BRC
		    RPTB	qqq1-1
		    LD		*AR3+,A
		    XOR		*AR4+,A
		    STL		A,*AR5+
qqq1:	    LD		*(v),A
		    ADD		#1536,A
		    STL		A,*(v)
		    B		qqq2
qqq:        LD		#2047,A
		    SUB		*(v),A
		    STLM	A,BRC				;循环次数为2048-V  BRC=2048-V-1
		    RPTB	qqq3-1
		    LD		*AR3+,A
		    XOR		*AR4+,A
		    STL		A,*AR5+
qqq3:	    LD		*(v),A
		    SUB		#513,A				;循环次数为V-512	BRC=V-512-1
		    STLM	A,BRC
			RPTB	qqq2-1
		    STM		#pn2,AR4
		    LD		*AR3+,A
		    XOR		*AR4+,A
		    STL		A,*AR5+
qqq2:	    RET
*******************************************************************
*QPSK调制器
*I信道数据在W中1536*16比特,Q信道数据在WA中1536*16比特
*IQ分别为00,01,10,11四种状态输出四种预存的波形,每种波形8个样点
*cos+sin;cos-sin;sin-cos;-cos-sin四种波形
*对应位置为*iq,*iq+8,iq+16,iq+24
*******************************************************************
qpsk		STM		#w,AR2
			STM		#wa,AR3
			STM		#1535,BRC
			RPTB	kkk-1
			LD		#iq,A
			BIT		*AR2,15-0				;输出0位
			BC		kkk1,NTC
			ADD		#16,A
kkk1:		BIT		*AR3,15-0
			BC		kkk2,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk2:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-1				;输出1位
			BC		kkk3,NTC
			ADD		#16,A
kkk3:		BIT		*AR3,15-1
			BC		kkk4,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk4:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点			
			LD		#iq,A
			BIT		*AR2,15-2				;输出2位
			BC		kkk5,NTC
			ADD		#16,A
kkk5:		BIT		*AR3,15-2
			BC		kkk6,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk6:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-3				;输出3位
			BC		kkk7,NTC
			ADD		#16,A
kkk7:		BIT		*AR3,15-3
			BC		kkk8,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk8:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-4				;输出4位
			BC		kkk9,NTC
			ADD		#16,A
kkk9:		BIT		*AR3,15-4
			BC		kkk10,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk10:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-5				;输出5位
			BC		kkk11,NTC
			ADD		#16,A
kkk11:		BIT		*AR3,15-5
			BC		kkk12,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk12:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-6				;输出6位
			BC		kkk13,NTC
			ADD		#16,A
kkk13:		BIT		*AR3,15-6
			BC		kkk14,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk14:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-7				;输出7位
			BC		kkk15,NTC
			ADD		#16,A
kkk15:		BIT		*AR3,15-7
			BC		kkk16,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk16:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-8				;输出8位
			BC		kkk17,NTC
			ADD		#16,A
kkk17:		BIT		*AR3,15-8
			BC		kkk18,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk18:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-9				;输出9位
			BC		kkk19,NTC
			ADD		#16,A
kkk19:		BIT		*AR3,15-9
			BC		kkk20,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk20:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-10				;输出10位
			BC		kkk21,NTC
			ADD		#16,A
kkk21:		BIT		*AR3,15-10
			BC		kkk22,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk22:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-11				;输出11位
			BC		kkk23,NTC
			ADD		#16,A
kkk23:		BIT		*AR3,15-11
			BC		kkk24,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk24:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-12				;输出12位
			BC		kkk25,NTC
			ADD		#16,A
kkk25:		BIT		*AR3,15-12
			BC		kkk26,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk26:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-13				;输出13位
			BC		kkk27,NTC
			ADD		#16,A
kkk27:		BIT		*AR3,15-13
			BC		kkk28,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk28:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2,15-14				;输出14位
			BC		kkk29,NTC
			ADD		#16,A
kkk29:		BIT		*AR3,15-14
			BC		kkk30,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk30:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
			LD		#iq,A
			BIT		*AR2+,15-15				;输出15位处理下一个字
			BC		kkk31,NTC
			ADD		#16,A
kkk31:		BIT		*AR3+,15-15				;输出15位处理下一个字
			BC		kkk32,NTC
			ADD		#8,A					;A=*iq,*iq+8,iq+16,iq+24
kkk32:		STLM	A,AR4					;A=*iq,*iq+8,iq+16,iq+24
			RPT		#7
			PORTW	*AR4+,PA9				;输出调制波形8个样点
kkk:		RET
*********************************************************************
		    .end		
