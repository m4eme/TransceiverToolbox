set ad_hdl_dir    	[pwd]

#### Move files
file rename -force $ad_hdl_dir/hdl/vendor/AnalogDevices/vivado/projects $ad_hdl_dir/projects
file rename -force $ad_hdl_dir/hdl/vendor/AnalogDevices/vivado/library $ad_hdl_dir/library
file copy -force $ad_hdl_dir/trx_examples/targeting/tuneAGC-ad9361/ccfmc_lvds_agc $ad_hdl_dir/projects/adrv9361z7035/ccfmc_lvds_agc