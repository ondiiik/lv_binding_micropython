# CMake file included into micropython ESP32 port
cmake_minimum_required(VERSION 3.5)


# Function located at position where ESP-IDF builder is already set up
function(lvgl_build_sources)
    # Checks dependencies
    if(CONFIG_MICROPYTHON_ESPIDF_ENABLE AND NOT CONFIG_MICROPYTHON_LVGL_ENABLE)
        message(FATAL_ERROR "[LVGL] ESP-IDF can not be built without LVGL. Please set cmake variable CONFIG_MICROPYTHON_LVGL_ENABLE to ON")
    endif()
    
    
    # Get settings of ESP-IDF builder
    list(APPEND MICROPY_CPP_INC ${MICROPY_CPP_INC_EXTRA})
    list(APPEND MICROPY_CPP_DEF ${MICROPY_CPP_DEF_EXTRA})
    
    set(_prefix "-I")
    foreach(_arg ${MICROPY_CPP_INC_EXTRA})
        if(EXISTS ${_arg})
            list(APPEND ESPIDF_INCLUDES ${_prefix}${_arg})
        endif()
    endforeach()
    
    list(REMOVE_DUPLICATES ESPIDF_INCLUDES)
    
    set(_prefix "-D")
    foreach(_arg ${MICROPY_CPP_DEF_EXTRA})
        list(APPEND ESPIDF_DEFINES ${_prefix}${_arg})
    endforeach()
    
    list(REMOVE_DUPLICATES ESPIDF_DEFINES)
    
    
    # Get configuration of LVGL
    set(_prefix "-D")
    foreach(_arg ${MICROPY_DEFINES_LVGL})
        list(APPEND LVGL_DEFINES ${_prefix}${_arg})
    endforeach()
    
    list(REMOVE_DUPLICATES LVGL_DEFINES)
    
    
    # Build python module sources for LVGL module
    if(CONFIG_MICROPYTHON_LVGL_ENABLE)
        message(STATUS "[LVGL] Preprocessing LVGL module ...")
        file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/lvgl)
        execute_process(COMMAND xtensa-esp32-elf-gcc -E ${LVGL_DEFINES} -I../../lib/lv_bindings/pycparser/utils/fake_libc_include -I../../lib/lv_bindings -I../../lib/lv_bindings/driver/png/lodepng -I../../lib/berkeley-db-1.xx/PORT/include -I. -I../.. -I${CMAKE_BINARY_DIR} ../../lib/lv_bindings/lvgl/lvgl.h
                        OUTPUT_FILE       ${CMAKE_BINARY_DIR}/lvgl/lvgl.pp.c
                        WORKING_DIRECTORY ${PROJECT_DIR})
        
        message(STATUS "[LVGL] Building LVGL module ...")
        execute_process(COMMAND python3 ../../lib/lv_bindings/gen/gen_mpy.py -M lvgl -MP lv -MD ${CMAKE_BINARY_DIR}/lvgl/lv_mpy.json -E ${CMAKE_BINARY_DIR}/lvgl/lvgl.pp.c ../../lib/lv_bindings/lvgl/lvgl.h
                        OUTPUT_FILE       ${CMAKE_BINARY_DIR}/lvgl/lv_mpy.c
                        WORKING_DIRECTORY ${PROJECT_DIR})
    endif()
    
    
    # Build python module sources for LODEPNG module
    if(CONFIG_MICROPYTHON_LODEPNG_ENABLE)
        message(STATUS "[LVGL] Preprocessing LODEPNG module ...")
        file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/lodepng)
        execute_process(COMMAND xtensa-esp32-elf-gcc -E -DLODEPNG_NO_COMPILE_ENCODER -DLODEPNG_NO_COMPILE_DISK -DLODEPNG_NO_COMPILE_ALLOCATORS -I../../lib/lv_bindings -I../../lib/lv_bindings/driver/png/lodepng -I../../lib/berkeley-db-1.xx/PORT/include -I. -I../.. -I${CMAKE_BINARY_DIR} -I../../lib/lv_bindings/pycparser/utils/fake_libc_include ../../lib/lv_bindings/driver/png/lodepng/lodepng.h
                        OUTPUT_FILE       ${CMAKE_BINARY_DIR}/lodepng/lodepng.pp.c
                        WORKING_DIRECTORY ${PROJECT_DIR})
        
        message(STATUS "[LVGL] Building LODEPNG module ...")
        execute_process(COMMAND python3 ../../lib/lv_bindings/gen/gen_mpy.py -M lodepng -E ${CMAKE_BINARY_DIR}/lodepng/lodepng.pp.c ../../lib/lv_bindings/driver/png/lodepng/lodepng.h
                        OUTPUT_FILE       ${CMAKE_BINARY_DIR}/lodepng/mp_lodepng.c
                        WORKING_DIRECTORY ${PROJECT_DIR})
        file(CREATE_LINK ${MICROPY_LVGL_DIR}/driver/png/lodepng/lodepng.cpp ${CMAKE_BINARY_DIR}/lodepng/lodepng.c)
    endif()
    
    
    # Build python module sources for ESPIDF module
    if(CONFIG_MICROPYTHON_ESPIDF_ENABLE)
        message(STATUS "[LVGL] Preprocessing ESPIDF module ...")
        file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/espidfmod)
        execute_process(COMMAND xtensa-esp32-elf-gcc -E  -DPYCPARSER -I../../lib/lv_bindings/pycparser/utils/fake_libc_include -I../../lib/lv_bindings -I../../lib/lv_bindings/driver/png/lodepng -I../../lib/berkeley-db-1.xx/PORT/include -I. -I../.. -I${CMAKE_BINARY_DIR} ${ESPIDF_INCLUDES} ${ESPIDF_DEFINES} ../../lib/lv_bindings/driver/esp32/espidf.h
                        OUTPUT_FILE       ${CMAKE_BINARY_DIR}/espidfmod/mp_espidf.ppi.c
                        WORKING_DIRECTORY ${PROJECT_DIR})
        
        message(STATUS "[LVGL] Building ESPIDF module ...")
        execute_process(COMMAND python3 ../../lib/lv_bindings/gen/gen_mpy.py -M espidf -R ${CMAKE_BINARY_DIR}/espidfmod/mp_espidf.pp.c -E ${CMAKE_BINARY_DIR}/espidfmod/mp_espidf.ppi.c ../../lib/lv_bindings/driver/esp32/espidf.h
                        OUTPUT_FILE       ${CMAKE_BINARY_DIR}/espidfmod/mp_espidf.c
                        WORKING_DIRECTORY ${PROJECT_DIR})
    endif()
