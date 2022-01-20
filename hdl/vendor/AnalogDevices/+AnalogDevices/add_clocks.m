function add_clocks(hRD,project,design)

switch lower(project)    
    case 'adrv9002'
        hRD.addClockInterface( ...
            'ClockConnection',   'sys_ps8/pl_clk0', ...
            'ResetConnection',   'sys_rstgen/peripheral_aresetn');
    case 'adrv9009'
        switch(upper(design))
            case 'RX'
                hRD.addClockInterface( ...
                    'ClockConnection',   'axi_adrv9009_rx_clkgen/clk_0', ...
                    'ResetConnection',   'adrv9009_rx_device_clk_rstgen/peripheral_aresetn');
            case 'TX'
                hRD.addClockInterface( ...
                    'ClockConnection',   'axi_adrv9009_tx_clkgen/clk_0', ...
                    'ResetConnection',   'adrv9009_tx_device_clk_rstgen/peripheral_aresetn');
            case 'RX & TX'
                hRD.addClockInterface( ...
                    'ClockConnection',   'axi_adrv9009_rx_clkgen/clk_0', ...
                    'ResetConnection',   'adrv9009_rx_device_clk_rstgen/peripheral_aresetn');
        %     case 'OBS'
        %         hRD.addClockInterface( ...
        %             'ClockConnection',   'axi_adrv9009_rx_os_clkgen/clk_0', ...
        %             'ResetConnection',   'sys_rstgen/peripheral_aresetn');
            otherwise
                error('Unknown reference design');
        end
    case {'pluto'}
        hRD.addClockInterface( ...
            'ClockConnection',   'axi_ad9361/l_clk', ...
            'ResetConnection',   'sys_rstgen/peripheral_aresetn');
    case {'adrv9361z7035','adrv9364z7020','fmcomms2','fmcomms5'}
        hRD.addClockInterface( ...
            'ClockConnection',   'util_ad9361_divclk/clk_out', ...
            'ResetConnection',   'util_ad9361_divclk_reset/peripheral_aresetn');
    case 'adrv9371x'
        switch(upper(design))
            case 'RX'
                hRD.addClockInterface( ...
                    'ClockConnection',   'axi_ad9371_rx_clkgen/clk_0', ...
                    'ResetConnection',   'sys_rstgen/peripheral_aresetn');
            case 'TX'
                hRD.addClockInterface( ...
                    'ClockConnection',   'axi_ad9371_tx_clkgen/clk_0', ...
                    'ResetConnection',   'sys_rstgen/peripheral_aresetn');
            case 'RX & TX'
                hRD.addClockInterface( ...
                    'ClockConnection',   'axi_ad9371_rx_clkgen/clk_0', ...
                    'ResetConnection',   'sys_rstgen/peripheral_aresetn');
        %     case 'OBS'
        %         hRD.addClockInterface( ...
        %             'ClockConnection',   'axi_adrv9371_rx_os_clkgen/clk_0', ...
        %             'ResetConnection',   'sys_rstgen/peripheral_aresetn');
            otherwise
                error('Unknown reference design');
        end    
    end
end
