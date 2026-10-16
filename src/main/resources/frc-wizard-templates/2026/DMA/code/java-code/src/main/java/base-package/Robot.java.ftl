<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
${data.copyright}

package ${data.basePackage};

import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj.AnalogInput;
import edu.wpi.first.wpilibj.DMA;
import edu.wpi.first.wpilibj.DMASample;
import edu.wpi.first.wpilibj.DigitalOutput;
import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;



/** This is a sample program showing how to use DMA to read a sensor. */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    private final DMA dma;
    private final DMASample dmaSample;
    
    // DMA needs a trigger, can use an output as trigger.
    // 8 Triggers exist per DMA object, can be triggered on any
    // DigitalSource.
    private final DigitalOutput dmaTrigger;
    
    // Analog input to read with DMA
    private final AnalogInput analogInput;
    
    // Encoder to read with DMA
    private final Encoder encoder;
    
    
    /** Called once at the beginning of the robot program. */
    public Robot()
    {
        dma = new DMA();
        dmaSample = new DMASample();
        dmaTrigger = new DigitalOutput(2);
        analogInput = new AnalogInput(0);
        encoder = new Encoder(0, 1);
        
        // Trigger on falling edge of dma trigger output
        dma.setExternalTrigger(dmaTrigger, false, true);
        
        // Add inputs we want to read via DMA
        dma.addAnalogInput(analogInput);
        dma.addEncoder(encoder);
        dma.addEncoderPeriod(encoder);
        
        // Make sure trigger is set to off.
        dmaTrigger.set(true);
        
        // Start DMA. No triggers or inputs can be added after this call
        // unless DMA is stopped.
        dma.start(1024);
    }
    
    
    @Override
    public void robotPeriodic()
    {
        // Manually Trigger DMA read
        dmaTrigger.set(false);
        
        // Update our sample. remaining is the number of samples remaining in the
        // buffer status is more specific error messages if readStatus is not OK.
        // Wait 1ms if buffer is empty
        DMASample.DMAReadStatus readStatus = dmaSample.update(dma, Units.millisecondsToSeconds(1));
        
        // Unset trigger
        dmaTrigger.set(true);
        
        if (readStatus == DMASample.DMAReadStatus.kOk)
        {
            // Status value in all these reads should be checked, a non 0 value means
            // value could not be read
            
            // If DMA is good, values exist
            double encoderDistance = dmaSample.getEncoderDistance(encoder);
            // Period is not scaled, and is a raw value
            int encoderPeriod = dmaSample.getEncoderPeriodRaw(encoder);
            double analogVoltage = dmaSample.getAnalogInputVoltage(analogInput);
            
            SmartDashboard.putNumber("Distance", encoderDistance);
            SmartDashboard.putNumber("Period", encoderPeriod);
            SmartDashboard.putNumber("Input", analogVoltage);
            SmartDashboard.putNumber("Timestamp", dmaSample.getTimeStamp());
        }
    }
}
