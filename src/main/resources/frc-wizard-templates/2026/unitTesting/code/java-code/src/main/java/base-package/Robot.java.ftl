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

import edu.wpi.first.wpilibj.Joystick;
import edu.wpi.first.wpilibj.TimedRobot;
import ${data.basePackage}.Constants.IntakeConstants;
import ${data.basePackage}.subsystems.Intake;



/**
 * The methods in this class are called automatically corresponding to each mode, as described in
 * the TimedRobot documentation. If you change the name of this class or the package after creating
 * this project, you must also update the Main.java file in the project.
 */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    private final Intake intake = new Intake();
    private final Joystick joystick = new Joystick(Constants.JOYSTICK_INDEX);
    
    
    /** This method is called periodically during operator control. */
    @Override
    public void teleopPeriodic()
    {
        // Activate the intake while the trigger is held
        if (joystick.getTrigger())
        {
            intake.activate(IntakeConstants.INTAKE_SPEED);
        }
        else
        {
            intake.activate(0);
        }
        
        // Toggle deploying the intake when the top button is pressed
        if (joystick.getTop())
        {
            if (intake.isDeployed())
            {
                intake.retract();
            }
            else
            {
                intake.deploy();
            }
        }
    }
}
