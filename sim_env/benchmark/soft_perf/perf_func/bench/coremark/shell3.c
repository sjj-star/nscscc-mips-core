#include <machine.h>
#include <time.h>

void shell3(void)
{
    unsigned long start_count = 0;
    unsigned long stop_count = 0;
    unsigned long total_count = 0;

    int err,i;

    err = 0;
    printf("coremark test begin.\n");
    start_count = get_count();
    if(SIMU_FLAG){
	    err = core_mark(0,0,0x66,COREMARK_LOOP,7,1,2000);
    }else{
        for(i=0;i<LOOPTIMES;i++)
	        err += core_mark(0,0,0x66,COREMARK_LOOP,7,1,2000);
    }
    stop_count = get_count();
    total_count = stop_count - start_count;
	if(err == 0){
        printf("coremark PASS!\n");
		*((int *)LED_RG1_ADDR) = 1;  
		*((int *)LED_RG0_ADDR) = 1;  
		*((int *)LED_ADDR)     = 0xffff;  
	}else{
        printf("coremark ERROR!!!\n");
		*((int *)LED_RG1_ADDR) = 1;  
		*((int *)LED_RG0_ADDR) = 2;  
		*((int *)LED_ADDR)     = 0;

	}

    *((int *)NUM_ADDR) = total_count;  
	printf("coremark: Total Count = 0x%x\n", total_count);

    return;
}