endfunction()




# Append sources for building modules to other micropython stuff
function(lvgl_add_sources)
    set(MICROPY_DEFINES_LVGL  MICROPY_PY_RTCH=0
                              )
    
#    set(MICROPY_SOURCE_LVGL ${MICROPY_LVGL_DIR}/driver/esp32/modrtch.c)
    
    
    
    if(CONFIG_MICROPYTHON_LVGL_ENABLE)
        list(APPEND MICROPY_DEFINES_LVGL MICROPY_PY_LVGL=1)
        
        if(DEFINED CONFIG_MICROPYTHON_LVGL_COLOR_DEPTH)
            list(APPEND MICROPY_DEFINES_LVGL LV_COLOR_DEPTH=${CONFIG_MICROPYTHON_LVGL_COLOR_DEPTH})
        endif()
        
        if(DEFINED CONFIG_MICROPYTHON_LVGL_COLOR_SWAP)
            list(APPEND MICROPY_DEFINES_LVGL LV_COLOR_16_SWAP=${CONFIG_MICROPYTHON_LVGL_COLOR_SWAP})
        endif()
        
        if(DEFINED CONFIG_MICROPYTHON_LVGL_HOR_RES)
            list(APPEND MICROPY_DEFINES_LVGL LV_HOR_RES_MAX=${CONFIG_MICROPYTHON_LVGL_HOR_RES})
        endif()
        
        if(DEFINED CONFIG_MICROPYTHON_LVGL_VER_RES)
            list(APPEND MICROPY_DEFINES_LVGL LV_VER_RES_MAX=${CONFIG_MICROPYTHON_LVGL_VER_RES})
        endif()
        
        
        list(APPEND MICROPY_SOURCE_LVGL  ${CMAKE_BINARY_DIR}/lvgl/lv_mpy.c
                                         ${MICROPY_LVGL_DIR}/driver/esp32/modlvesp32.c
                                         ${MICROPY_LVGL_DIR}/driver/generic/modlvindev.c
                                         ${MICROPY_LVGL_DIR}/driver/esp32/sh2lib.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_core/lv_disp.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_core/lv_group.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_core/lv_indev.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_core/lv_obj.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_core/lv_refr.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_core/lv_style.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_draw/lv_draw_arc.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_draw/lv_draw_blend.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_draw/lv_draw_img.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_draw/lv_draw_label.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_draw/lv_draw_line.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_draw/lv_draw_mask.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_draw/lv_draw_rect.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_draw/lv_draw_triangle.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_draw/lv_img_buf.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_draw/lv_img_cache.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_draw/lv_img_decoder.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_dejavu_16_persian_hebrew.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_fmt_txt.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_loader.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_10.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_12.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_12_subpx.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_14.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_16.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_18.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_20.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_22.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_24.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_26.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_28.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_28_compressed.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_30.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_32.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_34.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_36.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_38.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_40.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_42.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_44.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_46.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_48.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_montserrat_8.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_simsun_16_cjk.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_unscii_16.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_font/lv_font_unscii_8.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_gpu/lv_gpu_nxp_pxp.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_gpu/lv_gpu_nxp_pxp_osa.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_gpu/lv_gpu_nxp_vglite.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_gpu/lv_gpu_stm32_dma2d.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_hal/lv_hal_disp.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_hal/lv_hal_indev.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_hal/lv_hal_tick.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_anim.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_area.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_async.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_bidi.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_color.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_debug.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_fs.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_gc.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_ll.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_log.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_math.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_mem.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_printf.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_task.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_templ.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_txt.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_txt_ap.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc/lv_utils.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_themes/lv_theme.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_themes/lv_theme_empty.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_themes/lv_theme_material.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_themes/lv_theme_mono.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_themes/lv_theme_template.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_arc.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_bar.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_btn.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_btnmatrix.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_calendar.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_canvas.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_chart.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_checkbox.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_cont.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_cpicker.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_dropdown.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_gauge.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_img.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_imgbtn.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_keyboard.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_label.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_led.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_line.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_linemeter.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_list.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_msgbox.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_objmask.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_objx_templ.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_page.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_roller.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_slider.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_spinbox.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_spinner.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_switch.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_table.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_tabview.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_textarea.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_tileview.c
                                         ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets/lv_win.c)
    else()
        list(APPEND MICROPY_DEFINES_LVGL MICROPY_PY_LVGL=0)
    endif()
    
    
    
    if(CONFIG_MICROPYTHON_ESPIDF_ENABLE)
        list(APPEND MICROPY_DEFINES_LVGL MICROPY_PY_ESPIDF=1)
        list(APPEND MICROPY_SOURCE_LVGL  ${CMAKE_BINARY_DIR}/espidfmod/mp_espidf.c
                                         ${MICROPY_LVGL_DIR}/driver/esp32/espidf.c)
    else()
        list(APPEND MICROPY_DEFINES_LVGL MICROPY_PY_ESPIDF=0)
    endif()
    
    
    
    if(CONFIG_MICROPYTHON_LODEPNG_ENABLE)
        list(APPEND MICROPY_DEFINES_LVGL MICROPY_PY_LODEPNG=1
                                         LODEPNG_NO_COMPILE_ENCODER
                                         LODEPNG_NO_COMPILE_DISK
                                         LODEPNG_NO_COMPILE_ALLOCATORS)
        
        list(APPEND MICROPY_SOURCE_LVGL  ${CMAKE_BINARY_DIR}/lodepng/mp_lodepng.c
                                         ${CMAKE_BINARY_DIR}/lodepng/lodepng.c
                                         ${MICROPY_LVGL_DIR}/driver/png/mp_lodepng.c)
    else()
        list(APPEND MICROPY_DEFINES_LVGL MICROPY_PY_LODEPNG=0)
    endif()
    
    
    
    set(MICROPY_INCLUDES_LVGL ${MICROPY_DIR}
                              ${MICROPY_LVGL_DIR}
                              ${MICROPY_LVGL_DIR}/driver/esp32
                              ${MICROPY_LVGL_DIR}/driver/generic
                              ${MICROPY_LVGL_DIR}/driver/png
                              ${MICROPY_LVGL_DIR}/driver/png/lodepng
                              ${MICROPY_LVGL_DIR}/lvgl/src/lv_core
                              ${MICROPY_LVGL_DIR}/lvgl/src/lv_draw
                              ${MICROPY_LVGL_DIR}/lvgl/src/lv_font
                              ${MICROPY_LVGL_DIR}/lvgl/src/lv_gpu
                              ${MICROPY_LVGL_DIR}/lvgl/src/lv_hal
                              ${MICROPY_LVGL_DIR}/lvgl/src/lv_misc
                              ${MICROPY_LVGL_DIR}/lvgl/src/lv_themes
                              ${MICROPY_LVGL_DIR}/lvgl/src/lv_widgets
                              PARENT_SCOPE)
    
    
    set(MICROPY_DEFINES_LVGL ${MICROPY_DEFINES_LVGL} PARENT_SCOPE)
    set(MICROPY_SOURCE_LVGL  ${MICROPY_SOURCE_LVGL}  PARENT_SCOPE)
endfunction()
