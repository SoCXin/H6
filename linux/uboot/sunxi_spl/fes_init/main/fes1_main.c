/*
**********************************************************************************************************************
*
*						           the Embedded Secure Bootloader System
*
*
*						       Copyright(C), 2006-2014, Allwinnertech Co., Ltd.
*                                           All Rights Reserved
*
* File    :
*
* By      :
*
* Version : V2.00
*
* Date	  :
*
* Descript:
**********************************************************************************************************************
*/
#include <common.h>
#include <private_boot0.h>
#include <asm/io.h>
#include <asm/arch/clock.h>
#include <asm/arch/timer.h>
#include <asm/arch/uart.h>
#include <asm/arch/dram.h>
#include <asm/arch/ccmu.h>
#include <asm/arch/base_pmu.h>

extern void set_pll( void );
extern void set_gpio_gate( void );

extern const boot0_file_head_t fes1_head;

typedef struct __fes_aide_info{
    __u32 dram_init_flag;       /* Dram初始化完成标志       */
    __u32 dram_update_flag;     /* Dram 参数是否被修改标志  */
    __u32 dram_paras[SUNXI_DRAM_PARA_MAX];
}fes_aide_info_t;


//note: this function for linker error
int raise (int signum)
{
	return 0;
}

/* Dummy function to avoid linker complaints */
void __aeabi_unwind_cpp_pr0(void)
{

};


/*
************************************************************************************
*                          note_dram_log
*
* Description:
*	    ???????
* Parameters:
*		void
* Return value:
*    	0: success
*      !0: fail
* History:
*       void
************************************************************************************
*/
static void  note_dram_log(int dram_init_flag)
{
    fes_aide_info_t *fes_aide = (fes_aide_info_t *)CONFIG_FES1_RET_ADDR;

    memset(fes_aide, 0, sizeof(fes_aide_info_t));
    fes_aide->dram_init_flag    = SYS_PARA_LOG;
    fes_aide->dram_update_flag  = dram_init_flag;

    memcpy(fes_aide->dram_paras, fes1_head.prvt_head.dram_para, SUNXI_DRAM_PARA_MAX * 4);
    memcpy((void *)DRAM_PARA_STORE_ADDR, fes1_head.prvt_head.dram_para, SUNXI_DRAM_PARA_MAX * 4);
}
/*
************************************************************************************************************
*
*                                             function
*
*    name          :
*
*    parmeters     :
*
*    return        :
*
*    note          :
*
*
************************************************************************************************************
*/
int main(void)
{
	__s32 dram_size=0;

	timer_init();
	//serial init
	sunxi_serial_init(fes1_head.prvt_head.uart_port, (void *)fes1_head.prvt_head.uart_ctrl, 2);

	pmu_init(fes1_head.prvt_head.power_mode);
#ifdef CONFIG_SUNXI_MULITCORE_BOOT
	set_pll_voltage(CONFIG_SUNXI_CORE_VOL);
#endif
	set_pll();

	//enable gpio gate
	set_gpio_gate();
	//dram init
	printf("beign to init dram\n");
#ifdef FPGA_PLATFORM
	dram_size = mctl_init((void *)fes1_head.prvt_head.dram_para);
#else
#if defined(CONFIG_SUNXI_CRASH)
	dram_size = DRAMC_get_dram_size();
	printf("dram size=%dM\n", dram_size);
	if (dram_size)
	{
		__dram_para_t *dram_para = (__dram_para_t *)fes1_head.prvt_head.dram_para;

		dram_para->dram_para2 &= 0xffff;
		dram_para->dram_para2 |= (dram_size << 16);

		note_dram_log(1);
		printf("init dram ok\n");
	} else {
		dram_size = init_DRAM(0, (void *)fes1_head.prvt_head.dram_para);
	}
#else
	dram_size = init_DRAM(0, (void *)fes1_head.prvt_head.dram_para);
#endif
#endif

	if (dram_size)
	{
		note_dram_log(1);
		printf("init dram ok\n");
	}
	else
	{
		note_dram_log(0);
		printf("init dram fail\n");
	}

	__msdelay(10);

	return dram_size;
}

