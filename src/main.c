
#include "utilities.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

#include "stm32f4xx_hal.h"

#include "syscall.h"

void SystemClock_Config(void);

static GPIO_InitTypeDef  GPIO_InitStruct;

#define LED1_PIN GPIO_PIN_13
#define LED2_PIN GPIO_PIN_14
#define LED1_PORT GPIOG

static void LedBlinky_Task(void *pvParameters){
	while (1)
	{
		HAL_GPIO_TogglePin(LED1_PORT, LED1_PIN);
		vTaskDelay(1000/portTICK_PERIOD_MS);
	}
}

int main ( void )
{
	#if ENABLE_SEMIHOSTING
		initialise_monitor_handles();

		setbuf(stdout, NULL);
		//~ setvbuf(stdout, NULL, _IONBF, 0);
		INFO("Main program start");
	#endif


	HAL_Init();
	SystemClock_Config();

	__HAL_RCC_GPIOG_CLK_ENABLE();
	
	GPIO_InitStruct.Pin   = LED1_PIN | LED2_PIN;
	GPIO_InitStruct.Mode  = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull  = GPIO_PULLUP;
	GPIO_InitStruct.Speed = GPIO_SPEED_HIGH;

	HAL_GPIO_Init(LED1_PORT, &GPIO_InitStruct);
    
    void* app = 0x08010000;

//	xTaskCreate( LedBlinky_Task,						/* The function that implements the task. */
//				"LedBlinky", 							/* The text name assigned to the task - for debug only as it is not used by the kernel. */
//				configMINIMAL_STACK_SIZE, 				/* The size of the stack to allocate to the task. */
//				NULL, 									/* The parameter passed to the task - just to check the functionality. */
//				3, 										/* The priority assigned to the task. */
//				NULL );									/* The task handle is not required, so NULL is passed. */

    uint8_t led_ret = set_led(LED2, GPIO_PIN_SET);
	printf("Return value of set_led = %d\n",led_ret);
    vTaskStartScheduler();

	while (1)
	{
		
	}
	
	return 0;
}

void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage 
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE3);
  /** Initializes the CPU, AHB and APB busses clocks 
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLM = 8;
  RCC_OscInitStruct.PLL.PLLN = 128;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
  /** Initializes the CPU, AHB and APB busses clocks 
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV4;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0) != HAL_OK)
  {
    Error_Handler();
  }
}
