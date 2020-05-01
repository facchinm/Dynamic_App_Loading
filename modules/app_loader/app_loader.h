/**
 ******************************************************************************
 * @file    app_loader.h
 * @brief   Contains function for loading the app and setting up the freertos
 *          task
 ******************************************************************************
 * @attention
 *
 * LICENSE
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2020 Rohit Gujarathi rgujju.github.io
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
*/

#pragma once
#include "utilities.h"

/**
 *  @brief  TINF Format struct
 *          @verbatim
 *          Tiny Bin Format (TINF)
 *          +----------------------+----------------------------+-------------------------------------------------------------+
 *          | Field name           | Field size bits (bytes)    | Meaning                                                     |
 *          +----------------------+----------------------------+-------------------------------------------------------------+
 *          | magic                | 32  (4)                    | Always 'TINF' to identify App                               |
 *          | app_name             | 128 (16)                   | Name of App (Actual length allowed is 27)                   |
 *          | major_version        | 8   (1)                    | Major version of App                                        |
 *          | minor_version        | 8   (1)                    | Minor version of App                                        |
 *          | text_size            | 16  (2)                    | Size of text section in words (loaded onto flash)           |
 *          | data_size            | 16  (2)                    | Size of data section in words (loaded onto RAM)             |
 *          | bss_size             | 16  (2)                    | Size of the bss section in words (loaded onto RAM)          |
 *          | num_got_entries      | 32  (4)                    | Number of GOT entries                                       |
 *          | .text section        |                            | The .text section from the elf                              |
 *          | .data section        |                            | The .data section from the elf                              |
 *          | .got section         |                            | The .got section from the elf                               |
 *          +----------------------+----------------------------+-------------------------------------------------------------+
 *          @endverbatim
 */
typedef struct {
    /** Should be 'TINF'. This is checked while loading the app and APP_INVALID
     *  is returned if check fails.*/
    uint8_t magic[4];
    /** This is the name of app (max 15 chars and one \0 at the end).
     *  Will be passed to Task create function */
    uint8_t app_name[16];
    /** Major version of app. (max 255) */
    uint8_t major_version;
    /** Minor version of app. (max 255) */
    uint8_t minor_version;
    /** Size of the text section ie code section in words. max (65K words) */
    uint16_t text_size;
    /** Size of the data section in words. max (65K words) */
    uint16_t data_size;
    /** Size of the bss section in words. max (65K words) */
    uint16_t bss_size;
    /** Number of GOT table entries */
    uint32_t got_entries;
    /** The binary data is appended here */
    uint32_t bin[];

}__attribute__((packed)) tinf_t;


/** Magic and DUMMY_SYS_ADDR check failed */
#define APP_INVALID -1
/** Unable to allocate memory */
#define APP_OOM -2

/**
* @brief    Load the app from flash to RAM and setup the FreeRTOS task
*
* @param    tinf_img pointer to the memory location where App starts
*
* @retval   APP_INVALID  if magic and DUMMY_SYS_ADDR check fails
* @retval   APP_OOM      if malloc fails
*/
int8_t LoadApp(const uint8_t* tinf_img);
