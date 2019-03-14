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
#ifndef  __SBORM_LIBS_H__
#define  __SBORM_LIBS_H__


extern void mmu_setup(void);
void mmu_resetup(u32 dram_mbytes, u32 obligate_dram_mbytes);
extern void mmu_turn_off(void);

extern int create_heap(unsigned int pHeapHead, unsigned int nHeapSize);

extern unsigned int go_exec (unsigned int run_addr, unsigned int para_addr, int out_secure, unsigned int dram_size);

void boot0_jump(unsigned int addr);

extern int set_debugmode_flag(void);

extern int sunxi_deassert_arisc(void);

#endif

