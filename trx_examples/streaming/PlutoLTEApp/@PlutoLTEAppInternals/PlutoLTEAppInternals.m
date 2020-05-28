classdef PlutoLTEAppInternals < LTETestModelWaveform
    properties (SetObservable = true, AbortSet = true)
        CyclicPrefix
        FrameOffset
        SamplingRate
        NCellID
        FreqOffset
        IQOffset
        
        PSD_y
        PSD_x
        
        DemodSyms = struct
        
        evm_pbch_RMS
        evm_pcfich_RMS
        evm_pdcch_RMS
        evm_phich_RMS
        evm_rs_RMS
        evm_pss_RMS
        evm_sss_RMS
        
        nFrame
        count
        evmSymbol = struct
        evmSC = struct
        evmRB = struct        
        FrameEVM = struct
        FinalEVM
    end
    
    properties 
        SubFrameIndex
        PlutoTx
        PlutoRx
    end
    
    properties (Access = private)
        StopTest = false  
        test_settings = ...
            struct(...
            'DeviceIP', 'ip:192.168.2.1',...
            'TxGain', -10,...
            'RxGainMode', 'slow_attack',...
            'RxBufferSize', 2^18,...
            'SamplingRate', 1e6)        
    end
    
    methods (Access = private)
        % static methods in separate files
        dataRx = PlutoRadio(obj, app, eNodeBOutput, countTx)
    end
    
    methods
        function obj = PlutoLTEAppInternals(app_obj)
            addlistener(app_obj,'Play',@obj.handlePlayEvnt);
            addlistener(app_obj,'Stop',@obj.handleStopEvnt);
        end
    end
    
    methods (Static)
        function PlutoConnectionFcn(app)
            connectedRadios = findPlutoRadio;
            if ~isempty(connectedRadios)                
                status = ['Found Pluto. Radio Id: ''' connectedRadios.RadioID ''', SerialNum: ''' connectedRadios.SerialNum '''.'];
                app.Label.Text = {status};
                app.PlutoNotFound = false;
            else                
                status = 'Pluto not found.';
                app.Label.Text = {status};
                return;
            end            
        end
    end
       
    methods (Access = private)
        function handlePlayEvnt(obj, app, ~)
           % check if ADALM-PLUTO is connected 
           PlutoLTEAppInternals.PlutoConnectionFcn(app);
           if app.PlutoNotFound
               return;
           end
           
           % extract settings from app
           BW = app.BWDropDown.Value;
           BW = BW(~isspace(BW));
           TMN = app.TMNDropDown.Value;
           
           % clear Listbox
           app.ListBox.Items = {''};
           drawnow;
           
           countTx = 1;
           while (true)
               if obj.stopTest(app)
                   return;
               end
                                
               %% generate test waveform
               [eNodeBOutput, etm] = PlutoLTEAppInternals.Tx(TMN, BW);
               app.PlutoLTEAppInternalsProp.CyclicPrefix = etm.CyclicPrefix;           
               app.PlutoLTEAppInternalsProp.NCellID = etm.NCellID;
               app.PlutoLTEAppInternalsProp.SamplingRate = etm.SamplingRate;

               % scale the signal and cast to int16
               ScaleFactor = 0.7;
               eNodeBOutput = eNodeBOutput.*(1/max(abs(eNodeBOutput))*ScaleFactor);
               eNodeBOutput = int16(eNodeBOutput*2^15);

               %% transmit waveform using ADALM-PLUTO over a loopback cable and
               % receive waveform
               dataRx = obj.PlutoRadio(app, eNodeBOutput, countTx);
               app.ListBox.Items = [app.ListBox.Items, ...
                   sprintf('Trial #%d: \n', countTx)]; 
               scroll(app.ListBox,'bottom');                 
               countTx = countTx+1;
               
               %% demodulate received waveform and compute metrics
               [dataRx, frameOffset] = ...
                   PlutoLTEAppInternals.CorrectFreqFrameOffset(dataRx, etm);
               app.PlutoLTEAppInternalsProp.FrameOffset = frameOffset/etm.SamplingRate;

               % compute freq offset and IQ offset
               cec.PilotAverage = 'TestEVM';            
               [FreqOffset_temp, IQOffset_temp, refGrid, rxGridLow, rxGridHigh, ...
                   rxWaveform, nSubframes, nFrames, alg, frameEVM] = ...
                   PlutoLTEAppInternals.Sync(etm, cec, dataRx);
               app.PlutoLTEAppInternalsProp.FreqOffset = FreqOffset_temp;
               app.PlutoLTEAppInternalsProp.IQOffset = IQOffset_temp;

               % stop test if needed
               if obj.stopTest(app)
                   return;
               end
               
               % estimate channel
               [psd_frame, f, HestLow, HestHigh, allPRBSet] = ...
                   PlutoLTEAppInternals.EstimateChannel(etm, ...
                   rxWaveform, nSubframes, cec, rxGridLow, rxGridHigh);
               app.PlutoLTEAppInternalsProp.PSD_x = f;
               app.PlutoLTEAppInternalsProp.PSD_y = psd_frame;

               % compute EVM measurements           
               gridDims = lteResourceGridSize(etm);
               L = gridDims(2);    
               evmSymbolPlot = app.evmSymsAxes;
               evmSymbolPlot.XLim = [0 (L*nSubframes)-1];

               app.PlutoLTEAppInternalsProp.count = 1;           
               for i=0:nSubframes-1
                   % stop test if needed
                   if obj.stopTest(app)
                       return;
                   end

                   app.PlutoLTEAppInternalsProp.SubFrameIndex = i;

                   [EVMStruct, evm, allocatedSymbols, rxSymbols, refSymbols, ...
                       pdsch_ind, etm] = ...
                       PlutoLTEAppInternals.EVMSubframe(i, nSubframes, etm, allPRBSet, ...
                       refGrid, rxGridLow, rxGridHigh, HestLow, HestHigh);
                   app.PlutoLTEAppInternalsProp.DemodSyms = ...
                       struct('Rec', rxSymbols, 'Ref', refSymbols);

                   if isfield(EVMStruct, 'PBCH')
                       app.PlutoLTEAppInternalsProp.evm_pbch_RMS = 100*EVMStruct.PBCH;
                   end               
                   if isfield(EVMStruct, 'PCFICH')
                       app.PlutoLTEAppInternalsProp.evm_pcfich_RMS = 100*EVMStruct.PCFICH;
                   end
                   if isfield(EVMStruct, 'PHICH')
                       app.PlutoLTEAppInternalsProp.evm_phich_RMS = 100*EVMStruct.PHICH;
                   end
                   if isfield(EVMStruct, 'PDCCH')
                       app.PlutoLTEAppInternalsProp.evm_pdcch_RMS = EVMStruct.PDCCH;
                   end
                   if isfield(EVMStruct, 'RS')
                       app.PlutoLTEAppInternalsProp.evm_rs_RMS = 100*EVMStruct.RS;
                   end
                   if isfield(EVMStruct, 'PSS')
                       app.PlutoLTEAppInternalsProp.evm_pss_RMS = 100*EVMStruct.PSS;
                   end
                   if isfield(EVMStruct, 'SSS')
                       app.PlutoLTEAppInternalsProp.evm_sss_RMS = 100*EVMStruct.SSS; 
                   end

                   [SymbEVM, ScEVM, RbEVM, frameLowEVM, frameHighEVM, frameEVM, etm,...
                       app.PlutoLTEAppInternalsProp.count, app.PlutoLTEAppInternalsProp.nFrame] = ...
                       PlutoLTEAppInternals.DemodSymbs(i, pdsch_ind, nFrames, ...
                       app.PlutoLTEAppInternalsProp.count, alg, etm, evm, ...
                       allocatedSymbols, frameEVM, nSubframes);
                   app.PlutoLTEAppInternalsProp.evmSymbol = ...
                       struct('RMS', SymbEVM.evmSymbolRMS, 'Peak', SymbEVM.evmSymbolPeak);
                   app.PlutoLTEAppInternalsProp.evmSC = ...
                       struct('RMS', ScEVM.evmSubcarrierRMS, 'Peak', ScEVM.evmSubcarrierPeak);                
                   app.PlutoLTEAppInternalsProp.evmRB = ...
                       struct('RMS', RbEVM.evmRBRMS, 'Peak', RbEVM.evmRBPeak);  

                   if (mod(i, 10)==9 || (nFrames==0 && i==nSubframes-1))
                       if (nFrames~=0)
                           app.PlutoLTEAppInternalsProp.FrameEVM = ...
                               struct('Low', frameLowEVM, ...
                               'High', frameHighEVM, 'Overall', frameEVM);                
                       end
                   end           
               end
               % Final Mean EVM across all frames
               app.PlutoLTEAppInternalsProp.FinalEVM = lteEVM(cat(1, frameEVM(:).EV));
           end
        end
        
        function handleStopEvnt(obj, app, ~)
            obj.StopTest = true;
            obj.PlutoTx.release();
            obj.PlutoRx.release();
            app.PlayButton.Enable = 'on'; 
            drawnow limitrate;
        end          
        
        function killtest = stopTest(obj, app)
            killtest = obj.StopTest;
            if (killtest)
                app.PlayButton.Enable = 'on';  
                drawnow limitrate; 
                obj.StopTest = false;                
            end
        end
   end
end