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

import edu.wpi.first.wpilibj.GenericHID.RumbleType;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.XboxController;



/** This is a demo program showing the use of GenericHID's rumble feature. */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    private final XboxController hid = new XboxController(0);
    
    
    @Override
    public void autonomousInit()
    {
        // Turn on rumble at the start of auto
        hid.setRumble(RumbleType.kLeftRumble, 1.0);
        hid.setRumble(RumbleType.kRightRumble, 1.0);
    }
    
    
    @Override
    public void disabledInit()
    {
        // Stop the rumble when entering disabled
        hid.setRumble(RumbleType.kLeftRumble, 0.0);
        hid.setRumble(RumbleType.kRightRumble, 0.0);
    }
}
