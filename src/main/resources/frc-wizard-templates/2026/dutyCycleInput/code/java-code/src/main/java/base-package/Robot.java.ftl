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

import edu.wpi.first.wpilibj.DigitalInput;
import edu.wpi.first.wpilibj.DutyCycle;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;



public class ${data.robotClassSimpleName} extends TimedRobot
{
    private final DutyCycle dutyCycle;
    
    
    public Robot()
    {
        dutyCycle = new DutyCycle(new DigitalInput(0));
    }
    
    
    @Override
    public void robotPeriodic()
    {
        // Duty Cycle Frequency in Hz
        int frequency = dutyCycle.getFrequency();
        
        // Output of duty cycle, ranging from 0 to 1
        // 1 is fully on, 0 is fully off
        double output = dutyCycle.getOutput();
        
        SmartDashboard.putNumber("Frequency", frequency);
        SmartDashboard.putNumber("Duty Cycle", output);
    }
}
