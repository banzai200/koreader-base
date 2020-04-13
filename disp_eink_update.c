__s32 Disp_eink_update(__u32 sel, __u32 fb_id, __u32 mode, __u32 coordinate[])
{
	int ret = 0;
	__u8 *in_buffer = NULL;
	__u8 *out_buffer = NULL;
	__u32 xres, yres, bpp;
	__u32 x_start 	= coordinate[0];
	__u32 x_end 	= coordinate[1];
	__u32 y_start 	= coordinate[2];
	__u32 y_end 	= coordinate[3];

	cpufreq_driver_target(cpufreq_cpu_get(0), 1008000, 0);

	disp_eink.temperature = ADC_Get_temperature();

	/* disable the internal update task */
	disp_eink.internal_update = 0;

	if (mode == EINK_INIT_MODE)
		goto exit;

	Drv_disp_get_fb_size(0, &xres, &yres);
	bpp = Drv_disp_get_fb_bpp(0);

	in_buffer = eink_get32BppBuffer();
	ret = eink_get8BppBuffer(mode, coordinate, &out_buffer);
	if (ret < 0)
		goto exit;

	if (bpp != 8)
		eink_32To8Bpp(in_buffer, out_buffer);
	else
		memcpy(out_buffer, in_buffer, xres * yres);

	if (mode & EINK_DITHERING_MODE) {
		if (mode & EINK_GC16_MODE)
			eink_set_8bit_dithering((__u8 *)out_buffer);
		else
			eink_set_dithering((__u8 *)out_buffer, x_start, x_end, y_start, y_end);
	} else if (mode & (EINK_A2_MODE | EINK_A2_IN_MODE)) {
		eink_set1b_color((__u8 *)out_buffer, x_start, x_end, y_start, y_end);
	}

#ifdef AWF_WAVEFORM_SUPPORTED
	if (disp_eink.p_wf_buffer == NULL) {
		set_vcom();
		eink_load_awf_waveform(EINK_AWF_WAV_PATH);
	}
#else
	eink_loadWaveFormData();
#endif

exit:
	up(disp_eink.wav_compose_sem);
	return ret;
} 
