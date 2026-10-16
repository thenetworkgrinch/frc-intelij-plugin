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

package ${data.basePackage}.subsystems;

import edu.wpi.first.wpilibj.xrp.XRPServo;
import edu.wpi.first.wpilibj2.command.SubsystemBase;



public class Arm extends SubsystemBase
{
    private final XRPServo armServo;
    
    
    /** Creates a new Arm. */
    public Arm()
    {
        // Device number 4 maps to the physical Servo 1 port on the XRP
        armServo = new XRPServo(4);
    }
    
    
    @Override
    public void periodic()
    {
        // This method will be called once per scheduler run
    }
    
    
    /**
     * Set the current angle of the arm (0 - 180 degrees).
     *
     * @param angleDeg Desired arm angle in degrees
     */
    public void setAngle(double angleDeg)
    {
        armServo.setAngle(angleDeg);
    }
}
